use strict;
use warnings;
use Module::Build;
use Carp;

requires_external_bin('bash');

my $build = Module::Build->new(
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl => '5.008005',
        'Getopt::Long'                      => '0',
        'Pod::Usage'                        => '0',
        'File::Temp'                        => '0',
        'File::Copy'                        => '0',
        'IO::Socket::INET'                  => '0',
        'POSIX'                             => '0',
        'Proclet'                           => '0.23',
        'JSON'                              => '2.53',
        'Log::Minimal'                      => '0.14',
        'Module::Load'                      => '0.24',
        'Class::Accessor::Lite'             => '0.05',
        'LWP::UserAgent'                    => '6.02',
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'App-derived',
    module_name => 'App::derived',

    script_files => ['bin/derived'],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();

# Module::Install::Can

sub can_run {
    my $cmd = shift;
    require ExtUtils::MakeMaker;
    if ( $^O eq 'cygwin' ) {
        
        # MM->maybe_command is fixed in 6.51_01 for Cygwin.
        ExtUtils::MakeMaker->import(6.52);
    }
    
    my $_cmd = $cmd;
    return $_cmd if ( -x $_cmd or $_cmd = MM->maybe_command($_cmd) );
    
    for my $dir ( ( split /$Config::Config{path_sep}/x, $ENV{PATH} ), q{.} )
        {
            next if $dir eq q{};
            my $abs = File::Spec->catfile( $dir, $cmd );
            return $abs if ( -x $abs or $abs = MM->maybe_command($abs) );
        }
    
    return;
} ## end sub can_run

# Module::Install::External

sub requires_external_bin {
    my ( $bin, $version ) = @_;
    if ($version) {
        croak 'requires_external_bin does not support versions yet';
        
    }

    # Locate the bin
    print "Locating required external dependency bin: $bin...";
    my $found_bin = can_run($bin);
    if ($found_bin) {
        print " found at $found_bin.\n";
    } else {
        print " missing.\n";
        print "Unresolvable missing external dependency.\n";
        print "Please install '$bin' seperately and try again.\n";
        print {*STDERR}
            "NA: Unable to build distribution on this platform.\n";
        exit 0;
    }
    
    return 1;
} ## end sub requires_external_bin
