#
# Copyright (c) 2011-2015 T.v.Dein <tlinden |AT| cpan.org>.
#
# Licensed under the terms of the Artistic License 2.0
# see: http://www.perlfoundation.org/artistic_license_2_0
#
package Crypt::PWSafe3::Field;


use Carp::Heavy;
use Carp;
use Exporter ();
use vars qw(@ISA @EXPORT);
use utf8;

$Crypt::PWSafe3::Field::VERSION = '1.06';

%Crypt::PWSafe3::Field::map2type = (
		uuid     => 0x01,
		group    => 0x02,
		title    => 0x03,
		user     => 0x04,
		passwd   => 0x06,
		notes    => 0x05,
		ctime    => 0x07,
		mtime    => 0x08,
		atime    => 0x09,
		reserve  => 0x0b,
		lastmod  => 0x0c,
		url      => 0x0d,
		autotype => 0x0e,
		pwhist   => 0x0f,
		pwpol    => 0x10,
		pwexp    => 0x11,
		eof      => 0xff
	      );
%Crypt::PWSafe3::Field::map2name = map { $Crypt::PWSafe3::Field::map2type{$_} => $_ } keys %Crypt::PWSafe3::Field::map2type;

my @fields = qw(raw len value type name);
foreach my $field (@fields) {
  eval  qq(
      *Crypt::PWSafe3::Field::$field = sub {
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
  # new field object
  my($this, %param) = @_;
  my $class = ref($this) || $this;
  my $self = \%param;
  bless($self, $class);



  if (! exists $param{type}) {
    if (exists $param{name}) {
      $param{type} = $Crypt::PWSafe3::Field::map2type{$param{name}};
    }
    else {
      croak "HeaderField needs to have a type/name parameter!";
    }
  }

  my @convtime = (0x07, 0x08, 0x09, 0x0a, 0x0c);
  my @convhex  = (0x01);
  my @convbyte = (0x00, 0x11);

  if (exists $param{raw}) {
    if (grep { $_ eq $param{type} } @convtime) {
      $self->{value} = unpack("L<", $param{raw});
    }
    elsif (grep { $_ eq $param{type} } @convhex) {
      $self->{value} = unpack('H*', $param{raw});
    }
    elsif (grep { $_ eq $param{type} } @convbyte) {
      $self->{value} = unpack('S<', $param{raw});
    }
    else {
      $self->{value} = $param{raw};
      utf8::decode($self->{value});
    }
    $self->{len} = length($param{raw});
  }
  else {
    if (exists $param{value}) {
      if (grep { $_ eq $param{type} } @convtime) {
	$self->{raw} = pack("L<", $param{value});
      }
      elsif (grep { $_ eq $param{type} } @convhex) {
	$self->{raw} = pack('H*', $param{value});
      }
      elsif (grep { $_ eq $param{type} } @convbyte) {
	$self->{raw} = pack('S<', $param{value});
      }
      else {
	$self->{raw} = $param{value};
	utf8::encode($param{raw});
      }
    }
    else {
      croak "Either raw or value must be given to Crypt::PWSafe3::Field->new()";
    }
  }

  $self->{len} = length($param{raw});

  if (exists $Crypt::PWSafe3::Field::map2name{$self->{type}}) {
    $self->{name} = $Crypt::PWSafe3::Field::map2name{$self->{type}};
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

Crypt::PWSafe3::Field - represent a passwordsafe v3 record field.

=head1 SYNOPSIS

 use Crypt::PWSafe3;
 my $record = $vault->getrecord($uuid);
 print $record-{field}->{user}->raw();
 print $record-{field}->{user}->len();

=head1 DESCRIPTION

B<Crypt::PWSafe3::Field> represents a record field. This is the
raw implementation and you normally don't have to cope with it.

However, if you ever do, you can do it this way:

 my $field = Crypt::PWSafe3::Field->new(
                                        value => 'testing',
                                        name  => 'title
                                      );
 $record->addfield($field);

This is the preferred way to do it, Crypt::PWSafe3 does
it internaly exactly like this.

If there already exists a record field of this type, it will
be overwritten.

The better way to handle fields is the method B<modifyfield()>
of the class L<Crypt::PWSafe3::Record>.

=head1 SEE ALSO

L<Crypt::PWSafe3::Record>

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
