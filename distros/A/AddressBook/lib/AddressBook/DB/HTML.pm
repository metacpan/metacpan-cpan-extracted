package AddressBook::DB::HTML;

=head1 NAME

AddressBook::DB::HTML - Backend for AddressBook to print entries in HTML format

=head1 SYNOPSIS

  use AddressBook;
  $a = AddressBook->new(source => "HTML");
  $a->write($entry);

=head1 DESCRIPTION

AddressBook::DB::HTML currently supports only the sequential write method.  

Behavior can be modified using the following options:

=over 4

=item write_format

The write_format string is eval'd to determine how the entry is written.  The default write_format string is:

  'table(Tr([map{td(["$_:",$attributes{$_}])} keys %attributes]))'

This displays the entry in a table with attribute names on the left and values on the right.
As can be seen, CGI.pm tag-generating functions can be used in format strings. The "%attributes" 
hash is available for use.  The keys of %attributes are HTML backend attribute names, and the 
values are the corresponding attribute values.  Specific attributes can also be referenced by 
name using a scalar with the same name as the attribute.   For example,

  'Name: $Name'

Assuming that "Name" is a valid HTML attribute, this format string will display entry names.
This is equivalent to:

  'Name: $attributes{Name}'

The HTML backend recognizes the string "keys %attributes", and substitues an expression which
ensures that the "order" meta-attribute is obeyed.

=item form_format

The form_format string is eval'd to construct an html entry form.  The default form_format string is:

  table(Tr({-valign=>"TOP"},[map{td([$_,$attributes{$_}])} keys %attributes]))

Which generates a table of fields with labels on the left.  The input type is based on the attribute type,
eg. "text" attributes appear as text input fields, "boolean" attributes appear as checkbox inputs, etc...
The default values of the entry fields are the current values of the entry's attributes.

=item intra_attr_sep

The string to use in joining multiple instances of the same attribute.  The default is "<br>"

=back

=cut

use strict;
use AddressBook;
use Carp;
use File::Basename;
use vars qw($VERSION @ISA);
use CGI qw(:standard);

$VERSION = '0.14';

@ISA = qw(AddressBook);

sub new {
  my $class = shift;
  my $self = {};
  bless ($self,$class);
  my %args = @_;
  foreach (keys %args) {
    $self->{$_} = $args{$_};
  }
  unless ($self->{write_format}) {$self->{write_format} = 'table(Tr({-valign=>"TOP"},[map{td(["$_:",$attributes{$_}])} keys %attributes]))'}
  unless ($self->{form_format}) {$self->{form_format} = 'table(Tr({-valign=>"TOP"},[map{td([$_,$attributes{$_}])} keys %attributes]))'}
  unless ($self->{intra_attr_sep}) {$self->{intra_attr_sep} = '<br>'}
  return $self;
}

sub write {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $entry = shift;
  my ($format,$ret,%attributes,$key,$url,$desc);
  $entry->calculate;
  my $attr = $entry->get(db=>$self->{db_name});
  foreach $key (keys %{$attr}) {
    if ($attr->{$key}->{meta}->{type} =~ /^(text|textblock|boolean|date|phone)$/) {
      $attributes{$key} = join ($self->{intra_attr_sep},@{$attr->{$key}->{value}});
    } elsif ($attr->{$key}->{meta}->{type} eq "url") {
      $attributes{$key} = join ($self->{intra_attr_sep},
			      map {a({-href=>$_},$_)} @{$attr->{$key}->{value}});
    } elsif ($attr->{$key}->{meta}->{type} eq "lurl") {
      $attributes{$key} = join ($self->{intra_attr_sep},
			      map {
				($url,$desc) = split (/\s+/, $_, 2);
				$desc ||= $url;
				a({-href=>$url},$desc)} @{$attr->{$key}->{value}});
    } elsif ($attr->{$key}->{meta}->{type} eq "email") {
      $attributes{$key} = join ($self->{intra_attr_sep},
			      map {a({-href=>"mailto:$_"},$_)} @{$attr->{$key}->{value}});
    }
  }
  $format = $self->{write_format};
  foreach (values %{$self->{config}->{db2generic}->{$self->{db_name}}}) {
    $format =~ s/\$($_)/\$attributes{$1}/g;
  }
  my @attributes = (sort {$attr->{$a}->{meta}->{order} <=> $attr->{$b}->{meta}->{order}} (keys %attributes));
  $format =~ s'keys %attributes'@attributes'g;
  eval qq{\$ret = $format}; warn "Syntax error in HTML backend \"write_format\": $@" if $@;
  return $ret;
}

