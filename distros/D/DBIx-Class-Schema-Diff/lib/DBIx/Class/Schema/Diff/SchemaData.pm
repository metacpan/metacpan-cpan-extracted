package DBIx::Class::Schema::Diff::SchemaData;
use strict;
use warnings;

# ABSTRACT: Data representation of schema for diffing

use Moo;
with 'DBIx::Class::Schema::Diff::Role::Common';

use Types::Standard qw(:all);
use Module::Runtime;
use Scalar::Util qw(blessed);
use Path::Class qw(file);
use JSON;
use Clone 'clone';
use Digest::SHA1;

use Data::Dumper;
use Data::Dumper::Concise;

has 'schema', is => 'ro', isa => Maybe[InstanceOf[
  'DBIx::Class::Schema'
]], coerce => \&_coerce_schema, default => sub {undef};

has 'data', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  die "You must supply a schema or an existing data packet"
    unless ($self->schema);
  
  return $self->_gen_data( $self->schema );

}, isa => HashRef, coerce => \&_coerce_deep_unsafe_refs;


sub BUILD {
  my $self = shift;

  # initialize:
  $self->data;
}

sub sources {
  my $self = shift;
  return sort keys %{ $self->data->{sources} || {} };
}

sub source {
  my ($self, $name) = @_;
  return $self->data->{sources}{$name};
}

sub dump_json {
  my $self = shift;
  JSON::to_json( $self->data => { pretty => 1 });
}

sub dump_json_file {
  my ($self, $path) = @_;
  die "Filename required" unless ($path);
  my $file = file($path)->absolute;
  
  die "Target file '$file' already exists." if (-e $file);
  
  my $out_fh;
  open $out_fh, '>', $file or die "Could not open $file: $!";
  print $out_fh JSON::to_json( $self->data, { pretty => 1 });
  close $out_fh;
  return -f $file ? 1 : 0;
}


sub _gen_data {
  my ($self, $schema) = @_;
  
  my $data = {
    schema_class => (blessed $schema),
    sources => {
      map {
        my $Source = $schema->source($_);
        $_ => {
        
          columns => {
            map {
              $_ => $Source->column_info($_)
            } $Source->columns
          },
          
          relationships => {
            map {
              $_ => $Source->relationship_info($_)
            } $Source->relationships
          },
          
          constraints => {
            map {
              $_ => { columns => [$Source->unique_constraint_columns($_)] }
            } $Source->unique_constraint_names
          },
          
          table_name => $Source->from,
          
          isa => mro::get_linear_isa( $schema->class( $Source->source_name ) ),

        }
      } $schema->sources 
    }
  };
  
  return $self->_localize_deep_namespace_strings($data,$data->{schema_class});
}


sub _coerce_schema {
  my ($v) = @_;
  return $v if (!$v || ref $v);
  
  # Its a class name:
  Module::Runtime::require_module($v);
  return $v->can('connect') ? $v->connect('dbi:SQLite::memory:','','') : $v;
}


sub _coerce_deep_unsafe_refs {
  my ($v) = @_;
  my $rt = ref($v) or return $v;
  
  if($rt eq 'HASH') {
    return { map { $_ => &_coerce_deep_unsafe_refs($v->{$_}) } keys %$v };
  }
  elsif($rt eq 'ARRAY') {
    return [ map { &_coerce_deep_unsafe_refs($_) } @$v ];
  }
  elsif($rt eq 'CODE') {
    # TODO: we don't have to do this, we could let it through
    # to be stringified, but for now, we're not trying to compare
    # CodeRef contents
    return 'sub { "DUMMY" }';
  }
  else {
    # For all other refs, stringify them with Dumper. These will still
    # be just as useful for diff/compare. This makes them safe for JSON, etc
    my $str = Dumper($v);
    # strip newlines:
    $str =~ s/\r?\n//g;
    # normalize whitespace:
    $str =~ s/\s+/ /g;
    return $str;
  }
}

sub _localize_deep_namespace_strings {
  my ($self, $v, $ns) = @_;
  my $rt = ref($v);
  if($rt) {
    if($rt eq 'HASH') {
      return { map {
        $_ => $self->_localize_deep_namespace_strings($v->{$_},$ns)
      } keys %$v };
    }
    elsif($rt eq 'ARRAY') {
      return [ map {
        $self->_localize_deep_namespace_strings($_,$ns)
      } @$v ];
    }
    else {
      return $v;
    }
  }
  else {
    # swap the namespace prefix string for literal '{schema_class}':
    $v =~ s/^${ns}/\{schema_class\}/ if($v && $ns && $v ne $ns);
    return $v;
  }
}


