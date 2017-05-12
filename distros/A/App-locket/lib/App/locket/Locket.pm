package App::locket::Locket;

use strict;
use warnings;

use Crypt::Rijndael;
use Crypt::Random qw/ makerandom_octet /;
use Digest::SHA qw/ sha256 sha256_hex /;
use MIME::Base64;
use JSON; my $JSON = JSON->new->pretty;
use File::HomeDir;
use Path::Class;
use Term::ReadKey;
use YAML::XS();
use File::Temp;
use Try::Tiny;
use String::Util qw/ trim /;

use App::locket::Store;
 
use App::locket::Moose;

has_file cfg_file => qw/ is ro required 1 /;

sub open {
    my $self = shift;
    my $file = shift;
    return $self->new( cfg_file => $file );
}

has passphrase => qw/ is rw isa Maybe[Str] /;

sub require_passphrase {
    my $self = shift;
    return 0 if ! -f $self->cfg_file;
    my $ciphercfg = $self->read_cfg;
    return $ciphercfg =~ m/^\s*\{/;
}

has cfg => qw/ is ro isa HashRef lazy_build 1 clearer clear_cfg /;
sub _build_cfg {
    my $self = shift;
    return $self->load_cfg;
}

has ciphercfg => qw/ is ro isa Str lazy_build 1 clearer clear_ciphercfg/;
sub _build_ciphercfg {
    my $self = shift;
    return $self->read_cfg;
}

has plaincfg => qw/ is ro isa Maybe[Str] lazy_build 1 clearer clear_plaincfg /;
sub _build_plaincfg {
    my $self = shift;
    my $ciphercfg = $self->read_cfg;
    if ( $self->require_passphrase ) {
        my $passphrase = $self->passphrase;
        my $plaincfg = $self->unpickle( $passphrase, $ciphercfg, plaintext => 1 );
    }
    else {
        return $ciphercfg; # Actually not a "ciphercfg"
    }
}

has plainstore => qw/ is ro isa Str lazy_build 1 clearer clear_plainstore /;
sub _build_plainstore {
    my $self = shift;
    return $self->read;
}

has store => qw/ is ro isa App::locket::Store lazy_build 1 clearer clear_store /;
sub _build_store {
    my $self = shift;
    return $self->load;
}

sub read_cfg {
    my $self = shift;
    return unless my $cfg_file = $self->cfg_file;
    return unless -f $cfg_file && -r $cfg_file;
    return scalar $cfg_file->slurp;
}

sub write_cfg {
    my $self = shift;
    my $plaincfg = shift;

    my $cfg_file = $self->cfg_file;
    $cfg_file->parent->mkpath;

    my $passphrase = $self->passphrase;
    if ( defined $passphrase ) {
        my $ciphercfg = $self->pickle( $self->generate_keylet, $passphrase, $plaincfg, json => 1 );
        $cfg_file->openw->print( $ciphercfg );
    }
    else {
        $cfg_file->openw->print( $plaincfg );
    }
}

sub load_cfg {
    my $self = shift;
    return {} unless defined ( my $plaincfg = $self->plaincfg );
    my $cfg = YAML::XS::Load( $plaincfg );

    $self->resolve_cfg_property( $cfg, qw/ read / );
    $self->resolve_cfg_property( $cfg, qw/ edit / );
    $self->resolve_cfg_property( $cfg, qw/ copy / );
    $self->resolve_cfg_property( $cfg, qw/ paste / );

    return $cfg;
}

sub resolve_cfg_property {
    my $self = shift;
    my $cfg = shift;
    my $name = shift;

    defined and length and return $_ for $cfg->{ $name };

    for my $option ( @_ ) {
        my $value;
        if      ( ref $option eq '' )       { $value = $cfg->{ $option } }
        elsif   ( ref $option eq 'CODE' )   { $value = $option->( $self, $cfg, $name ) }
        next unless defined $value and length $value;
        return $cfg->{ $name } = $value;
    }
}

sub reload_cfg {
    my $self = shift;
    $self->clear_ciphercfg;
    $self->clear_plaincfg;
    $self->clear_cfg;
    $self->cfg;
    $self->reload;
}

sub can_read {
    my $self = shift;
    local $_ = $self->cfg->{ read };
    return defined and m/\S/;
}

sub read {
    my $self = shift;

    my $reader = $self->cfg->{ read };
    $reader = '' unless defined $reader;
    $reader =~ s/^\s*[|<]//;
    my $pipe = $reader;
    CORE::open( my $cipher, '-|', $pipe );
    my $plainstore = join '', <$cipher>;
    chomp $plainstore;
    return "$plainstore\n";

    die "*** Unknown/invalid reader ($reader)";
}

sub load {
    my $self = shift;
    my $plainstore = $self->plainstore;
    my $store;
    try {
        if ( $plainstore =~ m/^\s*\{/ )
                { $store = $JSON->decode( $plainstore ) }
        else    { $store = YAML::XS::Load( $plainstore ) }
    };
    die sprintf "*** Unable to parse store (%d)", length $plainstore if !$store;
    return App::locket::Store->new( store => $store );
}

sub reload {
    my $self = shift;
    $self->clear_plainstore;
    $self->clear_store;
    $self->store;
}

# ~
# Cipher
# ~

sub random ($) {
    my $length = shift;
    return makerandom_octet Length => $length, Strength => 1;
}

sub generate_keylet {
    my $self = shift;
    return { 
        master_seed => random 32,
        transform_seed => random 32,
        transform_count => 50_000,
        iv => random 16,
    };
}

sub generate_cipher {
    my $self = shift;
    my $keylet = shift;
    my $passphrase = shift;

    my $key_cipher = Crypt::Rijndael->new( $keylet->{ master_seed }, Crypt::Rijndael::MODE_ECB );
    my $key = sha256 $passphrase;
    $key = $key_cipher->encrypt( $key ) for 1 .. $keylet->{ transform_count };
    $key = sha256 $key;
    $key = sha256 $keylet->{ transform_seed }, $key;

    my $cipher = Crypt::Rijndael->new( $key, Crypt::Rijndael::MODE_CBC() );
    $cipher->set_iv( $keylet->{ iv } );

    return $cipher;
}

sub encrypt {
    my $self = shift;
    my $keylet = shift;
    my $passphrase = shift;
    my $plaintext = shift;

    my $cipher = $self->generate_cipher( $keylet, $passphrase );

    my $base64 = encode_base64 $plaintext, '';
    $base64 .= '=' x ( 16 - length( $base64 ) % 16 );
    return $cipher->encrypt( $base64 );
}

sub decrypt {
    my $self = shift;
    my $keylet = shift;
    my $passphrase = shift;
    my $ciphertext = shift;

    my $cipher = $self->generate_cipher( $keylet, $passphrase );

    my $base64 = $cipher->decrypt( $ciphertext );
    return decode_base64 $base64;
}

sub pickle {
    my $self = shift;
    my $keylet = shift;
    my $passphrase = shift;
    my $plaintext = shift;
    my %options = @_;

    my $plaintext_digest = sha256_hex $plaintext;

    my $pickle_keylet = { %$keylet };
    $_ = unpack 'h*', $_ for @$pickle_keylet{qw/ master_seed transform_seed iv /};

    my $pickle = {
        keylet => $pickle_keylet,
        plaintext_digest => $plaintext_digest,
        ciphertext => encode_base64( $self->encrypt( $keylet, $passphrase, $plaintext ), '' ),
    };

    if ( $options{ json } ) {
        $pickle = $JSON->encode( $pickle );
    }

    return $pickle;
}

sub unpickle {
    my $self = shift;
    my $passphrase = shift;
    my $pickle = shift;
    my %options = @_;

    if ( ! ref $pickle ) {
        $pickle = $JSON->decode( $pickle );
    }
    my %pickle = %$pickle;

    my ( $keylet, $ciphertext ) = delete @pickle{qw/ keylet ciphertext /};
    $keylet = { %$keylet };
    $_ = pack 'h*', $_ for @$keylet{qw/ master_seed transform_seed iv /};
    $pickle{ keylet } = $keylet;

    $ciphertext = decode_base64 $ciphertext;

    my $plaintext = $self->decrypt( $keylet, $passphrase, $ciphertext );
    die "Digest mismatch" unless $pickle{ plaintext_digest } eq sha256_hex $plaintext;
    
    if ( $options{ plaintext } ) {
        return $plaintext;
    }

    if ( $options{ json } ) {
        return $JSON->encode( \%pickle );
    }

    return \%pickle;
}

1;
