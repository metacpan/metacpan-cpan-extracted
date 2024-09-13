package    # hide from PAUSE
    DBIx::Squirrel::Utils;

use 5.010_001;
use strict;
use warnings;
use Carp                          ();
use Compress::Bzip2               qw/memBunzip memBzip/;
use DBIx::Squirrel::Crypt::Fernet qw/fernet_decrypt fernet_encrypt/;
use Devel::GlobalDestruction      ();
use Dotenv                        ();
use Encode                        ();
use JSON::Syck                    ();
use Scalar::Util;
use Sub::Name;

BEGIN {
    require Exporter;
    @DBIx::Squirrel::Utils::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Utils::EXPORT_OK = (
        qw/
            args_partition
            global_destruct_phase
            result
            slurp
            statement_digest
            statement_normalise
            statement_study
            statement_trim
            throw
            whine
            /
    );
    %DBIx::Squirrel::Utils::EXPORT_TAGS
        = (all => [@DBIx::Squirrel::Utils::EXPORT_OK]);
    Dotenv->load() if -e '.env';
}

sub args_partition {
    my $s = @_;
    return [] unless $s;
    my $n = $s;
    while ($n) {
        last unless UNIVERSAL::isa($_[$n - 1], 'CODE');
        $n -= 1;
    }
    return [@_] if $n == 0;
    return [], @_ if $n == $s;
    return [@_[$n .. $#_]], @_[0 .. $n - 1];
}

sub global_destruct_phase {
    # Perl versions older than 5.14 do not support ${^GLOBAL_PHASE}, so provide
    # a shim that works around that wrinkle.
    return Devel::GlobalDestruction::in_global_destruction();
}

sub throw {
    Carp::confess do {
        if (@_) {
            my($f, @a) = @_;
            @a ? sprintf($f, @a) : $f || $@ || 'Unknown exception thrown';
        }
        else {
            $@ || 'Unknown exception thrown';
        }
    };
}

sub whine {
    Carp::cluck do {
        if (@_) {
            my($f, @a) = @_;
            @a ? sprintf($f, @a) : $f || 'Unhelpful warning issued';
        }
        else {
            'Unhelpful warning issued';
        }
    };
}

sub slurp {
    my $filename = shift;
    my %options  = @_;
    my $bytes;
    open my $fh, '<:raw', $filename or throw "$! - $filename";
    read $fh, $bytes, -s $filename;
    close $fh;
    if ($filename =~ /\.encrypted/) {
        $bytes = do {
            if (!exists($options{key})) {
                fernet_decrypt($ENV{FERNET_KEY}, $bytes);
            }
            else {
                fernet_decrypt($options{key}, $bytes);
            }
        };
    }
    if ($filename =~ /\.bz2/) {
        $bytes = memBunzip($bytes);
    }
    if ($filename =~ /\.json/) {
        local $JSON::Syck::ImplicitUnicode = !!1;
        return do { $_ = JSON::Syck::Load($bytes) };
    }
    if (!exists($options{decode_utf8}) || !!$options{decode_utf8}) {
        return do { $_ = Encode::decode_utf8($bytes) };
    }
    return do { $_ = $bytes };
}

1;
