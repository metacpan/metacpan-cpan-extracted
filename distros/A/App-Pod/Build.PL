#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
use File::Spec::Functions qw( catfile );
Module::Build->VERSION( '0.4004' );

my $class = Module::Build->subclass(
    code => q{
        use Perl::OSType    qw(os_type);
      # use File::HomeDir   qw( home );  # Not sure how to say this also is required.
        sub _clear_cache {
            my $home = $ENV{HOME} // $ENV{USERPROFILE} // $ENV{LOGDIR};
            for ( glob qq("$home/.cache/my_pod*.cache") ) {
                print "Removing: $_\n";
                unlink or warn $!;
            }
        }
        sub _check_for_source_command {
            my $file = "bash_completion_pod";
            my $path = qx(which $file);
            chomp $path;
            if ( not $ENV{MY_POD_CACHE} and $path ) {
                print <<ECHO

Add this to your bashrc file (or compatible):

    [ "\$(which $file)" != "" ] && source $file

Or this one (if $file is not in your PATH):

    [ -f "$path" ] && source $path

ECHO
            }
        }
        sub ACTION_install {
            my ($s) = @_;
            $s->_clear_cache;
            $s->_check_for_source_command if os_type eq "Unix";
            $s->SUPER::ACTION_install;
        }
        sub ACTION_clean {
            my ($s) = @_;
            $s->_clear_cache;
            $s->SUPER::ACTION_clean;
        }
        sub ACTION_test {
            my ($s) = @_;
            $s->_clear_cache;
            $s->SUPER::ACTION_test;
        }
    },
);

my $builder = $class->new(
    module_name        => 'App::Pod',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov[AT]gmail.com>},
    dist_version_from  => 'lib/App/Pod.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'              => '5.024',
        'Module::Functions' => '2.1.3',
        'File::HomeDir'     => '1.006',
        'Mojo::File'        => '0',
        'Mojo::JSON'        => '0',
        'Pod::Query'        => '0.32',
    },
    add_to_cleanup => [
        'App-Pod-*',
        sprintf( "%s/.cache/my_pod*.cache",
            $ENV{HOME} // $ENV{USEPROFILE}
              // catfile( $ENV{HOMEDRIVE}, $ENV{HOMEPATH}, '' ) ),
    ],
    meta_merge => {
        resources => {
            bugtracker => 'https://github.com/poti1/app-pod/issues',
            repository => 'https://github.com/poti1/app-pod',
        },
    },
);

$builder->create_build_script();
