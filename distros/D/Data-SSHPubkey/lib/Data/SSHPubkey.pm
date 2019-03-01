# -*- Perl -*-
#
# utility function to parse SSH public keys with
#
# run perldoc(1) on this file for documentation

package Data::SSHPubkey;

use 5.010;
use strict;
use warnings;

use Carp qw(croak);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(&pubkeys);

our $VERSION = '0.01';

sub pubkeys {
    my ($input) = @_;
    my $fh;
    open $fh, '<', $input or croak "could not open $input: $!";
    my @keys;
    while ( my $line = readline $fh ) {
        if ( $line =~ m{^(-----BEGIN RSA PUBLIC KEY-----)} ) {
            my $key = $1;
            my ( $ok, $data ) = _until_end( $fh, '-----END RSA PUBLIC KEY-----' );
            croak "could not parse PEM pubkey" unless $ok;
            push @keys, [ 'PEM', $key . $/ . $data ];
        } elsif ( $line =~ m{^(-----BEGIN PUBLIC KEY-----)} ) {
            my $key = $1;
            my ( $ok, $data ) = _until_end( $fh, '-----END PUBLIC KEY-----' );
            croak "could not parse PKCS8 pubkey" unless $ok;
            push @keys, [ 'PKCS8', $key . $/ . $data ];

        } elsif ( $line =~ m{^(---- BEGIN SSH2 PUBLIC KEY ----)} ) {
            my $key = $1;
            my ( $ok, $data ) = _until_end( $fh, '---- END SSH2 PUBLIC KEY ----' );
            croak "could not parse RFC4716 pubkey" unless $ok;
            push @keys, [ 'RFC4716', $key . $/ . $data ];
        } elsif (
            # long enough for a RSA 4096-bit key, a bit too genereous
            # for ed25519 so probably should instead be done for each
            # key type
            $line =~ m{
              (ecdsa-sha2-nistp256|ssh-ed25519|ssh-rsa) [\t ]+?
              ([A-Za-z0-9+/=]{64,717}) (?:[\t ]|$) }x
        ) {
            push @keys, [ $1, "$1 $2" ];
        }
    }
    return \@keys;
}

# KLUGE this will very likely need changes depending on what clients in
# the while send in with this format, as I really only deal with OpenSSH
# type keys and not this form (e.g. skip Comment: or such fields?)
sub _until_end {
    my ( $fh, $fin ) = @_;
    my $ok;
    my $ret = '';
    while ( my $line = readline $fh ) {
        if ( $line =~ m/^($fin)/ ) {
            $ret .= $1;
            $ok = 1;
            last;
        }
        if ( $line =~ m/^(.{1,80})$/ ) {    # TODO tighten this up...
            $ret .= $1 . $/;
        }
    }
    return $ok, $ret;
}

1;
__END__

=head1 NAME

Data::SSHPubkey - utility function to parse SSH public keys with

=head1 SYNOPSIS

  use Data::SSHPubkey;

  my $keylist = Data::SSHPubkey::pubkeys( $file_or_scalarref );
  for my $ref ( @$keylist ) {
      my ($type, $pubkey) = @$ref;
      ...
  }

=head1 DESCRIPTION

C<Data::SSHPubkey> parses SSH public keys, or at least some of those
supported by C<ssh-keygen(1)>. It may be prudent to check any uploaded
data with C<ssh-keygen> though this module should help extract that from
web form upload data or the like to get to that step.

Currently supported public key types:

  ecdsa ed25519 rsa
  PEM PKCS8 RFC4716

Neither SSH1 keys nor SSH2 DSA keys are supported.

=head1 SUBROUTINE

=over 4

=item B<pubkeys> I<filename-or-scalarref>

A filename (scalar) will be opened and the public keys therein parsed; a
scalar reference will be treated as an in-memory file and will likewise
be opened and parsed.

This routine will B<croak> on error as, in theory, all the errors should
be due to the data passed in by the caller, or possibly the system has
run out of memory, or something.

The return format is a reference to a list of C<[ $type, $pubkey ]>
lists.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-sshpubkey at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SSHPubkey>. I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

Patches might best be applied towards:

L<https://github.com/thrig/Data-SSHPubkey>

=head2 Known Issues

Probably not enough guards or checks against hostile input (too much
data, etc).

Support for the

  PEM PKCS8 RFC4716

key types is pretty weak and needs improvement.

=head1 SEE ALSO

L<Config::OpenSSH::Authkey> - older module more aimed at management of
C<~/.ssh/authorized_keys> data and not specifically public keys. It does
have support for SSH2 DSA or SSH1 keys, though.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
