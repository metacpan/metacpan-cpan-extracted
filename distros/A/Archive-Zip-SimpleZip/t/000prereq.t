BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict ;
use warnings ;

use Test::More ;

BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };


    my $VERSION = '2.096';
    my @NAMES = qw(
            IO::Compress::Zip
            IO::Uncompress::Unzip
			);

    my @OPT = qw(
            IO::Compress::Lzma
            IO::Uncompress::UnLzma
            IO::Compress::Xz
            IO::Uncompress::UnXz
            IO::Compress::Zstd
            IO::Uncompress::UnZstd
			);

    plan tests => 1 + @NAMES + @OPT + $extra ;


    use_ok("Archive::Zip::SimpleZip");

    foreach my $name (@NAMES)
    {
        use_ok($name, $VERSION);
    }


    foreach my $name (@OPT)
    {
        eval " require $name " ;
        if ($@)
        {
            ok 1, "$name not available"
        }
        else
        {
            my $ver = eval("\$${name}::VERSION");
            is $ver, $VERSION, "$name version should be $VERSION"
                or diag "$name version is $ver, need $VERSION" ;
        }
    }

}

{
    # Print our versions of all modules used

    my @results = ( [ 'perl', $] ] );
    my @modules = qw(
                    Archive::Zip::SimpleZip
                    Archive::Zip::SimpleUnzip
                    IO::Compress::Base
                    IO::Compress::Zip
                    IO::Compress::Bzip2
                    IO::Compress::Lzma
                    IO::Compress::Xz
                    IO::Compress::Zstd
                    IO::Uncompress::Base
                    IO::Uncompress::Unzip
                    IO::Uncompress::Bunzip2
                    IO::Uncompress::UnLzma
                    IO::Uncompress::UnXz
                    IO::Uncompress::UnZstd
                    Compress::Raw::Zlib
                    Compress::Raw::Bzip2
                    Compress::Raw::Lzma
                    Compress::Stream::Zstd

                    );

    my %have = ();

    for my $module (@modules)
    {
        my $ver = packageVer($module) ;
        my $v = defined $ver
                    ? $ver
                    : "Not Installed" ;
        push @results, [$module, $v] ;
        $have{$module} ++
            if $ver ;
    }

    if ($have{"Compress::Raw::Zlib"})
    {
        my $ver = eval { Compress::Raw::Zlib::zlib_version() } || "unknown";
        push @results, ["zlib", $ver] ;
    }

    if ($have{"Compress::Raw::Bzip2"})
    {
        my $ver = eval{ Compress::Raw::Bzip2::bzlibversion(); } || "unknown";
        push @results, ["bzip2", $ver] ;
    }

    if ($have{"Compress::Raw::Lzma"})
    {
        my $ver = eval { Compress::Raw::Lzma::lzma_version_string(); } || "unknown";
        push @results, ["lzma", $ver] ;
    }

    if ($have{"Compress::Stream::Zstd"})
    {
        my $ver = eval { Compress::Stream::Zstd::ZSTD_VERSION_STRING; } || "unknown";
        push @results, ["Zstandard", $ver] ;
    }

    use List::Util qw(max);
    my $width = max map { length $_->[0] } @results;

    diag "\n\n" ;
    for my $m (@results)
    {
        my ($name, $ver) = @$m;

        my $b = " " x (1 + $width - length $name);

        diag $name . $b . $ver . "\n" ;
    }

    diag "\n\n" ;
}

sub packageVer
{
    no strict 'refs';
    my $package = shift;

    eval "use $package;";
    return ${ "${package}::VERSION" };

}
