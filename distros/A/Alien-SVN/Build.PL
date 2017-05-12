#!/usr/bin/perl -w

use strict;

use lib 'inc';
use My::SVN::Builder;

use Config;

my $build = My::SVN::Builder->new(
    module_name     => 'Alien::SVN',
    dist_author     => 'Michael G Schwern <schwern@pobox.com>',

    # perl for Alien::SVN, Apache for subversion and SVN::* modules.
    license         => 'open_source',
    
    requires        => {
        perl                    => '5.8.0',
        version                 => '0.70',
    },
    build_requires      => {
        'ExtUtils::MakeMaker'   => '6.31',   # for INSTALL_BASE
        'Module::Build'         => '0.28',
        'Test::More'            => '0.40',
    },
    configure_requires  => {
        'Module::Build'         => '0.28',
    },

    no_index => {
        directory => [qw(inc src)]
    },

    meta_merge => {
        provides => My::SVN::Builder->_svn_provides(),

        resources => {
            license     => ['http://dev.perl.org/licenses/'],
            bugtracker  => 'https://github.com/evalEmpire/Alien-SVN/issues',
            repository  => 'https://github.com/evalEmpire/Alien-SVN/',
        },
    },
    
    create_readme => 1,
);
$build->create_build_script;

print <<'END';

---------------------------------------------------------------------
This module will build Subversion and install its libraries and Perl
bindings for you.

It requires a C compiler and make.
END

my $make = $build->prompt(
    "Which make should I use to build Subversion?",
    $Config{make}
);
$build->notes('your_make', $make);

my $run_configure = 'y';
if( -e 'src/subversion/config.status' ) {
    $run_configure = $build->prompt(
        "Looks like Subversion has already been configured.\n".
        "Do you want to re-run configure?",
        "n"
    );
}
else {
    $run_configure = $build->prompt(
        "Run Subversion's configure now?", 'y'
    );
}

if( $run_configure =~ /^y/i ) {
    my $configure_args = $build->prompt(
        "\n\nWould you like to pass any arguments to configure?", 
        $build->_default_configure_args
    );

    $build->notes("configure_args", $configure_args);

    print "\n\nSubversion will now be configured.\n\n";
    sleep 1;

    if( $build->_run_svn_configure ) {
        print "\n\nYou should now run ./Build.\n";
    }
    else {
        die <<'END';
    Something went wrong with the Subversion configuration.
    Please attempt to correct it and re-run Build.PL.
END
    }
}
