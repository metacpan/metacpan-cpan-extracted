package Convert::SSH2;

use 5.010;
use strict;
use warnings;

use Moo;
use MIME::Base64 qw(decode_base64);
use File::Slurp qw(read_file write_file);
use Carp qw(confess);
use Try::Tiny;
use Class::Load qw(load_class);
use Math::BigInt try => 'GMP';

=head1 NAME

Convert::SSH2 - Convert SSH2 RSA keys to other formats

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use 5.010;
    use Convert::SSH2;

    my $converter = Convert::SSH2->new('~/.ssh/id_rsa.pub');
    # Automatically calls parse()

    # Use default PKCS#1 format
    say $converter->format_output();

    $converter->write('/my/pub/key.pem');


=head1 PURPOSE

This library converts SSH2 style RSA public keys to other representations like PKCS#1.
This is useful if you want to use these public keys with other Perl cryptography 
libraries like L<Crypt::RSA> or L<Crypt::OpenSSL::RSA>.

=head1 ATTRIBUTES

=over

=item key

Required. Read-only.  The key material.  Attempts to be DWIMish. If this is a file path,
it will be used to load the file contents into memory.  If it's a buffer, it will use
the buffer contents.

=back

=cut

has 'key' => (
    is => 'ro',
    required => 1,
);

=over

=item format

Read-only. The output format. Current supports:

=over

=item * pkcs1

This format looks like

  -----BEGIN RSA PUBLIC KEY-----
  ...
  -----END RSA PUBLIC KEY-----

=item * pkcs8

This format looks like

  -----BEGIN PUBLIC KEY-----
  ...
  -----END PUBLIC KEY-----

=back

You can add your own format by implementing a L<Convert::SSH2::Format::Base> module.

=back

=cut

has 'format' => (
    is => 'ro',
    isa => sub {
        my $n = shift;
        confess "$n is not a supported format." unless 
            grep { $n eq $_ } qw(
                pkcs1
                pkcs8
            );
    },
    default => sub { 'pkcs1' },
);

has '_buffer' => (
    is => 'rw',
);

has '_output' => (
    is => 'rw',
    predicate => '_has_output',
);

has '_e' => (
    is => 'rw',
);

has '_n' => (
    is => 'rw',
);

=head1 METHODS 

Generally, errors are fatal.  Use L<Try::Tiny> if you want more graceful error handling.

=over

=item new()

Constructor. Takes any of the attributes as arguments.  You may optionally call new
with either a buffer or a path, and the class will assume that it is the C<key>
material.

The object automatically attempts to parse C<key> data after instantiation.

=back

=cut 

# Support single caller argument
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( @_ == 1 ) {
        unshift @_, "key";
    }

    $class->$orig(@_);
};

sub BUILD {
    my $self = shift;

    my $buf;
    unless ( $self->key =~ /\n/ ) {
        if ( -e $self->key ) {
            $buf = read_file($self->key, { binmode => ':raw' });
        }
        else {
            $buf = $self->key;
        }
    }
    else {
        $buf = $self->key;
    }

    $buf =~ s/\n//g;
    $self->_buffer( (split / /, $buf)[1] );

    $self->parse();
}

=over 

=item parse()

This method takes the Base64 encoded portion of the SSH key, decodes it, and then converts the
data inside of it into three components: the id string ('ssh-rsa'), the public exponent ('e'),
and the modulus ('n'). By default it looks for the Base64 data inside the instantiated object, 
but you can optionally pass in a Base64 string.

It uses L<Math::BigInt> to hold large integers such as 'n' or 'e'. If you don't have 
C<libgmp> installed, it will fall back to pure perl automatically, but there will be a speed 
penalty.

Returns a true value on success.

=back

=cut

sub parse {
    my $self = shift;
    my $b64 = shift || $self->_buffer;

    confess "I don't have a buffer!" unless $b64;

    my $blob = decode_base64($b64) or confess "Couldn't Base64 decode buffer"; 

    my @parts;
    my $len = length($blob);
    my $pos = 0;

    while ( $pos < $len ) {
        # There's probably a clever way to do this, but this works ok.
        my $dlen = hex( unpack "H*", substr($blob, $pos, 4) );
        $pos += 4;
        push @parts, substr($blob, $pos, $dlen);
        $pos += $dlen;
    }

    # ok $parts[0] should be a string, $parts[1] the exponent 'e', and $parts[2] the modulus 'n'

    confess "Invalid key type" unless unpack "A*", $parts[0] eq 'ssh-rsa';

    my $e;
    if ( length($parts[1]) <= 4 ) {
        $e = hex( unpack "H*", $parts[1] );
    }
    else {
        $e = Math::BigInt->new( ("0x" . unpack "H*", $parts[1]) );
    }

    my $n = Math::BigInt->new( ("0x" . unpack "H*", $parts[2]) );

    $self->_e( $e );
    $self->_n( $n );

    return 1;
}

=over

=item format_output()

Using a subclass of L<Convert::SSH2::Format::Base>, generate a representation of the SSH2 key.

Returns a formatted string.

=back

=cut

sub format_output {
    my $self = shift;
    my $format = "Convert::SSH2::Format::" . uc($self->format);

    try {
        load_class $format;
    }
    catch {
        confess "Couldn't load formatter $format: $_";
    };

    my $fmt = $format->new(
            e => $self->_e,
            n => $self->_n,
    );

    my $str = $fmt->generate();

    $self->_output( $str );

    return $str;
}

=over

=item write()

Convenience method to write a formatted key representation to a file.

Expects a pathname.  Automatically calls C<format_output()> if necessary.
If the output format has been generated already, it uses a cached version.

Returns a true value on success.

=back

=cut

sub write {
    my $self = shift;
    my $path = shift;

    confess "I don't have a path" unless $path;

    if ( -e $path ) {
        confess "$path seems to exist already?";
    }

    $self->format_output() unless $self->_has_output;

    write_file( $path, { noclobber => 1, binmode => ":raw" }, $self->_output );
}

=head1 AUTHOR

Mark Allen, C<< <mrallen1 at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-convert-ssh2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-SSH2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::SSH2

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-SSH2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-SSH2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-SSH2>

=item * MetaCPAN

L<https://metacpan.org/dist/Convert-SSH2>

=item * Git Hub

L<https://github.com/mrallen1/Convert-SSH2>

=back

=head1 SEE ALSO

L<Convert::SSH2::Format::Base>, L<Convert::SSH2::Format::PKCS1>

L<Converting OpenSSH public keys|http://blog.oddbit.com/2011/05/converting-openssh-public-keys.html>

=head1 ACKNOWLEDGEMENTS

Mark Cavage

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark Allen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Convert::SSH2