sub prune {
  my ($self,@keywords) = @_;
  die "must supply at least 1 prune keyword" unless (scalar(@keywords) > 0);
  
  my $data = clone( $self->data );
  
  my @meths = map {
    my $meth = join('_','__prune',$_);
    $self->can($meth) or die "Bad prune keyword '$_' (no such method '$meth')";
    $meth
  } @keywords;
  
  $self->$_($data) for (@meths);

  __PACKAGE__->new({ data => $data })
}


sub __prune_isa {
  my ($self, $data) = @_;
  $self->_prune_whole_source_key('isa',$data)
}

sub __prune_constraints {
  my ($self, $data) = @_;
  $self->_prune_whole_source_key('constraints',$data)
}

sub __prune_relationships {
  my ($self, $data) = @_;
  $self->_prune_whole_source_key('relationships',$data)
}

sub __prune_columns {
  my ($self, $data) = @_;
  $self->_prune_whole_source_key('columns',$data)
}


sub __prune_private_col_attrs {
  my ($self, $data) = @_;
  
  for my $rsrcData (values %{ $data->{sources} }) {
    if(my $columns = $rsrcData->{columns}) {
      for my $attrs (values %$columns) {
        # delete all keys starting with underscore '_'
        $_ =~ /^_/ and delete $attrs->{$_} for (keys %$attrs);
      }
    }
  }
  
  $data
}


sub _prune_whole_source_key {
  my ($self, $key, $data) = @_;
  
  for my $rsrcData (values %{ $data->{sources} }) {
    delete $rsrcData->{$key} if exists $rsrcData->{$key}
  }
  
  $data
}


sub fingerprint {
  my $self = shift;
  my $sum = Digest::SHA1->new->add( $self->_string_for_signature )->hexdigest;
  join('-', 'schemsum', substr($sum,0,15) )
}


# So far this is the only thing I could find to produce a consistent string value across all
# Travis tested perls (5.10,5.12,5.14,5.16,5.18,5.20,5.22,5.24,5.26)
sub _string_for_signature {
  my $self = shift;
  
  local $Data::Dumper::Maxdepth = 0;
  Data::Dumper->new([ $self->data->{sources} ])
   ->Purity(0)
   ->Terse(1)
   ->Indent(0)
   ->Useqq(1)
   ->Sortkeys(1)
   ->Dump()
}


1;


__END__

=head1 NAME

DBIx::Class::Schema::Diff::SchemaDiff - Data representation of schema for diffing

=head1 SYNOPSIS

 use DBIx::Class::Schema::Diff::SchemaData;
 
 my $SD = DBIx::Class::Schema::Diff::SchemaData->new( 
  schema => 'My::Schema'
 );
 
 $SD = DBIx::Class::Schema::Diff::SchemaData->new( 
  schema => $schema
 );
 
 # Get hashref representation of schema:
 my $hashref = $SD->data;
 
 my $SD2 = DBIx::Class::Schema::Diff::SchemaData->new( 
  data => $hashref
 );
 
 # Dump as JSON to file:
 $SD2->dump_json_file('/path/to/schema_data.json');
 

=head1 DESCRIPTION

Object class representing a DBIx::Class::Schema. The C<old_schema> and C<new_schema> build
params in L<DBIx::Class::Schema::Diff> are dynamically coerced into objects of this class. 

This class can also be instantiated directly to dump/save the current schema data for 
later use by L<DBIx::Class::Schema::Diff> (See its SYNOPSIS).

=head1 METHODS

=head2 new

Create a new DBIx::Class::Schema::Diff::SchemaData instance. The following build options are supported:

=over 4

=item schema

DBIx::Class schema supplied as a class name or connected object instance. If this param is supplied
it will be used to build C<data>.

=item data

Can be supplied instead of C<schema> to use previously generated data. 

=back

=head2 dump_json

Returns C<data> as a serialized JSON string.

=head2 dump_json_file

Writes output of C<dump_json()> to the supplied filename as long as it doesn't already exists. If the
file already exists, an exception is thrown.

=head2 prune

Accepts a list of one or more prune C<keywords> and returns a new C<SchemaData> object with the
specified information pruned/stripped from the C<data>. Currently supported prune keywords:

=over 4

=item isa

=item constraints

=item relationships

=item columns

=item private_col_attrs

=back

=head2 fingerprint

Returns a sha1-based fingerprint string of the current data. Note that C<prune> will result in 
different fingerprints. An example fingerprint is C<schemsum-448d754e40e09e0>. The 'schemsum' prefix
is just for fun (and also provides an easy way to eyeball these values down the road).


=head1 SEE ALSO

=over

=item *

L<DBIx::Class::Schema::Diff>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
