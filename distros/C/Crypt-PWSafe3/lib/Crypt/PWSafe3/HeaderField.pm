#
# Copyright (c) 2011-2015 T.v.Dein <tlinden |AT| cpan.org>.
#
# Licensed under the terms of the Artistic License 2.0
# see: http://www.perlfoundation.org/artistic_license_2_0
#
#
package Crypt::PWSafe3::HeaderField;

use Carp::Heavy;
use Carp;
use Exporter ();
use vars qw(@ISA @EXPORT);
use utf8;

$Crypt::PWSafe3::HeaderField::VERSION = '1.05';

%Crypt::PWSafe3::HeaderField::map2name = (
	    0x00 => "version",
	    0x01 => "uuid",
	    0x02 => "preferences",
	    0x03 => "treedisplaystatus",
	    0x04 => "lastsavetime",
	    0x05 => "wholastsaved",
	    0x06 => "whatlastsaved",
	    0x07 => "savedbyuser",
	    0x08 => "savedonhost",
	    0x09 => "databasename",
	    0x0a => "databasedescr",
	    0x0b => "databasefilters",
	    0xff => "eof"
	   );

%Crypt::PWSafe3::HeaderField::map2type = map { $Crypt::PWSafe3::HeaderField::map2name{$_} => $_ } keys %Crypt::PWSafe3::HeaderField::map2name;

my @fields = qw(raw len value type name);
foreach my $field (@fields) {
  eval  qq(
      *Crypt::PWSafe3::HeaderField::$field = sub {
              my(\$this, \$arg) = \@_;
              if (\$arg) {
                return \$this->{$field} = \$arg;
              }
              else {
                return \$this->{$field};
              }
      }
    );
}

sub new {
  #
  # new header field object
  my($this, %param) = @_;
  my $class = ref($this) || $this;
  my $self = \%param;
  bless($self, $class);

  if (! exists $param{type}) {
    if (exists $param{name}) {
      if (exists $Crypt::PWSafe3::HeaderField::map2type{$param{name}}) {
	$param{type} = $Crypt::PWSafe3::HeaderField::map2type{$param{name}};
      }
      else {
	croak "Unknown header type $param{name}";
      }
    }
    else {
      croak "HeaderField needs to have a type/name parameter!";
    }
  }

  if (exists $param{raw}) {
    if ($param{type} == 0x00) {
       $self->{value} = unpack('L<2', $param{raw});# maybe WW  or CC ?
    }
    elsif ($param{type} == 0x01) {
      $self->{value} = unpack('L<4', $param{raw});
    }
    elsif ($param{type} == 0x04) {
      $self->{value} = unpack('L<', $param{raw});
    }
    else {
      $self->{value} = $param{raw};
    }
    $self->{len} = length($param{raw});
  }
  else {
    if (exists $param{value}) {
      if ($param{type} == 0x00) {
	$self->{raw} = pack("L<2", $param{value});
      }
      elsif ($param{type} == 0x01) {
	$self->{raw} = pack('L<4', $param{value});
      }
      elsif ($param{type} == 0x04) {
	$self->{raw} = pack('L<', $param{value});
      }
      else {
	$self->{raw} = $param{value};
      }
    }
    else {
      croak "Either raw or value must be given to Crypt::PWSafe3::Field->new()";
    }
  }

  $self->{len} = length($param{raw});

  if (exists $Crypt::PWSafe3::HeaderField::map2name{$self->{type}}) {
    $self->{name} = $Crypt::PWSafe3::HeaderField::map2name{$self->{type}};
  }
  else {
    $self->{name} = $self->{type};
  }

  return $self;
}


sub eq {
  #
  # compare this field with the given one
  my ($this, $field) = @_;
  return $this->type == $field->type and $this->value eq $field->value;
}

=head1 NAME

Crypt::PWSafe3::HeaderField - represent a passwordsafe v3 header field.

=head1 SYNOPSIS

 use Crypt::PWSafe3;
 my $who = $vault->getheader('wholastsaved');
 print $who->value;

 my $h = Crypt::PWSafe3::HeaderField->new(name => 'savedonhost',
                                         value => 'localhost');
 $vault->addheader($h);

=head1 DESCRIPTION

B<Crypt::PWSafe3::HeaderField> represents a header field. This is the
raw implementation and you normally don't have to cope with it.

However, if you ever do, you can add/replace any field type
this way:

 my $field = Crypt::PWSafe3::HeaderField->new(
                                        value => 'localhost',
                                        name  => 'savedonhost'
                                      );
 $record->addheader($field);

This is the preferred way to do it, Crypt::PWSafe3 does
it internaly exactly like this.

If there already exists a field of this type, it will
be overwritten.

=head1 HEADER FIELDS

A password safe v3 database supports the following header fields:

version

uuid

preferences

treedisplaystatus

lastsavetime

wholastsaved

whatlastsaved

savedbyuser

savedonhost

databasename

databasedescr

databasefilters

eof

Refer to  L<Crypt::PWSafe3::Databaseformat> for details on those
header fields.

=head1 SEE ALSO

L<Crypt::PWSafe3>

=head1 AUTHOR

T.v.Dein <tlinden@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011-2015 by T.v.Dein <tlinden@cpan.org>.
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms of the Artistic
License 2.0, see: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
