#!/usr/bin/perl -w

=head1 NAME

app.t

=head1 DESCRIPTION

test App::Basis

=head1 AUTHOR

 kevin mulholland, moodfarm@cpan.org

=cut

use v5.10;
use strict;
use warnings;
use Try::Tiny;
use Path::Tiny ;
use File::HomeDir ;
use Test::More tests => 20;

my $logfile = "/tmp/$$.log" ;

BEGIN { use_ok('App::Basis'); }

# App::Basis can die rather than exit, specially to help us test it!
set_test_mode(1);
set_log_file( $logfile) ;

# first off lest just test that it works
my $status = 0;

try {
    @ARGV = ();
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {}
    );
    $status = 1;
}
catch {
    note "  ERROR: caught $_";
};
ok( $status, 'Basic init_app' );
$status = 0;

try {
    @ARGV = ();
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => { fred => { required => 1, desc => 'something' } }
    );
}
catch {
    note "  CORRECT: caught $_";
    $status = 1;
};
ok( $status, 'missing desc' );
$status = 0;

try {
    @ARGV = ();
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => { fred => { desc => 'something', } }
    );
    $status = 1;
}
catch {
    note "  ERROR: caught $_";
};
ok( $status, 'has desc' );
$status = 0;

try {
    @ARGV = ('--fred');
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            fred => {
                desc     => 'something',
                required => 1
            }
        }
    );
    $status = 1;
}
catch {
    note "  ERROR: caught $_";
};
ok( $status, 'has required' );
$status = 0;

try {
    @ARGV = ();
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            fred => {

                # desc     => 'something',
                required => 1
            }
        }
    );
}
catch {
    $status = 1;
    note "  CORRECT: caught $_";
};
ok( $status, 'missing required' );
$status = 0;

try {
    @ARGV = ('--fred');
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            fred => {
                desc     => 'something',
                required => 1,
                depends  => 'bill'
            }
        }
    );
}
catch {
    note "  CORRECT: caught $_";
    $status = 1;
};
ok( $status, 'missing depends' );
$status = 0;

try {
    @ARGV = ( '--fred', '--bill' );
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            fred => {
                desc     => 'something',
                required => 1,
                depends  => 'bill'
            },
            bill => { desc => 'somedesc' }
        }
    );
    $status = 1;
}
catch {
    note "  ERROR: caught $_";
};
ok( $status, 'has depends' );
$status = 0;

try {
    @ARGV = ( '--fred=123', '--bill' );
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            'fred=i' => {
                desc     => 'something',
                required => 1,
                depends  => 'bill',
                default  => 123
            },
            bill => { desc => 'somedesc' }
        }
    );
    $status = 1 if ( $opt{fred} == 123 );
}
catch {
    note "  ERROR: caught $_";
};
ok( $status, 'sets default' );
$status = 0;

try {
    @ARGV = ( '--fred=123', '--bill' );
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            'fred=i' => {
                desc     => 'something',
                required => 1,
                depends  => 'bill',
                default  => 123,
                validate => 123
            },
            bill => { desc => 'somedesc' }
        }
    );
}
catch {
    note "  CORRECT: caught $_";
    $status = 1;
};
ok( $status, 'invalid validate function' );
$status = 0;

try {
    @ARGV = ( '--fred=123', '--bill' );
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            'fred=i' => {
                desc     => 'something',
                required => 1,
                depends  => 'bill',
                default  => 123,
                validate => sub { my $val = shift; return $val == 123; }
            },
            bill => { desc => 'somedesc' }
        }
    );
    $status = 1;
}
catch {
    note "  ERROR: caught $_";
};
ok( $status, 'validated parameter' );
$status = 0;

try {
    @ARGV = ( '--fred=123', '--bill' );
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            'fred=i' => {
                desc     => 'something',
                required => 1,
                depends  => 'bill',
                default  => 123,
                validate => sub { my $val = shift; return $val == 124; }
            },
            bill => { desc => 'somedesc' }
        }
    );
}
catch {
    note "  CORRECT: caught $_";
    $status = 1;
};
ok( $status, 'fails validated parameter' );
$status = 0;

try {
    @ARGV = (  );
    my %opt = init_app(
        help_text => "Boiler plate code for an App::Basis app",
        options   => {
            'help|h' => "extra help",
            "bill|h" => "reuse h"
        }
    );
}
catch {
    note "  CORRECT: caught $_";
    $status = 1;
};
ok( $status, 'duplication of options not allowed' );
$status = 0;


my $program = path($0)->basename ;
ok( get_program() eq $program, 'get_program correct' );

# windows has DIR command everything else should hopefully have ls
my ( $r, $o, $e );
if ( $^O =~ /MSWin32/ ) {
    ( $r, $o, $e ) = run_cmd('dir');
}
else {
    ( $r, $o, $e ) = run_cmd('ls');
}

ok( !$r, 'run_cmd on valid program' );
( $r, $o, $e ) = run_cmd('ls1234567890');
ok( $r, 'run_cmd on invalid program' );

# check fix_filename

my $current = Path::Tiny->cwd;
my $file    = fix_filename("~/");
my $home = File::HomeDir->my_home ;
ok( $file =~ "^$home", "fix_filename with tilde" );

$file = fix_filename("./");
ok( $file eq $current, "fix_filename with ./" );

$file = fix_filename(".");
ok( $file eq $current, "fix_filename with ." );

$file = fix_filename("../");
# my @tmp = split( /\//, $current );
# pop @tmp;    # remove last directory
# my $parent = join( '/', @tmp );    # rebuild
# ok( $file eq "$parent/", "fix_filename with ../" );
# just need to make sure that we have replaced it with something
ok( $file !~ /^\.\./, "fix_filename with ../") ;

unlink( $logfile) ;
# -----------------------------------------------------------------------------
# completed all the tests
