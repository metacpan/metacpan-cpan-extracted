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
use File::Temp ();

our ( $max_keys, $max_lines, %ssh_pubkey_types );

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(&convert_pubkeys &pubkeys %ssh_pubkey_types);

our $VERSION = '0.06';

# rsa or ecdsa or ed25519 with the upper case forms presumably some
# other encoding of one of these, so set very low by default
$max_keys = 3;

# a 4096-bit RSA key is 16 lines in RFC4716, though this may need to be
# set higher if you allow long comments, or
$max_lines = 100;

@ssh_pubkey_types{qw(ecdsa ed25519 rsa PEM PKCS8 RFC4716)} = ();
# NOTE these are taken from the ssh-keygen(1) -t or -m options which
# differ from the strings present in the SSH key data
#
#   type        public key prefix
#   -----------------------------------
#   ecdsa       ecdsa-sha2-nistp256 ...
#   ed25519     ssh-ed25519 ...
#   rsa         ssh-rsa ...
#
# those responsible for the confusion between these two different bits
# of data in versions of this module prior to 0.05 have been sacked

sub convert_pubkeys {
    my ($list) = @_;
    my @pubkeys;
    for my $ref (@$list) {
        if ( $ref->[0] =~ m/^(?:PEM|PKCS8|RFC4716)$/ ) {
            # TODO perl (or CPAN module) conversion of these so don't
            # need to call out to this ssh-keygen which is not portable
            # to olden versions of ssh-keygen
            my $tmp = File::Temp->new;
            print $tmp $ref->[1];
            my $tfile = $tmp->filename;
            open my $fh, '-|', qw(ssh-keygen -i -m), $ref->[0], '-f', $tfile
              or die "could not exec ssh-keygen: $!";
            binmode $fh;
            push @pubkeys, do { local $/; readline $fh };
            close $fh or die "ssh-keygen failed with exit status $?";
        } elsif ( $ref->[0] =~ m/^(?:ecdsa|ed25519|rsa)$/ ) {
            push @pubkeys, $ref->[1];
        } else {
            croak 'unknown public key type ' . $ref->[0];
        }
    }
    chomp @pubkeys;
    return \@pubkeys;
}

sub pubkeys {
    my ($input) = @_;
    croak "input must be string, GLOB, or scalar ref" if !defined $input;
    my $fh;
    if ( ref $input eq 'GLOB' ) {
        $fh = $input;
    } else {
        open $fh, '<', $input or croak "could not open $input: $!";
        binmode $fh;
    }
    my @keys;
    while ( my $line = readline $fh ) {
        croak "too many input lines" if $. > $max_lines;
        if ( $line =~ m{^(-----BEGIN RSA PUBLIC KEY-----)} ) {
            my $key = $1;
            my ( $ok, $data ) = _until_end( $fh, '-----END RSA PUBLIC KEY-----' );
            croak "could not parse PEM pubkey: $data" unless defined $ok;
            push @keys, [ 'PEM', $key . $/ . $data ];
        } elsif ( $line =~ m{^(-----BEGIN PUBLIC KEY-----)} ) {
            my $key = $1;
            my ( $ok, $data ) = _until_end( $fh, '-----END PUBLIC KEY-----' );
            croak "could not parse PKCS8 pubkey: $data" unless defined $ok;
            push @keys, [ 'PKCS8', $key . $/ . $data ];

        } elsif ( $line =~ m{^(---- BEGIN SSH2 PUBLIC KEY ----)} ) {
            my $key = $1;
            my ( $ok, $data ) = _until_end( $fh, '---- END SSH2 PUBLIC KEY ----' );
            croak "could not parse RFC4716 pubkey: $data" unless defined $ok;
            push @keys, [ 'RFC4716', $key . $/ . $data ];
        } elsif (
            # long enough for a RSA 4096-bit key, a bit too genereous
            # for ed25519 so probably should instead be done for each
            # key type
            $line =~ m{
              (?<prefix>(?<type>ecdsa)-sha2-nistp256|ssh-(?<type>ed25519|rsa)) [\t ]+?
              (?<key>[A-Za-z0-9+/=]{64,717}) (?:[\t ]|$) }x
        ) {
            push @keys, [ $+{type}, $+{prefix} . ' ' . $+{key} ];
        }
        croak "too many keys" if @keys > $max_keys;
    }
    return \@keys;
}

