use strict;
use warnings;
package Data::GUID;
# ABSTRACT: globally unique identifiers
$Data::GUID::VERSION = '0.049';
use Carp ();
use Data::UUID 1.148;
use Sub::Install 0.03;

#pod =head1 SYNOPSIS
#pod
#pod   use Data::GUID;
#pod
#pod   my $guid = Data::GUID->new;
#pod
#pod   my $string = $guid->as_string; # or "$guid"
#pod
#pod   my $other_guid = Data::GUID->from_string($string);
#pod
#pod   if (($guid <=> $other_guid) == 0) {
#pod     print "They're the same!\n";
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod Data::GUID provides a simple interface for generating and using globally unique
#pod identifiers.
#pod
#pod =head1 GETTING A NEW GUID
#pod
#pod =head2 new
#pod
#pod   my $guid = Data::GUID->new;
#pod
#pod This method returns a new globally unique identifier.
#pod
#pod =cut

my $_uuid_gen_obj;
my $_uuid_gen_pid;
my $_uuid_gen = sub {
  return $_uuid_gen_obj if $_uuid_gen_obj
                        && $_uuid_gen_pid == $$;

  $_uuid_gen_pid = $$;
  $_uuid_gen_obj = Data::UUID->new;
};

sub new {
  my ($class) = @_;

  return $class->from_data_uuid($_uuid_gen->()->create);
}

#pod =head1 GUIDS FROM EXISTING VALUES
#pod
#pod These method returns a new Data::GUID object for the given GUID value.  In all
#pod cases, these methods throw an exception if given invalid input.
#pod
#pod =head2 from_string
#pod
#pod   my $guid = Data::GUID->from_string("B0470602-A64B-11DA-8632-93EBF1C0E05A");
#pod
#pod =head2 from_hex
#pod
#pod   # note that a hex guid is a guid string without hyphens and with a leading 0x
#pod   my $guid = Data::GUID->from_hex("0xB0470602A64B11DA863293EBF1C0E05A");
#pod
#pod =head2 from_base64
#pod
#pod   my $guid = Data::GUID->from_base64("sEcGAqZLEdqGMpPr8cDgWg==");
#pod
#pod =head2 from_data_uuid
#pod
#pod This method returns a new Data::GUID object if given a Data::UUID value.
#pod Because Data::UUID values are not blessed and because Data::UUID provides no
#pod validation method, this method will only throw an exception if the given data
#pod is of the wrong size.
#pod
#pod =cut

sub from_data_uuid {
  my ($class, $value) = @_;

  my $length = do { use bytes; defined $value ? length $value : 0; };
  Carp::croak "given value is not a valid Data::UUID value" if $length != 16;
  bless \$value => $class;
}

#pod =head1 IDENTIFYING GUIDS
#pod
#pod =head2 string_guid_regex
#pod
#pod =head2 hex_guid_regex
#pod
#pod =head2 base64_guid_regex
#pod
#pod These methods return regex objects that match regex strings of the appropriate
#pod type.
#pod
#pod =cut

my ($hex, $base64, %type);

BEGIN { # because %type must be populated for method/exporter generation
  $hex    = qr/[0-9A-F]/i;
  $base64 = qr{[A-Z0-9+/=]}i;

  %type = ( # uuid_method  validation_regex
    string => [ 'string',     qr/\A$hex{8}-?(?:$hex{4}-?){3}$hex{12}\z/, ],
    hex    => [ 'hexstring',  qr/\A0x$hex{32}\z/,                        ],
    base64 => [ 'b64string',  qr/\A$base64{24}\z/,                       ],
  );

  for my $key (keys %type) {
    no strict 'refs';
    my $subname = "$key\_guid_regex";
    *$subname = sub { $type{ $key }[1] }
  }
}

# provided for test scripts
sub __type_regex { shift; $type{$_[0]}[1] }

sub _install_from_method {
  my ($type, $alien_method, $regex) = @_;
  my $alien_from_method = "from_$alien_method";

  my $our_from_code = sub {
    my ($class, $string) = @_;
    $string ||= q{}; # to avoid (undef =~) warning
    Carp::croak qq{"$string" is not a valid $type GUID} if $string !~ $regex;
    $class->from_data_uuid( $_uuid_gen->()->$alien_from_method($string) );
  };

  Sub::Install::install_sub({ code => $our_from_code, as => "from_$type" });
}

sub _install_as_method {
  my ($type, $alien_method) = @_;

  my $alien_to_method = "to_$alien_method";

  my $our_to_method = sub {
    my ($self) = @_;
    $_uuid_gen->()->$alien_to_method( $self->as_binary );
  };

  Sub::Install::install_sub({ code => $our_to_method, as => "as_$type" });
}

BEGIN { # possibly unnecessary -- rjbs, 2006-03-11
  do {
    while (my ($type, $profile) = each %type) {
      _install_from_method($type, @$profile);
      _install_as_method  ($type, @$profile);
    }
  };
}

