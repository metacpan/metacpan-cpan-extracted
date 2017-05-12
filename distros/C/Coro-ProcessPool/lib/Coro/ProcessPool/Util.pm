package Coro::ProcessPool::Util;

use strict;
use warnings;
use Carp;
use Config;
use Const::Fast;
use Storable        qw(freeze thaw);
use MIME::Base64    qw(encode_base64 decode_base64);
use String::Escape  qw(backslash);
use Sereal::Encoder qw(sereal_encode_with_object SRL_SNAPPY);
use Sereal::Decoder qw(sereal_decode_with_object);

use base qw(Exporter);
our @EXPORT_OK = qw(
    get_command_path
    get_args
    cpu_count
    encode
    decode
    $EOL
);

const our $EOL => "\n";
const our $DEFAULT_READ_TIMEOUT => 0.1;

my $ENCODER = Sereal::Encoder->new();
my $DECODER = Sereal::Decoder->new();

sub encode {
    my ($id, $info, $data) = @_;
    $data = [] unless defined $data;

    my $package = {
        id   => $id,
        data => $data,
        info => undef,
        code => undef,
    };

    if (ref $info && ref $info eq 'CODE') {
        no warnings 'once';
        local $Storable::Deparse    = 1;
        local $Storable::forgive_me = 1;
        $package->{code} = freeze($info);
    } else {
        $package->{info} = $info;
    }

    my $pickled = sereal_encode_with_object($ENCODER, $package);
    return encode_base64($pickled, '');
}

sub decode {
    my $line = shift or croak 'decode: expected line';
    my $pickled = decode_base64($line);
    my $package = sereal_decode_with_object($DECODER, $pickled);

    my ($id, $info, $data) = @{$package}{qw(id info data)};

    if ($package->{code}) {
        no warnings 'once';
        local $Storable::Eval = 1;
        $info = thaw($package->{code});
    }

    return ($id, $info, $data);
}

sub get_command_path {
    my $perl = $Config{perlpath};
    my $ext  = $Config{_exe};
    $perl .= $ext if $^O ne 'VMS' && $perl !~ /$ext$/i;
    return $perl;
}

sub get_args {
    my @inc = map { sprintf('-I%s', backslash($_)) } @_, @INC;
    my $cmd = q|-MCoro::ProcessPool::Worker -e 'Coro::ProcessPool::Worker->new->run'|;
    return join ' ', @inc, $cmd;
}

#-------------------------------------------------------------------------------
# "Borrowed" from Test::Smoke::Util::get_ncpus.
#
# Modifications:
#   * Use $^O in place of an input argument
#   * Return number instead of string
#-------------------------------------------------------------------------------
sub cpu_count {
    # Only *nixy osses need this, so use ':'
    local $ENV{PATH} = "$ENV{PATH}:/usr/sbin:/sbin";

    my $cpus = "?";
    OS_CHECK: {
        local $_ = $^O;

        /aix/i && do {
            my @output = `lsdev -C -c processor -S Available`;
            $cpus = scalar @output;
            last OS_CHECK;
        };

        /(?:darwin|.*bsd)/i && do {
            chomp( my @output = `sysctl -n hw.ncpu` );
            $cpus = $output[0];
            last OS_CHECK;
        };

        /hp-?ux/i && do {
            my @output = grep /^processor/ => `ioscan -fnkC processor`;
            $cpus = scalar @output;
            last OS_CHECK;
        };

        /irix/i && do {
            my @output = grep /\s+processors?$/i => `hinv -c processor`;
            $cpus = (split " ", $output[0])[0];
            last OS_CHECK;
        };

        /linux/i && do {
            my @output; local *PROC;
            if ( open PROC, "< /proc/cpuinfo" ) {
                @output = grep /^processor/ => <PROC>;
                close PROC;
            }
            $cpus = @output ? scalar @output : '';
            last OS_CHECK;
        };

        /solaris|sunos|osf/i && do {
            my @output = grep /on-line/ => `psrinfo`;
            $cpus =  scalar @output;
            last OS_CHECK;
        };

        /mswin32|cygwin/i && do {
            $cpus = exists $ENV{NUMBER_OF_PROCESSORS}
                ? $ENV{NUMBER_OF_PROCESSORS} : '';
            last OS_CHECK;
        };

        /vms/i && do {
            my @output = grep /CPU \d+ is in RUN state/ => `show cpu/active`;
            $cpus = @output ? scalar @output : '';
            last OS_CHECK;
        };

        $cpus = "";
        require Carp;
        Carp::carp( "get_ncpu: unknown operationg system" );
    }

    return sprintf '%d', ($cpus || 1);
}

1;
