# -*-cperl-*-
#
# Crypt::Unsnoopable - Completely unsnoopable messaging
# Copyright (c) Ashish Gulhati <crypt-unsnoopable at hash.neo.tc>
#
# $Id: lib/Crypt/Unsnoopable.pm v1.010 Tue Oct 16 21:04:28 PDT 2018 $

package Crypt::Unsnoopable;

use warnings;
use strict;
use Bytes::Random::Secure;
use Persistence::Object::Simple;
use Compress::Zlib;
use Math::Prime::Util qw(fromdigits todigitstring);

use vars qw( $VERSION $AUTOLOAD @ISA @EXPORT_OK );

@ISA = qw(Exporter);
@EXPORT_OK = qw(dec heX);

our ( $VERSION ) = '$Revision: 1.010 $' =~ /\s+([\d\.]+)/;

sub new {
  my ($class, %arg) = @_;
  my $self = bless { debug     => $arg{Debug} || 1,
		     db        => $arg{DB} || '/tmp/.unsnoopable',
		   }, $class;
  $self->{otps} = { map { my $o = new Persistence::Object::Simple ('__Fn' => $_); (pack('H*', $o->{name}) => $o) }
		    glob("$self->{db}/*.otp") };
  return $self;
}

sub otpgen {
  my ($self, $size, $name) = @_;
  my $r = Bytes::Random::Secure->new( Bits => 256 );
  my $pad = $r->bytes($size+4);
  local $SIG{'__WARN__'} = sub { };
  my $pad_id = dec(unpack('H*', substr($pad, 0, 4, '')));
  my $pad_obj = new Persistence::Object::Simple ('__Fn' => $self->db . "/$pad_id.otp");
  $pad_obj->{id} = $pad_id;
  $pad_obj->{pad} = unpack('H*', $pad);
  $pad_obj->{name} = unpack('H*', $name);
  $pad_obj->commit;
  $self->{otps}->{$name} = $pad_obj;
  return $pad_obj;
}

sub add {
  my ($self, $pad, $name) = @_;
  local $SIG{'__WARN__'} = sub { };
  my $hexpad = heX($pad); my $pad_id = dec(substr($hexpad, 0, 8, ''));
  my $padfn = $self->db . "/$pad_id.otp";
  return if -e $padfn;
  my $pad_obj = new Persistence::Object::Simple ('__Fn' => $padfn);
  $pad_obj->{id} = $pad_id;
  $pad_obj->{pad} = $hexpad;
  $pad_obj->{name} = unpack('H*', $name);
  $pad_obj->commit;
  $self->{otps}->{$name} = $pad_obj;
}

sub encrypt {
  my ($self, $pad_name, $msg) = @_;
  return unless exists $self->{otps}->{$pad_name};
  my $pad = $self->{otps}->{$pad_name};
  my $compressed = compress($msg);
  return unless (length($compressed)+4)*2 <= length($pad->{pad});
  my $key = pack('H*',substr($pad->{pad}, 0, (length($compressed)+4)*2, ''));
  $self->otps->{$pad_name}->commit;
  my $encrypted = "\x00\x00\x00\x00$compressed" ^ "$key";
  local $SIG{'__WARN__'} = sub { };
  dec(heX($pad->{id}) . unpack('H*',$encrypted));
}

sub decrypt {
  my ($self, $ciphertext) = @_;
  local $SIG{'__WARN__'} = sub { };
  my $hex = heX($ciphertext);
  my $pad_id = dec(substr($hex, 0, 8, ''));
  my $pad_start = substr($hex, 0, 8);
  my $pads = $self->otps;
  return unless my ($pad_name) = grep { $pads->{$_}->{id} eq $pad_id } keys %$pads;
  my $pad = $pads->{$pad_name}; my $padlen = length($pad->{pad});
  return unless substr($pad->{pad}, 0, 8) eq $pad_start;
  return unless length($hex) <= $padlen;
  my $encrypted = pack('H*',$hex);
  my $key = pack('H*',substr($pad->{pad}, 0, length($hex), ''));
  $pad->commit;
  my $compressed = "$encrypted" ^ "$key";
  my $decrypted = uncompress(substr($compressed,4));
  return ($decrypted, $pad, $padlen/2);
}

sub AUTOLOAD {
  my $self = shift; (my $auto = $AUTOLOAD) =~ s/.*:://;
  return if $auto eq 'DESTROY';
  if ($auto =~ /^(db|debug|otps)$/x) {
    $self->{$auto} = shift if (defined $_[0]);
    return $self->{$auto};
  }
  else {
    die "Could not AUTOLOAD method $auto.";
  }
}

sub _diag {
  my $self = shift;
  print STDERR @_ if $self->debug;
}

sub dec {
  fromdigits(shift, 16);
}

sub heX {
  todigitstring(shift, 16)
}

1; # End of Crypt::Unsnoopable

__END__

=head1 NAME

Crypt::Unsnoopable - Completely unsnoopable messaging

=head1 VERSION

 $Revision: 1.010 $
 $Date: Tue Oct 16 21:04:28 PDT 2018 $

=head1 SYNOPSIS

    use Crypt::Unsnoopable;

    my $a = new Crypt::Unsnoopable( DB => $dir1 );   # Alice
    my $b = new Crypt::Unsnoopable( DB => $dir2 );   # Bob

    my $pad = $a->otpgen(1024, "Bob");   # Alice generates new 1024 byte OTP

    $b->add($pad, 'Alice');              # Bob adds it to his set of OTPs

    my $encrypted = $a->encrypt('Bob', 'Setec Astronomy');

    my ($decrypted) = $b->decrypt($encrypted);

=head1 CONSTRUCTOR

=head2 new

=head2 new

Creates and returns a new Crypt::Unsnoopabe object. The following
optional named parameter can be provided:

=over

DB - The directory to store one-time pads in. Defaults to
'/tmp/.unsnoopable' if not provided.

=back

=head1 METHODS

=head2 otpgen

Generate and saves a one-time pad. Returns an OTP object. Two
arguments are required: the size of the OTP (in bytes) and its name,
in that order.

=head2 add

Adds a one-time pad to the pads DB. Returns an OTP object, or undef on
error. Two arguments are required: the pad, and its name, in that
order.

=head2 encrypt

Encrypts a message using an OTP and returns the ciphertext, or undef
on error. Two arguments are required: the pad name, and the plaintext
message, in that order.

=head2 decrypt

Decrypts a ciphertext provided as the single required argument and
returns the decrypted plaintext if successful, or undef if not.

=head1 SEE ALSO

=head2 L<http://www.unsnoopable.org>

=head2 L<http://www.noodlepi.com>

=head2 L<unsnoopable.pl>

=head1 AUTHOR

Ashish Gulhati, C<< <crypt-unsnoopable at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crypt-unsnoopable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crypt-Unsnoopable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Crypt::Unsnoopable

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-Unsnoopable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Crypt-Unsnoopable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Crypt-Unsnoopable>

=item * Search CPAN

L<http://search.cpan.org/dist/Crypt-Unsnoopable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) Ashish Gulhati.

This software package is Open Software; you can use, redistribute,
and/or modify it under the terms of the Open Artistic License 2.0.

Please see L<http://www.opensoftwr.org/oal20.txt> for the full license
terms, and ensure that the license grant applies to you before using
or modifying this software. By using or modifying this software, you
indicate your agreement with the license terms.
