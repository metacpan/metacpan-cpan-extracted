package Alien::ghostty::Zig;
use strict;
use warnings;
use Config ();
use Digest::SHA ();
use File::Path ();
use File::Spec;

our $VERSION = '0.01';

our $ZIG_VERSION = '0.16.0';

my %ZIG_SHA256 = (
    'x86_64-linux'    => '70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00',
    'aarch64-linux'   => 'ea4b09bfb22ec6f6c6ceac57ab63efb6b46e17ab08d21f69f3a48b38e1534f17',
    'x86_64-macos'    => '0387557ed1877bc6a2e1802c8391953baddba76081876301c522f52977b52ba7',
    'aarch64-macos'   => 'b23d70deaa879b5c2d486ed3316f7eaa53e84acf6fc9cc747de152450d401489',
    'x86_64-freebsd'  => '390379bfaf6b89b001c6bb4035b8fcbc5c12193fd9fd5048c3a0fe39e5d1cf72',
    'aarch64-freebsd' => '0a441f50696a34cfb9f9a0b3c510fd49a56b18b364e03c26525cb7999959c969',
    'x86_64-netbsd'   => 'e235ca96f63034a009aca831c69394a1c14498a8e06ff5f358fc3fb4bed73dfb',
    'aarch64-netbsd'  => '4767425d72c779275ebbc5a6319f5a3c5d109664d3d8c880125d550e87d9d46a',
    'x86_64-openbsd'  => '25b72946e8b2dde5c93bc03cbebeb17e4d90eea8040acce8bb78cefdeee97337',
    'aarch64-openbsd' => 'f3c868ccc1bc30e2d2b68128186b2153d86c3efc41190f4170a43024a3cd7809',
);

my %OS = (
    linux   => 'linux',
    darwin  => 'macos',
    freebsd => 'freebsd',
    netbsd  => 'netbsd',
    openbsd => 'openbsd',
);

sub platform {
    my $os = $OS{$^O} or return;
    return unless $Config::Config{ptrsize} == 8;
    for my $flag ('-m', '-p') {
        my $arch = `uname $flag 2>/dev/null`;
        next unless defined $arch;
        chomp $arch;
        return "x86_64-$os"  if $arch =~ /^(?:x86_64|amd64)$/i;
        return "aarch64-$os" if $arch =~ /^(?:aarch64|arm64)$/i;
    }
    return;
}

sub version_of {
    my ($bin) = @_;
    return unless defined $bin && length $bin && -f $bin && -x _;
    open my $fh, '-|', $bin, 'version' or return;
    my $out = <$fh>;
    close $fh;
    return unless defined $out;
    $out =~ s/\s+\z//;
    return $out;
}

sub is_usable {
    my ($version) = @_;
    my ($series) = $ZIG_VERSION =~ /^(\d+\.\d+)\./;
    return defined $version && $version =~ /^\Q$series\E\.\d+$/;
}

sub find {
    my (%args) = @_;
    my $log = $args{log} || sub {};

    my $bin = $ENV{ALIEN_GHOSTTY_ZIG};
    if (defined $bin && length $bin) {
        my $v = version_of($bin);
        die "Alien::ghostty: ALIEN_GHOSTTY_ZIG=$bin is not zig $ZIG_VERSION-compatible"
          . (defined $v ? " (reports $v)" : ' (not executable)') . "\n"
            unless is_usable($v);
        $log->("using zig $v from ALIEN_GHOSTTY_ZIG: $bin");
        return $bin;
    }

    for my $dir (File::Spec->path) {
        $bin = File::Spec->catfile($dir, 'zig');
        my $v = version_of($bin);
        next unless defined $v;
        if (is_usable($v)) {
            $log->("using zig $v from PATH: $bin");
            return $bin;
        }
        $log->("ignoring zig $v at $bin (need $ZIG_VERSION-compatible)");
    }
    return;
}

sub find_or_fetch {
    my (%args) = @_;
    $args{log} ||= sub { print STDERR "@_\n" };
    return find(%args) || fetch(%args);
}

sub fetch {
    my (%args) = @_;
    my ($dir, $log) = @args{qw(dir log)};
    die "Alien::ghostty: zig $ZIG_VERSION is needed and network fetch is disabled; "
      . "install zig and put it on PATH or set ALIEN_GHOSTTY_ZIG\n"
        if exists $args{network} && !$args{network};
    my $plat = platform()
        or die "Alien::ghostty: no prebuilt zig $ZIG_VERSION for $^O/$Config::Config{archname}; "
             . "install zig $ZIG_VERSION and put it on PATH or set ALIEN_GHOSTTY_ZIG\n";
    my $sha256 = $ZIG_SHA256{$plat};

    my $name = "zig-$plat-$ZIG_VERSION";
    my $url  = "https://ziglang.org/download/$ZIG_VERSION/$name.tar.xz";
    File::Path::make_path($dir);
    my $archive = File::Spec->catfile($dir, "$name.tar.xz");
    my $bin     = File::Spec->catfile($dir, $name, 'zig');

    if (is_usable(version_of($bin))) {
        $log->("using previously fetched zig: $bin");
        return $bin;
    }

    require HTTP::Tiny;
    my $http = HTTP::Tiny->new(verify_SSL => 1);
    if ($http->can('can_ssl')) {
        my ($ok, $why) = $http->can_ssl;
        die "Alien::ghostty: cannot fetch $url: $why\n" unless $ok;
    }

    $log->("fetching $url");
    my $res = $http->mirror($url, $archive);
    unless ($res->{success}) {
        my $why = $res->{status} == 599 ? $res->{content} : "$res->{status} $res->{reason}";
        die "Alien::ghostty: fetching $url failed: $why\n";
    }

    my $got = Digest::SHA->new(256)->addfile($archive, 'b')->hexdigest;
    if ($got ne $sha256) {
        unlink $archive;
        die "Alien::ghostty: $name.tar.xz checksum mismatch: expected $sha256, got $got\n";
    }

    $log->("extracting $archive");
    my ($qa, $qd) = map { (my $s = $_) =~ s/'/'\\''/g; "'$s'" } $archive, $dir;
    system('tar', '-xJf', $archive, '-C', $dir) == 0
        or system("xz -dc $qa | tar -xf - -C $qd") == 0
        or die "Alien::ghostty: cannot extract $archive (needs tar with xz support)\n";
    unlink $archive;

    my $v = version_of($bin);
    die "Alien::ghostty: extracted zig at $bin does not run\n" unless is_usable($v);
    $log->("using fetched zig $v: $bin");
    return $bin;
}

1;