sub entry_form {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $entry = shift;
  my $formname = shift;
  my ($format,$ret,$key,$option,@options,%selected,$i,%result,$default);
  #$entry->calculate;
  my $attr = $entry->get(db=>$self->{db_name});
  my %attributes = %{$entry->get(db=>$self->{db_name},values_only=>1)};
  foreach $key (keys %attributes) {
    if ($attr->{$key}->{meta}->{type} =~ /^(text|url|lurl|email|date|phone)$/) {
      if ($attr->{$key}->{meta}->{read_only} =~ /yes/i) {
	$result{$key} = join ($self->{intra_attr_sep}, 
			      @{$attributes{$key}});
      } else {
	$result{$key} = join ($self->{intra_attr_sep}, 
			      map {textfield(-name=>$key,
					     -size=>30,
					     -override=>1,
					     -default=>$_)} @{$attributes{$key}});
      }
    } elsif ($attr->{$key}->{meta}->{type} eq "textblock") {
      if ($attr->{$key}->{meta}->{read_only} =~ /yes/i) {
	$result{$key} = join ($self->{intra_attr_sep}, 
			      @{$attributes{$key}});
      } else {
	$result{$key} = join ($self->{intra_attr_sep}, 
			      map {textarea(-name=>$key,
					     -columns=>30,
					     -rows=>10,
					     -override=>1,
					     -default=>$_)} @{$attributes{$key}});
      }
    } elsif ($attr->{$key}->{meta}->{type} eq "select") {
      if ($attr->{$key}->{meta}->{read_only} =~ /yes/i) {
	$result{$key} = join ($self->{intra_attr_sep}, 
				  @{$attributes{$key}});
      } else {
	foreach (@{$attributes{$key}}) {
	  $selected{$_} = 1;
	}
	@options = split ",",$attr->{$key}->{meta}->{values};
	$result{$key} = "<select name=\"$key\" size=";
	$result{$key} .= $#options + 1;
	if ($attr->{$key}->{meta}->{non_multiple} !~ /yes/i) {
	  $result{$key} .=  " multiple";
	} 
	$result{$key} .= ">";
	foreach $option (@options) {
	  if (exists $selected{$option}) {
	    $result{$key} .= "<option selected>$option";
	  } else {
	    $result{$key} .= "<option>$option";
	  }
	}
	$result{$key} .= "</select>";
      }
    } elsif ($attr->{$key}->{meta}->{type} eq "boolean") {
      @options=();
      for ($i=0;$i<=$#{$attributes{$key}};$i++) {
	if ($attr->{$key}->{meta}->{read_only} =~ /yes/i) {
	  $options[$i] = $attributes{$key}->[$i];
	} else {
	  if ($attributes{$key}->[$i] =~ /yes/i) {
	    $options[$i] = "<input type=checkbox name=\"_${key}_$i\" value=\"yes\" checked>";
	  } else {
	    $options[$i] = "<input type=checkbox name=\"_${key}_$i\" value=\"yes\">";
	  }
	  #$options[$i] = "<table><tr><td>";
	  #$options[$i] .= radio_group(-name=>"_${key}_$i",
				     #-values=>['Yes','No'],
				     #-default=>$attributes{$key}->[$i] || 'empty',
				     #-override=>1,
				     #-columns=>1);
	  #$options[$i] .= "</td>";
	  #if ($formname) {
	    #$options[$i] .= "<td><input type=button value=Clear onClick=\"
                              #document.$formname.elements[\'_${key}_$i\'][0].checked=0;
                              #document.$formname.elements[\'_${key}_$i\'][1].checked=0;\"></td>";
	  #}
	  #$options[$i] .= "</tr></table>";
	}
      }
      $result{$key} = join ($self->{intra_attr_sep},@options);
      $result{$key} .= "<input type=hidden name=\"_${key}_count\" value=$#options>";
    }
  }
  %attributes = %result;
  $format = $self->{form_format};
  foreach (values %{$self->{config}->{db2generic}->{$self->{db_name}}}) {
    $format =~ s/\$($_)/\$attributes{$1}/g;
  }
  my @attributes = (sort {$attr->{$a}->{meta}->{order} <=> $attr->{$b}->{meta}->{order}} (keys %attributes));
  $format =~ s'keys %attributes'@attributes'g;
  eval qq{\$ret = $format}; warn "Syntax error in HTML backend \"form_format\": $@" if $@;
  return $ret;
}

sub read_from_args {
  my $self = shift;
  my $class = ref $self || croak "Not a method call";
  my $query = shift;
  my ($key,$canon_field_name,@value,$i,$key_count);
  my $entry = AddressBook::Entry->new(config=>$self->{config});
  foreach $key (keys %{$self->{config}->{db2generic}->{$self->{db_name}}}) {
    $canon_field_name = $self->{config}->{db2generic}->{$self->{db_name}}->{$key};
    if ($self->{config}->{meta}->{$canon_field_name}->{type} eq "boolean" ) {
      $key_count = $query->param("_${key}_count");
      if ((defined $key_count) && ($key_count >= 0)) {
	for ($i=0;$i<=$key_count;$i++) {
	  if ($query->param("_${key}_$i") =~ /yes/i) {
	    $value[$i] = "Yes";
	  } else {
	    $value[$i] = "No";
	  }
	}
      }
      $entry->add(db=>$self->{db_name},attr=>{$key=>\@value});
    } else {
      foreach ($query->param($key)) {
	$entry->add(db=>$self->{db_name},attr=>{$key=>$_});
      }
    }
  }
  $entry->chop;
  return $entry;
}

1;
__END__

=head1 AUTHOR

Mark A. Hershberger, <mah@everybody.org>
David L. Leigh, <dleigh@sameasiteverwas.net>

=head1 SEE ALSO

L<AddressBook>,
L<AddressBook::Config>,
L<AddressBook::Entry>.

=cut
