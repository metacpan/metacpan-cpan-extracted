package Crypt::PBE::CLI;

use strict;
use warnings;
use utf8;

use Term::ReadKey;
use MIME::Base64;
use Getopt::Long qw( GetOptionsFromArray :config gnu_compat );
use Pod::Usage;
use Carp;

use Crypt::PBE::PBES1;
use Crypt::PBE::PBES2;

our $VERSION = '0.103';

my @cli_options = qw(
    help|h
    man
    version
    verbose|v
    null|0

    input=s
    password=s
    count=i
    hash=s
    hmac=s
    encryption=s
    digest=s

    scheme=s
    algorithm=s

    base64
    hex
    format=s

    encrypt
    decrypt
    list-algorithms
);

my $pbe_mapping = {
    'PBEWithMD2AndDES'  => { scheme => 'pbes1', hash => 'md2',  encryption => 'des' },
    'PBEWithMD5AndDES'  => { scheme => 'pbes1', hash => 'md5',  encryption => 'des' },
    'PBEWithSHA1AndDES' => { scheme => 'pbes1', hash => 'sha1', encryption => 'des' },

    'PBEWithHmacSHA1AndAES_128'   => { scheme => 'pbes2', hmac => 'hmac-sha1',   encryption => 'aes-128' },
    'PBEWithHmacSHA1AndAES_192'   => { scheme => 'pbes2', hmac => 'hmac-sha1',   encryption => 'aes-192' },
    'PBEWithHmacSHA1AndAES_256'   => { scheme => 'pbes2', hmac => 'hmac-sha1',   encryption => 'aes-256' },
    'PBEWithHmacSHA224AndAES_128' => { scheme => 'pbes2', hmac => 'hmac-sha224', encryption => 'aes-128' },
    'PBEWithHmacSHA224AndAES_192' => { scheme => 'pbes2', hmac => 'hmac-sha224', encryption => 'aes-192' },
    'PBEWithHmacSHA224AndAES_256' => { scheme => 'pbes2', hmac => 'hmac-sha224', encryption => 'aes-256' },
    'PBEWithHmacSHA256AndAES_128' => { scheme => 'pbes2', hmac => 'hmac-sha256', encryption => 'aes-128' },
    'PBEWithHmacSHA256AndAES_192' => { scheme => 'pbes2', hmac => 'hmac-sha256', encryption => 'aes-192' },
    'PBEWithHmacSHA256AndAES_256' => { scheme => 'pbes2', hmac => 'hmac-sha256', encryption => 'aes-256' },
    'PBEWithHmacSHA384AndAES_128' => { scheme => 'pbes2', hmac => 'hmac-sha384', encryption => 'aes-128' },
    'PBEWithHmacSHA384AndAES_192' => { scheme => 'pbes2', hmac => 'hmac-sha384', encryption => 'aes-192' },
    'PBEWithHmacSHA384AndAES_256' => { scheme => 'pbes2', hmac => 'hmac-sha384', encryption => 'aes-256' },
    'PBEWithHmacSHA512AndAES_128' => { scheme => 'pbes2', hmac => 'hmac-sha512', encryption => 'aes-128' },
    'PBEWithHmacSHA512AndAES_192' => { scheme => 'pbes2', hmac => 'hmac-sha512', encryption => 'aes-192' },
    'PBEWithHmacSHA512AndAES_256' => { scheme => 'pbes2', hmac => 'hmac-sha512', encryption => 'aes-256' },
};

sub cli_error {
    my ($error) = @_;
    $error =~ s/ at .* line \d+.*//;
    print "ERROR: $error\n";
    exit 255;
}

sub cli_readkey {

    my ($message) = @_;

    my $value = undef;

    print $message;
    ReadMode 'noecho';

    $value = ReadLine 0;
    chomp $value;

    ReadMode 'normal';
    print "\n";

    return $value;

}

sub show_version {

    require Crypt::PBE;
    require Crypt::CBC;
    require Crypt::DES;
    require Crypt::OpenSSL::AES;

    print <<"EOF";
pkcs5-tool v$VERSION

CORE
  Perl                 ($^V, $^O)
  Crypt::PBE           ($Crypt::PBE::VERSION)

CRYPT MODULES
  Crypt::CBC           ($Crypt::CBC::VERSION)
  Crypt::DES           ($Crypt::DES::VERSION)
  Crypt::OpenSSL::AES  ($Crypt::OpenSSL::AES::VERSION)

DIGEST MODULES
  Digest::MD2          ($Digest::MD2::VERSION)
  Digest::MD5          ($Digest::MD5::VERSION)
  Digest::SHA          ($Digest::SHA::VERSION)

EOF

    return 0;

}

sub file_read {
    my ($filename) = @_;

    open( my $fh, '<', $filename ) or die "Can't open file: $!";

    my $content = do { local $/; <$fh> };
    chomp($content);

    close $fh;

    return $content;
}