sub _from_multitype {
  my ($class, $what, $types) = @_;
  sub {
    my ($class, $value) = @_;
    return $value if eval { $value->isa('Data::GUID') };

    my $value_string = defined $value ? qq{"$value"} : 'undef';

    # The only good ref is a blessed ref, and only into our denomination!
    if (my $ref = ref $value) {
      Carp::croak "a $ref reference is not a valid GUID $what"
    }

    for my $type (@$types) {
      my $from = "from_$type";
      my $guid = eval { $class->$from($value); };
      return $guid if $guid;
    }

    Carp::croak "$value_string is not a valid GUID $what";
  }
}

#pod =head2 from_any_string
#pod
#pod   my $string = get_string_from_ether;
#pod
#pod   my $guid = Data::GUID->from_any_string($string);
#pod
#pod This method returns a Data::GUID object for the given string, trying all known
#pod string interpretations.  An exception is thrown if the value is not a valid
#pod GUID string.
#pod
#pod =cut

BEGIN { # possibly unnecessary -- rjbs, 2006-03-11
  Sub::Install::install_sub({
    code => __PACKAGE__->_from_multitype('string', [ keys %type ]),
    as   => 'from_any_string',
  });
}

#pod =head2 best_guess
#pod
#pod   my $value = get_value_from_ether;
#pod
#pod   my $guid = Data::GUID->best_guess($value);
#pod
#pod This method returns a Data::GUID object for the given value, trying everything
#pod it can.  It works like C<L</from_any_string>>, but will also accept Data::UUID
#pod values.  (In effect, this means that any sixteen byte value is acceptable.)
#pod
#pod =cut

BEGIN { # possibly unnecessary -- rjbs, 2006-03-11
  Sub::Install::install_sub({
    code => __PACKAGE__->_from_multitype('value', [(keys %type), 'data_uuid']),
    as   => 'best_guess',
  });
}

#pod =head1 GUIDS INTO STRINGS
#pod
#pod These methods return various string representations of a GUID.
#pod
#pod =head2 as_string
#pod
#pod This method returns a "traditional" GUID/UUID string representation.  This is
#pod five hexadecimal strings, delimited by hyphens.  For example:
#pod
#pod   B0470602-A64B-11DA-8632-93EBF1C0E05A
#pod
#pod This method is also used to stringify Data::GUID objects.
#pod
#pod =head2 as_hex
#pod
#pod This method returns a plain hexadecimal representation of the GUID, with a
#pod leading C<0x>.  For example:
#pod
#pod   0xB0470602A64B11DA863293EBF1C0E05A
#pod
#pod =head2 as_base64
#pod
#pod This method returns a base-64 string representation of the GUID.  For example:
#pod
#pod   sEcGAqZLEdqGMpPr8cDgWg==
#pod
#pod =cut

#pod =head1 OTHER METHODS
#pod
#pod =head2 compare_to_guid
#pod
#pod This method compares a GUID to another GUID and returns -1, 0, or 1, as do
#pod other comparison routines.
#pod
#pod =cut

sub compare_to_guid {
  my ($self, $other) = @_;

  my $other_binary
    = eval { $other->isa('Data::GUID') } ? $other->as_binary : $other;

  $_uuid_gen->()->compare($self->as_binary, $other_binary);
}

#pod =head2 as_binary
#pod
#pod This method returns the packed binary representation of the GUID.  At present
#pod this method relies on Data::GUID's underlying use of Data::UUID.  It is not
#pod guaranteed to continue to work the same way, or at all.  I<Caveat invocator>.
#pod
#pod =cut

sub as_binary {
  my ($self) = @_;
  $$self;
}

use overload
  q{""} => 'as_string',
  '<=>' => sub { ($_[2] ? -1 : 1) * $_[0]->compare_to_guid($_[1]) },
  fallback => 1;

#pod =head1 IMPORTING
#pod
#pod Data::GUID does not export any subroutines by default, but it provides a few
#pod routines which will be imported on request.  These routines may be called as
#pod class methods, or may be imported to be called as subroutines.  Calling them by
#pod fully qualified name is incorrect.
#pod
#pod   use Data::GUID qw(guid);
#pod
#pod   my $guid = guid;             # OK
#pod   my $guid = Data::GUID->guid; # OK
#pod   my $guid = Data::GUID::guid; # NOT OK
#pod
#pod =cut

#pod =head2 guid
#pod
#pod This routine returns a new Data::GUID object.
#pod
#pod =head2 guid_string
#pod
#pod This returns the string representation of a new GUID.
#pod
#pod =head2 guid_hex
#pod
#pod This returns the hex representation of a new GUID.
#pod
#pod =head2 guid_base64
#pod
#pod This returns the base64 representation of a new GUID.
#pod
#pod =head2 guid_from_anything
#pod
#pod This returns the result of calling the C<L</from_any_string>> method.
#pod
#pod =cut

BEGIN {
  Sub::Install::install_sub({ code => 'new', as => 'guid' });

  for my $type (keys %type) {
    my $method = "guid_$type";
    my $as     = "as_$type";

    Sub::Install::install_sub({
      as   => $method,
      code => sub {
        my ($class) = @_;
        $class->new->$as;
      },
    });
  }
}

