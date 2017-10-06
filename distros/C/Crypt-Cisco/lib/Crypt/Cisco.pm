package Crypt::Cisco;

##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

use Exporter;
our %EXPORT_TAGS = ( 'subs' => [qw( cisco_encrypt cisco_decrypt )], );
our @EXPORT_OK = ( @{$EXPORT_TAGS{'subs'}} );

our @ISA = qw(Exporter);

# Cisco's XOR key
my @xlat = (
    0x64, 0x73, 0x66, 0x64, 0x3B, 0x6B, 0x66, 0x6F, 0x41, 0x2C, 0x2E, 0x69,
    0x79, 0x65, 0x77, 0x72, 0x6B, 0x6C, 0x64, 0x4A, 0x4B, 0x44, 0x48, 0x53,
    0x55, 0x42, 0x73, 0x67, 0x76, 0x63, 0x61, 0x36, 0x39, 0x38, 0x33, 0x34,
    0x6E, 0x63, 0x78, 0x76, 0x39, 0x38, 0x37, 0x33, 0x32, 0x35, 0x34, 0x6B,
    0x3B, 0x66, 0x67, 0x38, 0x37
);

my $warn = sprintf
    "\n" .
    "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" .
    "'password_*' subs are deprecated.\n" .
    "They will be removed from a future release." .
    "Instead, use 'cisco_*'\n" .
    "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" .
    "\n";

##################################################
# Start Public Module
##################################################

sub password_decrypt {
    warn($warn);
    return cisco_decrypt(@_);
}

sub cisco_decrypt {
    my $self = shift;

    my $passwd;

    # Call as sub
    if ( $self =~ /^Crypt::Cisco/ ) {
        ($passwd) = @_;
    } else {
        $passwd = $self;
    }

    if ( ( $passwd =~ /^[\da-f]+$/i ) and ( length($passwd) > 2 ) ) {
        if ( !( length($passwd) & 1 ) ) {
            my $dec = "";
            my ( $s, $e ) = ( $passwd =~ /^(..)(.+)/o );

            for ( my $i = 0; $i < length($e); $i += 2 ) {

                # If we move past the end of the XOR key, reset
                if ( $s > $#xlat ) { $s = 0 }
                $dec .= sprintf "%c",
                  hex( substr( $e, $i, 2 ) ) ^ $xlat[$s++];
            }
            return $dec;
        }
    }
    carp("Invalid password `$passwd'");
    return "";
}

sub password_encrypt {
    warn($warn);
    return cisco_decrypt(@_);
}

sub cisco_encrypt {
    my $self = shift;

    my ( $cleartxt, $index );

    # Call as sub
    if ( $self =~ /^Crypt::Cisco/ ) {
        ( $cleartxt, $index ) = @_;
    } else {
        $cleartxt = $self;
        ($index) = @_;
    }

    my $start = 0;
    my $end   = $#xlat;

    if ( defined $index ) {
        if ( $index =~ /^\d+$/ ) {
            if ( ( $index < 0 ) or ( $index > $end ) ) {
                carp("Index out of range 0-$#xlat: $index");
                return "";
            } else {
                $start = $end = $index;
            }
        }
    } else {
        $start = $end = int( rand( $#xlat + 1 ) );
    }

    my @passwds;
    for ( my $j = $start; $j <= $end; $j++ ) {
        my $encrypt = sprintf "%02i", $j;
        my $s = $j;

        for ( my $i = 0; $i < length($cleartxt); $i++ ) {

            # If we move past the end of the XOR key, reset
            if ( $s > $#xlat ) { $s = 0 }
            $encrypt .= sprintf "%02X",
              ord( substr( $cleartxt, $i, 1 ) ) ^ $xlat[$s++];
        }
        push @passwds, $encrypt;
    }

    my $ret = \@passwds;
    if ( $#passwds == 0 ) {
        $ret = $passwds[0];
    }

    if ( wantarray ) {
        return @passwds;
    } else {
        return $ret;
    }
}

##################################################
# End Public Module
##################################################

1;

__END__

##################################################
# Start POD
##################################################

=head1 NAME

Crypt::Cisco - Commands for Cisco Type 7 Passwords

=head1 SYNOPSIS

  use Crypt::Cisco;
  my $clear = cisco_decrypt('121A0C041104');
  my $crypt = cisco_encrypt('cisco');

=head1 DESCRIPTION

The following subs implement the type-7 password encryption / decryption.  
The algorithm is freely available on the Internet on several sites; thus, 
I can/will B<NOT> take credit or B<ANY> liability for its use.

=head1 FUNCTIONS

B<NOTE:> The legacy functions are deprecated and will be removed from a 
future release:

=over 4

=item B<password_decrypt>

=item B<password_encrypt>

=back

Use the following instead:

=head2 cisco_decrypt() - decrypt a Cisco type 7 password

  my $passwd = cisco_decrypt('00071A150754');

Where C<00071A150754> is the encrypted Cisco password in this example.

=head2 cisco_encrypt() - encrypt a Cisco type 7 password

  my $passwd = cisco_encrypt('cleartext'[,# | *]);
  print "$_\n" for (@{$passwd});

Where C<cleartext> is the clear text string to encrypt.  The second
optional argument is a number in the range of 0 - 52 inclusive or
random text.

Returns an array of all possible encryptions if random text is the 
second argument.

  Option  Description            Action
  ------  -----------            -------
          No argument provided   Return a random encryption.
  #       Number 0-52 inclusive  Return password encrypted with # index.
  (other) Random text            Return all 53 possibilities in array.

B<NOTE:>  Cisco routers by default only seem to use the first 16 indexes
(0 - 15) to encrypt passwords.  You notice this by looking at the first
two characters of any type 7 encrypted password in a Cisco router
configuration.  However, testing on IOS 12.x and later shows that manually
entering a password encrypted with a higher index (generated from this
script) to a Cisco configuration will not only be allowed, but will
function normally for authentication.  This may be a form of "security
through obscurity" given that some older Cisco password decrypters don't
use the entire translation index and limit 'valid' passwords to those
starting with the fist 16 indexes (0 - 15).  Using passwords with an
encryption index of 16 - 52 inclusive I<may> render older Cisco password
decrypters useless.

Additionally, the Cisco router command prompt seems to be limited to 254
characters, making the largest password 250 characters (254 - 4
characters for the C<pas > (followed by space) command to enter the
password).

=head1 EXPORTS

Load them: use Crypt::Cisco qw(:subs);

=over 4

=item B<cisco_decrypt>

=item B<cisco_encrypt>

=back

=head1 EXAMPLES

This distribution comes with a script (installed to the default
C<bin> install directory) that not only demonstrates example uses but also
provides functional execution.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010, 2017

L<http://www.VinsWorld.com>

All rights reserved

=cut
