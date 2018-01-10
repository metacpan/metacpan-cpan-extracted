package CommonTest;

use v5.16.3;
use Archive::Tar;
use File::chdir;
use Test::Roo::Role;
use Test::TempDir::Tiny;
use Path::Tiny;
use IPC::Cmd 0.92 qw/can_run run run_forked/;

has _openssl => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $p = can_run 'openssl';
        BAIL_OUT "openssl not found, cannot continue" unless $p;
        return path $p;
    },
);

has workdir => (
    is      => 'ro',
    clearer => 1,
    lazy    => 1,
    default => sub { path(tempdir) },
);

has hsm_token_dir => (
    is      => 'lazy',
    clearer => 1,
);

has hsm_config => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        sprintf "directories.tokendir = %s\nobjectstore.backend = file",
          $_[0]->hsm_token_dir;
    },
);

has hsm_config_file => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    default => sub {
        my $self = shift;
        my $file = $self->workdir->child('softhsm2.conf');
        $file->spew($self->hsm_config);
        return $file;
    },
);

has key => (
    is      => 'ro',
    default => '',

);

has has_softhsm2 => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $p = can_run 'softhsm2-util';
        return $p ? path $p : undef;
    },
);

has pkcs11 =>
  (is => 'rw', lazy => 1, builder => '_build_pkcs11', clearer => 1);

before setup => sub {
    my $self = shift;

    if ($ENV{TEST_DEBUG}) {
        require Log::Any::Adapter;
        Log::Any::Adapter->set('Stderr', log_level => 'debug');
    }
};

after each_test => sub {
    my $self = shift;
    $self->clear_pkcs11;
    $self->clear_hsm_token_dir;
};

sub _build_pkcs11 {
    my $self = shift;
    my $mod  = 'Crypt::PKCS11::Easy';

    require_ok $mod;

    $ENV{SOFTHSM2_CONF} = $self->hsm_config_file;

    my $obj = new_ok $mod => [module => 'libsofthsm2'];

    BAIL_OUT "Failed to initialise $mod, no point continuing" unless $obj;

    return $obj;
}

sub _new_pkcs11 {
    my $self = shift;
    my %args = @_;

    my $mod = 'Crypt::PKCS11::Easy';

    require_ok $mod;

    $ENV{SOFTHSM2_CONF} = $self->hsm_config_file;

    $args{module} = 'libsofthsm2' unless $args{module};
    $args{pin}    = '1234'        unless $args{pin};
    $args{token}  = 'test_keys_1' unless $args{token};

    my @arg_list = %args;
    my $obj = new_ok $mod => \@arg_list;

    BAIL_OUT "Failed to initialise $mod, no point continuing" unless $obj;

    return $obj;
}

sub _build_hsm_token_dir {
    my $self = shift;

    my $archive = path('t/data/tokens.tar.gz')->absolute;

    local $CWD = $self->workdir;

    diag "Extracting test tokens into $CWD";
    Archive::Tar->extract_archive($archive);

    return path('tokens')->absolute;
}

sub openssl_sign {
    my ($self, $key_file, $data_file) = @_;
    my $openssl_cmd = [$self->_openssl, 'dgst', '-sha1', '-sign', $key_file];
    my $output = run_forked $openssl_cmd,
      {verbose => $ENV{TEST_DEBUG}, child_stdin => $data_file->slurp_raw};
    chomp $output->{stdout};
    return $output->{stdout};
}

sub openssl_verify {
    my ($self, $key_file, $sig_file, $data_file) = @_;

    my $openssl_cmd = [
        $self->_openssl, 'dgst',       '-sha1',   '-verify',
        $key_file,       '-signature', $sig_file, $data_file
    ];

    return run command => $openssl_cmd, verbose => $ENV{TEST_DEBUG};
}

sub openssl_decrypt {
    my ($self, $private_key_file, $encrypted_data, $mech) = @_;

    my $openssl_cmd =
      [$self->_openssl, 'rsautl', '-decrypt', '-inkey', $private_key_file];

    if ($mech eq 'RSA_PKCS') {
        push @$openssl_cmd, '-pkcs';
    } elsif ($mech eq 'RSA_PKCS_OAEP') {
        push @$openssl_cmd, '-oaep';
    } else {
        die "Unsupported mech: $mech";
    }

    my $output = run_forked $openssl_cmd,
      {verbose => $ENV{TEST_DEBUG}, child_stdin => $encrypted_data};
    chomp $output->{stdout};

    return $output->{stdout};
}

1;