sub _curry_class {
  my ($class, $subname, $eval) = @_;
  return $eval ? sub { eval { $class->$subname(@_) } }
               : sub { $class->$subname(@_) };
}

my %exports;
BEGIN {
  %exports
    = map { my $method = $_; $_ => sub { _curry_class($_[0], $method) } }
    ((map { "guid_$_" } keys %type), 'guid');
}

use Sub::Exporter 0.90 -setup => {
  exports => {
    %exports, # defined just above
    guid_from_anything => sub { _curry_class($_[0], 'from_any_string', 1) },
  }
};

#pod =head1 TODO
#pod
#pod =for :list
#pod * add namespace support
#pod * remove dependency on wretched Data::UUID
#pod * make it work on 5.005
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::GUID - globally unique identifiers

=head1 VERSION

version 0.049

=head1 SYNOPSIS

  use Data::GUID;

  my $guid = Data::GUID->new;

  my $string = $guid->as_string; # or "$guid"

  my $other_guid = Data::GUID->from_string($string);

  if (($guid <=> $other_guid) == 0) {
    print "They're the same!\n";
  }

=head1 DESCRIPTION

Data::GUID provides a simple interface for generating and using globally unique
identifiers.

=head1 GETTING A NEW GUID

=head2 new

  my $guid = Data::GUID->new;

This method returns a new globally unique identifier.

=head1 GUIDS FROM EXISTING VALUES

These method returns a new Data::GUID object for the given GUID value.  In all
cases, these methods throw an exception if given invalid input.

=head2 from_string

  my $guid = Data::GUID->from_string("B0470602-A64B-11DA-8632-93EBF1C0E05A");

=head2 from_hex

  # note that a hex guid is a guid string without hyphens and with a leading 0x
  my $guid = Data::GUID->from_hex("0xB0470602A64B11DA863293EBF1C0E05A");

=head2 from_base64

  my $guid = Data::GUID->from_base64("sEcGAqZLEdqGMpPr8cDgWg==");

=head2 from_data_uuid

This method returns a new Data::GUID object if given a Data::UUID value.
Because Data::UUID values are not blessed and because Data::UUID provides no
validation method, this method will only throw an exception if the given data
is of the wrong size.

=head1 IDENTIFYING GUIDS

=head2 string_guid_regex

=head2 hex_guid_regex

=head2 base64_guid_regex

These methods return regex objects that match regex strings of the appropriate
type.

=head2 from_any_string

  my $string = get_string_from_ether;

  my $guid = Data::GUID->from_any_string($string);

This method returns a Data::GUID object for the given string, trying all known
string interpretations.  An exception is thrown if the value is not a valid
GUID string.

=head2 best_guess

  my $value = get_value_from_ether;

  my $guid = Data::GUID->best_guess($value);

This method returns a Data::GUID object for the given value, trying everything
it can.  It works like C<L</from_any_string>>, but will also accept Data::UUID
values.  (In effect, this means that any sixteen byte value is acceptable.)

=head1 GUIDS INTO STRINGS

These methods return various string representations of a GUID.

=head2 as_string

This method returns a "traditional" GUID/UUID string representation.  This is
five hexadecimal strings, delimited by hyphens.  For example:

  B0470602-A64B-11DA-8632-93EBF1C0E05A

This method is also used to stringify Data::GUID objects.

=head2 as_hex

This method returns a plain hexadecimal representation of the GUID, with a
leading C<0x>.  For example:

  0xB0470602A64B11DA863293EBF1C0E05A

=head2 as_base64

This method returns a base-64 string representation of the GUID.  For example:

  sEcGAqZLEdqGMpPr8cDgWg==

=head1 OTHER METHODS

=head2 compare_to_guid

This method compares a GUID to another GUID and returns -1, 0, or 1, as do
other comparison routines.

=head2 as_binary

This method returns the packed binary representation of the GUID.  At present
this method relies on Data::GUID's underlying use of Data::UUID.  It is not
guaranteed to continue to work the same way, or at all.  I<Caveat invocator>.

=head1 IMPORTING

Data::GUID does not export any subroutines by default, but it provides a few
routines which will be imported on request.  These routines may be called as
class methods, or may be imported to be called as subroutines.  Calling them by
fully qualified name is incorrect.

  use Data::GUID qw(guid);

  my $guid = guid;             # OK
  my $guid = Data::GUID->guid; # OK
  my $guid = Data::GUID::guid; # NOT OK

=head2 guid

This routine returns a new Data::GUID object.

=head2 guid_string

This returns the string representation of a new GUID.

=head2 guid_hex

This returns the hex representation of a new GUID.

=head2 guid_base64

This returns the base64 representation of a new GUID.

=head2 guid_from_anything

This returns the result of calling the C<L</from_any_string>> method.

=head1 TODO

=over 4

=item *

add namespace support

=item *

remove dependency on wretched Data::UUID

=item *

make it work on 5.005

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Ricardo SIGNES

Ricardo SIGNES <rjbs@codesimply.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
