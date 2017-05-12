package DotDirs;

# stolen/adapted from local_utils.pm in the CPAN.pm distro

use Config;
use File::Path qw(rmtree mkpath);
use File::Spec ();
use IO::File;

sub _f ($) {File::Spec->rel2abs(File::Spec->catfile(split /\//, shift));}
sub _d ($) {File::Spec->rel2abs(File::Spec->catdir(split /\//, shift));}

my $dot_cpan          = _d("t/dot-cpan$$");
my $dot_cpan_reporter = _d("t/dot-cpanreporter$$");
my $cpanlib           = _d("$dot_cpan/lib");
my $testlib           = _d("t/lib");

sub _cleanup {
    my $dir = shift;
    # suppress warnings
    local $SIG{__WARN__} = sub { 1 };
    # try more than once -- Win32 sometimes fails due to apparent timing issues
    for ( 0 .. 1 ) {
        rmtree $dir if -d $dir;
    }
}

sub prepare_cpan {
    my $class = shift;
    _cleanup $dot_cpan;
    mkpath $dot_cpan;
    my $fh = IO::File->new( "t/data/MyConfig.pm" );
    my $config = do { local $/; <$fh> };
    $config =~ s/DOT_CPAN/dot-cpan$$/;
    mkpath _d("$cpanlib/CPAN");
    $fh = IO::File->new(_f("$cpanlib/CPAN/MyConfig.pm"), "w") or die $!;
    print {$fh} $config;
    close $fh;
    $class->munge_inc($cpanlib);
    # load early
    require CPAN::MyConfig;
    $ENV{PERL5OPT} = join( q{ }, 
        "-I$cpanlib -MCPAN::MyConfig", ( defined $ENV{PERL5OPT} ? $ENV{PERL5OPT} : () )
    );
    return $dot_cpan;
}

sub prepare_cpan_reporter {
    my $class = shift;
    _cleanup $dot_cpan_reporter;
    mkpath $dot_cpan_reporter;
    my $config = IO::File->new( _f"$dot_cpan_reporter\/config.ini", ">" );
    print {$config} <DATA>;
    $config->close;
    $class->munge_inc( $testlib );
    return $dot_cpan_reporter;
}

sub munge_inc {
    my $class = shift;
    my (@dirs) = @_;
    unshift @INC, @dirs;
    $ENV{PERL5LIB} = join( $Config{path_sep}, 
        @dirs, ( defined $ENV{PERL5LIB} ? $ENV{PERL5LIB} : () )
    );
}

END { 
    _cleanup $dot_cpan unless $?;
    _cleanup $dot_cpan_reporter unless $?;
}

1;

# standard .cpanreporter/config.ini for testing
__DATA__
email_from = johndoe@example.com
command_timeout = 30
send_duplicates = yes
transport = Null
