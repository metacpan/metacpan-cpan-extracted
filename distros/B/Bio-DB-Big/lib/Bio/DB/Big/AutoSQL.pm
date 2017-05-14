=head1 LICENSE

Copyright [2015-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::DB::Big::AutoSQL;

=pod

=head1 NAME

Bio::DB::Big::AutoSQL

=head1 SYNOPSIS

  my $raw_autosql = $bb->get_autosql();
  my $as = Bio::DB::Big::AutoSQL->new($raw_autosql);
  foreach my $field (@{$as->fields()}) {
    printf("%d: %s (%s)\n", $field->position(), $field->name(), $field->type());
  }

=head1 DESCRIPTION

Provides access to an AutoSQL definition by parsing a raw AutoSQL file into this object (representing the overall definition) and a series of L<Bio::DB::Big::AutoSQLField> objects. Fields can be looped over in the order they appear or can be retrieved by name.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use Scalar::Util qw/reftype/;

use Bio::DB::Big::AutoSQLField;

#### START OF REGEXS

#### A set of regular expressions used to parse AutoSQL files. See 
#### https://github.com/ucscGenomeBrowser/kent/blob/master/src/hg/autoSql/autoSql.doc
#### for more information on the specification.

# Parse a name e.g. name
my $NAME_RX = qr/[a-z0-9_]+/ixms;
# Extract string from a quoted string e.g. "A description."
my $QUOTEDSTR_RX = qr/"(.+?)"/xms;
# Capture field size e.g. int[2]
my $FIELDSIZE_RX = qr/\[(\w+)]/xms;
# Capture field values e.g. enum(one,two, three)
my $FIELDVALUES_RX = qr/\(([a-z, ]+)\)/xms;

# Capture all types of fields
my $FIELDSTYPE_RX = qr/(int|uint|short|ushort|byte|ubyte|float|char|string|lstring|enum|set)/xms;
# Capture index types e.g. primary or unique[12]
my $INDEX_RX = qr/(primary|index|unique) $FIELDSIZE_RX?/xms;
# Capture auto declaration
my $AUTO_RX = qr/\s(auto)/xms;

# Capture alternative back refs to other objects
my $DECLARETYPE_RX = qr/(object|simple|table)/xms;
# Capture overall structure of autosql file
my $DECLARE_RX = qr/^\s* $DECLARETYPE_RX \s+ (\w+) \s+ \"(.+)\" \s+ \((.+)\)$/xms;

# Capture a single field
my $FIELD_RX = qr/
(?:
(?:$FIELDSTYPE_RX (?:$FIELDSIZE_RX|$FIELDVALUES_RX)?)
|
# Capture declarative backrefs e.g. object obj[objCount] or simple point[1]
(?: $DECLARETYPE_RX \s* ($NAME_RX) $FIELDSIZE_RX? )
)
\s*
($NAME_RX)
\s*
$INDEX_RX? $AUTO_RX?
;
\s*
$QUOTEDSTR_RX
/xms;

#### END OF REGEXS

=pod

=head2 new($autosql)

Create a new object. Must give it an AutoSQL definition otherwise the library will throw an exception. The given string is also chomped.

=cut

sub new {
  my ($class, $autosql, $alternative_name_lookup) = @_;
  confess("Parse error; no AutoSQL data given") if ! $autosql;
  chomp $autosql;
  if(defined $alternative_name_lookup) {
    if(reftype($alternative_name_lookup) ne 'HASH') {
      confess 'Config error; expected a hash for alternative name lookup but was given a '.reftype($alternative_name_lookup);
    }
  }
  else {
    $alternative_name_lookup = {};
  }
  my $self = bless({
    raw => $autosql,
    type => '',
    name => '',
    comment => '',
    fields => [],
    alternative_name_lookup => {},
  }, (ref($class)||$class));
  $self->alternative_name_lookup($alternative_name_lookup);
  $self->_parse();
  return $self;
}

=pod alternative_name_lookup()

Give a hash where keys are alternative names and values are the target conversion name. The idea is you use the target conversion names at all times and the library will attempt to use this to translate between the two.

=cut

sub alternative_name_lookup {
  my ($self, $alternative_name_lookup) = @_;
  if(defined $alternative_name_lookup) {
    if(reftype($alternative_name_lookup) ne 'HASH') {
      confess 'Config error; expected a hash for alternative name lookup but was given a '.reftype($alternative_name_lookup);
    }
    $self->{alternative_name_lookup} = $alternative_name_lookup;
  }
  return $self->{alternative_name_lookup};
}

=pod

=head2 raw()

Getter for the raw AutoSQL definition

=cut

sub raw {
  my ($self) = @_;
  return $self->{raw};
}

=pod

=head2 name()

Getter for the name found in this AutoSQL definition

=cut

sub name {
  my ($self) = @_;
  return $self->{name};
}

=pod

=head2 type()

Getter for the type found in this AutoSQL definition

=cut

sub type {
  my ($self) = @_;
  return $self->{type};
}

=pod

=head2 comment()

Getter for the comment found in this AutoSQL definition

=cut

sub comment {
  my ($self) = @_;
  return $self->{comment};
}

=pod

=head2 fields()

Access an array of L<Bio::DB::Big::AutoSQLField> objects parsed from the given AutoSQL definition

=cut

sub fields {
  my ($self) = @_;
  return $self->{fields};
}

=pod

=head2 get_field($name)

Returns a L<Bio::DB::Big::AutoSQLField> object for the given name. Returns undef if the field is unavailable.

=cut

sub get_field {
  my ($self, $field_name) = @_;
  return if ! $self->has_field($field_name);
  my $field_lookup = $self->_field_lookup();
  if(exists $field_lookup->{$field_name}) {
    return $field_lookup->{$field_name};
  }
  else {
    my $alt_name_lookup = $self->alternative_name_lookup();
    my $alt_name = $alt_name_lookup->{$field_name};
    return $field_lookup->{$alt_name};
  }
  return;
}

=pod

=head2 has_field($name)

Return a boolean response if the given field is found in the parsed AutoSQL definition.

=cut

sub has_field {
  my ($self, $field_name) = @_;
  my $field_lookup = $self->_field_lookup();
  if(exists $field_lookup->{$field_name}) {
    return 1;
  }
  else {
    my $alt_name_lookup = $self->alternative_name_lookup();
    if(exists $alt_name_lookup->{$field_name}) {
      my $alt_name = $alt_name_lookup->{$field_name};
      if(exists $field_lookup->{$alt_name}) {
        return 1;
      }
    }
  }
  return 0;
}

=pod

=head2 is_table() 

Returns a boolean if this AutoSQL object represents a table i.e. the type is set to table

=cut

sub is_table {
  my ($self) = @_;
  my $type = $self->type();
  return ($type eq 'table') ? 1 : 0;
}

sub _field_lookup {
  my ($self) = @_;
  if(! $self->{_field_lookup}) {
    $self->{_field_lookup} = {
      map { $_->name, $_ }
      @{$self->{fields}}
    };
  }
  return $self->{_field_lookup};
}

# Calls both internal parser rountines
sub _parse {
  my ($self) = @_;
  my $raw_fields = $self->_parse_header();
  $self->_parse_fields($raw_fields);
  return;
}


# Runs the declare regex against the raw autosql. Pulls back the 
# header and all remaining unparsed fields i.e. anything between ().
# Throws an exception if the AutoSQL isn't formatted as expected
sub _parse_header {
  my ($self) = @_;
  if(my ($type, $name, $comment, $raw_fields) = $self->{raw} =~ $DECLARE_RX) {
    $self->{type} = $type;
    $self->{name} = $name;
    $self->{comment} = $comment;
    return $raw_fields;
  }
  confess 'Parse error; cannot parse AutoSQL provided';
}

# Loop through the fields (each one carridge returned) using the field regular expression.
# We currently parse 11 fields out some of which may be empty. Any changes to the  
# capture fields used in the regular expressions will have an impact on the order of capture
sub _parse_fields {
  my ($self, $raw_fields) = @_;
  my $position = 1;
  while($raw_fields =~ /$FIELD_RX/g) {

    my (
      $type, $field_size, $field_values, 
      $declare_type, $declare_name, $declare_size, 
      $name, 
      $index_type, $index_size, $auto, 
      $comment) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);

    # If no type is specified we default to the declared type
    if(! $type) {
      $type = $declare_type;
    }
    
    # Any set or enum needs splitting if present
    my @field_values_parsed;
    if($field_values) {
      @field_values_parsed = split /,\s*/, $field_values;
    }
    
    # Field and string need to be stringified (because they can be text as well as numerics)
    $field_size = "$field_size" if $field_size;
    $index_size = "$index_size" if $index_size;
    
    # Create the field, push and increment position
    my $field = Bio::DB::Big::AutoSQLField->new({
      type => $type,
      name => $name,
      comment => $comment,
      position => $position,
      field_size => $field_size,
      field_values => \@field_values_parsed,
      declare_size => $declare_size,
      declare_name => $declare_name,
      index_type => $index_type,
      index_size => $index_size,
      auto => $auto,
    });
    push(@{$self->{fields}}, $field);
    $position++;
  }
  return;
}

1;
