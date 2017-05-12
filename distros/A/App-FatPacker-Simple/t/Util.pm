package t::Util;
use strict;
use warnings;
use utf8;
use Capture::Tiny qw(capture);
use Cwd 'abs_path';
use Exporter 'import';
use File::Basename 'dirname';
use File::Path 'mkpath';
use File::Spec;
use File::pushd qw(pushd tempd);

our @EXPORT = qw(run spew spew_pm slurp contains pushd tempd);

my $base = abs_path( File::Spec->catdir( dirname(__FILE__), "..") );

{
    package Result;
    sub new {
        my ($class, $out, $err, $exit) = @_;
        bless { exit => $exit, out => $out, err => $err }, $class;
    }
    sub success {
        shift->{exit} == 0;
    }
    sub out {
        my $out = shift->{out};
        wantarray ? ( split /\n/, $out ) : $out;
    }
    sub err {
        my $err = shift->{err};
        wantarray ? ( split /\n/, $err ) : $err;
    }
}

sub run {
    my @argv = @_;
    my ($out, $err, $exit) = capture {
        # your responsibility :-)
        # local $ENV{PERL5LIB};
        # local $ENV{PERL5OPT};
        system $^X, "-I$base/lib", "$base/script/fatpack-simple", @argv;
    };
    Result->new($out, $err, $exit);
}

sub spew {
    my ($content, $file) = @_;
    my $dir = dirname($file);
    mkpath $dir unless -d $dir;
    open my $fh, ">", $file or die "open $file: $!";
    print {$fh} $content;
}
sub slurp {
    my $file = shift;
    open my $fh, "<", $file or die "open $file: $!";
    local $/; <$fh>;
}

sub spew_pm {
    my ($package, $dir) = @_;
    my $pm = $package;
    $pm =~ s{::}{/}; $pm .= ".pm";
    spew "use $package; 1; # this is comment" => "$dir/$pm";
}

sub contains {
    my ($file, $package) = @_;
    my $content = slurp $file;
    my $pm = $package;
    $pm =~ s{::}{/}; $pm .= ".pm";
    index( $content, qq(\$fatpacked{"$pm"}) ) != -1;
}

1;