sub parse_value {

    my ($value) = @_;

    return if ( !$value );

    if ( $value =~ /^(file|env)\:(.*)/ ) {

        my $type = $1;
        my $name = $2;

        if ( $type eq 'file' ) {
            return cli_error('File not found') if ( !-f $name );
            return file_read($name);
        }

        if ( $type eq 'env' ) {
            return cli_error('Environment variable not found') if ( !defined $ENV{$name} );
            return $ENV{$name};
        }

    }

    return $value;

}

sub run {

    my ( $class, $arguments ) = @_;

    my $options = {};

    GetOptionsFromArray( $arguments, $options, @cli_options ) or pod2usage( -verbose => 0 );

    $options->{count}  ||= 1_000;
    $options->{format} ||= 'base64';

    if ( $options->{base64} ) {
        $options->{format} = 'base64';
    }

    if ( $options->{hex} ) {
        $options->{format} = 'hex';
    }

    if ($options->{format} ne 'base64' && $options->{format} ne 'hex') {
        return cli_error('Invalid format');
    }

    # Detect input from STDIN
    if ( -p STDIN || -f STDIN ) {
        $options->{input} = do { local $/; <STDIN> };
    }

    pod2usage( -exitstatus => 0, -verbose => 2 ) if ( $options->{man} );
    pod2usage( -exitstatus => 0, -verbose => 0 ) if ( $options->{help} );

    return show_version if ( $options->{version} );

    if ( $options->{'list-algorithms'} ) {
        print join( "\n", sort keys %{$pbe_mapping} ) . "\n";
        return 0;
    }

    pod2usage( -exitstatus => 1, -verbose => 0 ) if ( !$options->{algorithm} );
    pod2usage( -exitstatus => 1, -verbose => 0 ) if ( !$options->{input} );

    my $pbe_params = $pbe_mapping->{ $options->{algorithm} };

    if ( !$pbe_params ) {
        return cli_error 'Invalid algorithm';
    }

    if (! $options->{encrypt} && ! $options->{decrypt}) {
        return cli_error 'Specify --encrypt or --decrypt';
    }

    # Read password and input data from file or env variable
    $options->{password} = parse_value( $options->{password} );
    $options->{input}    = parse_value( $options->{input} );

    if ( !$options->{password} ) {

        my $input_password = cli_readkey('Password: ');

        if ( $options->{encrypt} ) {
            my $test_password = cli_readkey('Re-type password: ');

            if ( $input_password ne $test_password ) {
                return cli_error 'Password mismatch';
            }
        }

        $options->{password} = $input_password;

    }

    my $pbes = undef;

    if ( $pbe_params->{scheme} eq 'pbes1' ) {

        if ( $options->{verbose} ) {
            printf STDERR "[PBES1] Scheme: %s\n",     $pbe_params->{scheme};
            printf STDERR "[PBES1] Hash: %s\n",       $pbe_params->{hash};
            printf STDERR "[PBES1] Encryption: %s\n", $pbe_params->{encryption};
            printf STDERR "[PBES1] Count: %s\n",      $options->{count};
        }

        $pbes = Crypt::PBE::PBES1->new(
            password   => $options->{password},
            count      => $options->{count},
            hash       => $pbe_params->{hash},
            encryption => $pbe_params->{encryption},
        );

    }

    if ( $pbe_params->{scheme} eq 'pbes2' ) {

        if ( $options->{verbose} ) {
            printf STDERR "[PBES2] Scheme: %s\n",     $pbe_params->{scheme};
            printf STDERR "[PBES2] HMAC: %s\n",       $pbe_params->{hmac};
            printf STDERR "[PBES2] Encryption: %s\n", $pbe_params->{encryption};
            printf STDERR "[PBES2] Count: %s\n",      $options->{count};
        }

        $pbes = Crypt::PBE::PBES2->new(
            password   => $options->{password},
            count      => $options->{count},
            hmac       => $pbe_params->{hmac},
            encryption => $pbe_params->{encryption},
        );

    }

    my $output = '';

    if ( $options->{encrypt} ) {

        if ( $options->{format} eq 'hex' ) {
            $output = join '', unpack 'H*', $pbes->encrypt( $options->{input} );
        }

        if ( $options->{format} eq 'base64' ) {
            $output = encode_base64( $pbes->encrypt( $options->{input} ), '' );
        }

    }

    if ( $options->{decrypt} ) {

        if ( $options->{format} eq 'hex' ) {
            $output = $pbes->decrypt( pack 'H*', $options->{input} );
        }

        if ( $options->{format} eq 'base64' ) {
            $output = $pbes->decrypt( decode_base64 $options->{input} );
        }

    }

    print $output . ( $options->{null} ? "\0" : "\n" );

    return 0;

}

1;

=encoding utf-8

=head1 NAME

Crypt::PBE::CLI - PKCS#5 Password-Based Encryption Command Line Interface

=head1 SYNOPSIS

    use Crypt::PBE::CLI qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

PKCS#5 Password-Based Encryption Command Line Interface module for C<pkcs5-tool(1)>.

=head1 AUTHOR

L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2020-2023 L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

You may use and distribute this module according to the same terms
that Perl is distributed under.