# this (probably incorrectly) enforces RFC 4716 parsing on all of the
# multiline formats so may not be correct for the other two formats,
# though attempts are made at supporting them
sub _until_end {
    my ( $fh, $fin ) = @_;
    my $ok;
    my $ret = '';
    while ( my $line = readline $fh ) {
        die "too many input lines" if $. > $max_lines;
        if ( $line =~ m/^($fin)/ ) {
            $ret .= $1;
            $ok = 1;
            last;
        }

        # RFC 4716 "implementations SHOULD be prepared to read files
        # using any of the common line termination sequence[s]"
        $line =~ s/(\012|\015|\015\012)$//;

        # RFC 4716 "line[s] ... MUST NOT be longer than 72 8-bit bytes
        # excluding line termination characters" (TODO bytes vs. characters)
        return undef, "line $. too long" if length $line > 72;

        # RFC 4716 ignore "key file header" fields as this code pretends
        # that it cannot recognize any
        if ( $line =~ m/:/ ) {
            if ( $line =~ m/\\$/ ) {    # backslash continues a line
                do {
                    $line = readline $fh;
                    return undef, "continued to EOF" if eof $fh;
                    $line =~ s/(\012|\015|\015\012)$//;
                    return undef, "line $. too long" if length $line > 72;
                } until $line !~ m/\\$/;
            }
            next;
        }

        # RFC 4253 section 6.6 indicates there can be a "signature
        # format identifier"; those are KLUGE not supported by this
        # module as I don't know what that specific encoding looks like.
        # go with a sloppy Base64ish match, meanwhile, as that is what
        # OpenSSH generates as output
        if ( $line =~ m{^([A-Za-z0-9+/=]{1,72})$} ) {
            $ret .= $1 . $/;
            next;
        }

        # support RFC 822 by way of RFC 1421 PEM header extensions that
        # begin with leading whitespace (sloppy, should only happen for
        # header lines)
        next if $line =~ m{^[ \t]};

        # support RFC 1421 PEM blank line (poorly, as all blank lines
        # are ignored)
        next if $line =~ m{^$};

        return undef, "fell off end of parser at line $.";
    }
    return $ok, $ret;
}

1;
__END__

=head1 NAME

Data::SSHPubkey - utility function to parse SSH public keys with

=head1 SYNOPSIS

  use Data::SSHPubkey qw(pubkeys);

  # a Mojo app might accept public keys from clients, e.g.
  #   cat /etc/ssh/*.pub | curl ... --data-urlencode pk@- http...
  # this case is supported via a scalar reference
  my $keylist = pubkeys( \$c->param('pk') );
  for my $ref ( @$keylist ) {
      my ($type, $pubkey) = @$ref;
      ...
  }

  # a key collection host could instead wrap ssh-keyscan(1) and
  # pass in a file handle
  open( my $fh, '-|', qw(ssh-keyscan --), $host ) or die ...
  binmode $fh;
  my $keylist = pubkeys($fh);

  # a string will be treated as a file to open and read
  my $keylist = pubkeys( "/etc/ssh/ssh_host_ed25519_key.pub" );

  # if you do not care about the key types, extract only the pub
  # keys with something like
  ... = map { $_->[1] } @$keylist;

=head1 DESCRIPTION

C<Data::SSHPubkey> parses SSH public keys, or at least some of those
supported by L<ssh-keygen(1)>. It may be prudent to check any uploaded
data against C<ssh-keygen> though this module should help extract said
data from a web form upload or the like to get to that step.

Currently supported public key types (the possible values that C<$type>
above may contain):

  ecdsa ed25519 rsa
  PEM PKCS8 RFC4716

Neither SSH1 keys nor SSH2 DSA keys are supported.

