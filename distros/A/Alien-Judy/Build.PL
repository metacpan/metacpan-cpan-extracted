#!perl -w
use strict;
use 5.005;
use lib qw( inc lib );

use My::Judy::Builder;
use Alien::Judy ();
use ExtUtils::Liblist;
use Config ();

my %configure_requires = (
    'perl' => '5.005',

    # Core only and unavailable on CPAN

    # Perl 5+
    'Cwd'               => 0,

    # Perl 5.1+
    'ExtUtils::Liblist' => 0,
    'File::Path'        => 0,
    'lib'               => 0,

    # Perl 5.2+
    'File::Copy'        => 0,
    'vars'              => 0,

    # Perl 5.3.7+
    # 'Config' => 0,

    # Perl 5.5+
    'File::Spec'        => 0,

    # Perl 5.6+
    'warnings'          => 0,

    # Perl 5.9.4+
    'Module::Build'     => 0,

    # CPAN
    'Sub::Exporter' => 0,
);
my %build_requires = (
    %configure_requires,

    # Perl 5.6.2+
    'Test::More'         => 0,

    # Perl 5.9.3+
    'ExtUtils::CBuilder' => 0,
);
my %requires = (
    %build_requires,
);

my $builder = My::Judy::Builder->new(
    module_name         => 'Alien::Judy',
    license             => 'perl',
    configure_requires  => \ %configure_requires,
    build_requires      => \ %build_requires,
    requires            => \ %requires,
    add_to_cleanup      => [
        'Alien-Judy-*',
        # TODO: all the generated files by src/judy-1.0.5/
    ],

    create_readme  => 1,
    dynamic_config => 1,
);

$builder->create_build_script();

my $have_judy = 1;
{
    local $SIG{__WARN__} = sub {
        my $warning = "@_";
        if ( $warning =~ /No library found for -lJudy/ ) {
            $have_judy = 0;
        }
    };

    my $lib_dirs =
        join ' ',
        map { "-L$_" }
        Alien::Judy::lib_dirs();

    ExtUtils::Liblist->ext(
        "$lib_dirs -lJudy",
        1
    );
}
$builder->notes('have_judy', $have_judy );

my $build_judy = 'y';
if ( $have_judy ) {
    $build_judy = $builder->y_n('Found -lJudy. Build Judy anyway?', 'n');
}
$builder->notes('build_judy',$build_judy);


if ( $build_judy ) {

    # Ensure this directory exists
    system "mkdir -p src/judy-1.0.5/doc/man/man3";

    print q{

---------------------------------------------------------------------
This module will build and install Judy.

It requires a C compiler and GNU make.
};

    my $make_def = find_gnu_make();
    my $make = $builder->prompt('Make program: ', $make_def );
    $builder->notes('your_make', $make);

    my $run_configure = 'y';
    if (    -e 'src/judy-1.0.4/Makefile'
         && -e 'src/judy-1.0.4/config.h'
    ) {
        $run_configure = $builder->y_n("Re-run Judy's configure? ", 'n');
    }
    else {
        $run_configure = $builder->y_n("Run Judy's configure now? ",'y');
    }

    if ( $run_configure ) {
        my $configure_args = $builder->prompt(
            'Pass any arguments to configure: ',
            $builder->_default_config_args
        );
        $builder->notes("configure_args", $configure_args);

        if( $builder->_run_judy_configure ) {
            print q{

You should now run ./Build.
};
        }
        else {
            print q{
    Something went wrong with the Judy configuration.
    You should correct it and re-run Build.PL.
};
            exit 1;
        }
    }
}

sub find_gnu_make {
    my $make_ver = `make --version`;
    my $make_ok  = $? == 0;

    my $make;
    if ( $make_ver =~ /^GNU Make/ ) {
        $make = 'make';
    }
    else {
        my $gmake_ver = `gmake --version`;
        my $gmake_ok = $? == 0;

        if ( $gmake_ver =~ /^GNU Make/ ) {
            $make = 'gmake';
        }
        elsif ( $make_ok ) {
            $make = 'make';
        }
        elsif ( $gmake_ok ) {
            $make = 'gmake';
        }
        else {
            $make = 'make';
        }
    }
    return $make;
}