The C<$pubkey> data will not include any tailing comments; those are
stripped. The C<$pubkey> data will not end with a newline; that must
be added by your software as necessary when writing out the public
keys. POSIX mandates an ultimate newline, and the shell C<read>
command is buggy by default if that ultimate newline is missing:

  $ (echo data; echo -n loss) | while read line; do echo $line; done

Inner newlines for the multiline SSH public key types (C<PEM>, C<PKCS8>,
and C<RFC4716>) will be standardized to the C<$/> variable. This may
cause problems if C<ssh-keygen(1)> or equivalent on some platform
demands a specific newline sequence that is not C<$/>.

The types C<PEM>, C<PKCS8>, and C<RFC4716> will need conversion for use
with OpenSSH; use B<convert_pubkeys> or these types could be excluded
with something like:

  my @pubkeys = grep { $_->[0] =~ m/^(?:ecdsa|ed25519|rsa)$/ }
    @{ Data::SSHPubkey::pubkeys( ... ) };

or

  ... = map { $_->[0] =~ m/^(?:ecdsa|ed25519|rsa)$/ ? $_->[1] : () }
    @{ Data::SSHPubkey::pubkeys( ... ) };

to obtain only the public key material.

=head1 SUBROUTINES

=over 4

=item B<convert_pubkeys> I<output-from-pubkeys>

This subroutine converts the output of B<pubkeys> into a list of just
the public keys, with the C<PEM>, C<PKCS8>, and C<RFC4716> types
converted into a form suitable for use with OpenSSH, using the external
tool L<ssh-keygen(1)> that is hopefully installed.

=item B<pubkeys> I<filename-or-scalarref>

A filename (scalar) will be opened and the public keys therein parsed; a
scalar reference will be treated as an in-memory file and will likewise
be opened and parsed.

This routine will B<croak> on error as, in theory, all the errors should
be due to the data passed in by the caller, or possibly the system has
run out of memory, or something.

The return format is a reference to a list of C<[ $type, $pubkey ]>
sublists.

=back

=head1 VARIABLES

C<$Data::SSHPubkey::max_keys> specifies the maximum number of keys to
parse, C<3> by default. An exception is thrown if more than C<3> keys
are seen in the input.

C<$Data::SSHPubkey::max_lines> specifies the maximum number of input
lines this module will process before throwing an exception, C<100> by
default. An attacker still might supply too much data with very long
lines; webserver or other configuration to limit that may be necessary.

The C<%Data::SSHPubkey::ssh_pubkey_types> hash contains as its keys the
SSH public key types supported by this module.

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-sshpubkey at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-SSHPubkey>. I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

Patches might best be applied towards:

L<https://github.com/thrig/Data-SSHPubkey>

=head2 Known Issues

Probably not enough guards or checks against hostile input.

Support for the C<PEM> and especially C<PKCS8> formats is a bit sloppy,
and the base64 matching is done by a regex that may accept data that is
not valid base64.

Support for various RFC 4253 formats is likely lacking (see below or
the comments in the code).

More tests are necessary for more edge cases.

If the input uses fancy encodings (where fancy is anything not ASCII)
lines longer than 72 8-bit bytes may be accepted. C<read_binary> from
L<File::Slurper> or a traditional C<binmode $fh> should avoid this case
as the key data looked for is only a subset of ASCII (header values or
comments that are ignored by this module could be UTF-8 or possibly
anything else).

B<convert_pubkeys> calls out to (modern versions of) L<ssh-keygen(1)>;
ideally this might instead be done via suitable CPAN modules.

=head1 SEE ALSO

L<ssh-keygen(1)>, L<ssh-keyscan(1)>

L<Config::OpenSSH::Authkey> - older module more aimed at management of
C<~/.ssh/authorized_keys> data and not specifically public keys. It does
have support for SSH2 DSA or SSH1 keys, though.

=over 4

=item RFC 822

Definition of white space used in various formats C<[ \t]>.

=item RFC 1421

PEM format details.

=item RFC 4253

Mentioned by RFC 4716 but it is unclear to me what the section 6.6
"Public Key Algorithms" formats exactly are.

=item RFC 4716

Secure Shell (SSH) public key file format.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
