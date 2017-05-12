#!perl

use Test::More tests => 12;

use strict;
use warnings;

use lib 't';
use File::Temp;
use File::Spec::Functions qw[ catfile ];

use App::Env;

my $script = catfile( qw [ t appexec.pl ] );
my $badscript = catfile( qw [ t script_no_exist ] );

{
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );
    my $tmp = File::Temp->new;

    my $res = $app1->system( $^X,  $script, $tmp->filename );
    is( $res, 0, 'successful system call' );

    chomp( my $output = <$tmp> );
    is( $output, '1', 'successful system results' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0, SysFatal => 1 } );
    my $tmp = File::Temp->new;

    eval {
	$app1->system( $^X,  $script, $tmp->filename );
    };

    is( $@, '', 'successful system call: SysFatal' );

    chomp( my $output = <$tmp> );
    is( $output, '1', 'successful system results: SysFatal' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );
    my $tmp = File::Temp->new;

    my $res = $app1->system( $^X,  $badscript, $tmp->filename );
    isnt( $res, 0, 'unsuccessful system call' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0, SysFatal => 1 } );
    my $tmp = File::Temp->new;

    eval {
	$app1->system( $^X,  $badscript, $tmp->filename );
    };

    isnt( $@, '', 'unsuccessful system call: SysFatal' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );
    my $output = $app1->qexec( $^X, '-e', 'print $ENV{Site1_App1}' );
    chomp( $output );

    is( $output, '1', 'qexec: good script' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );
    my $output = $app1->qexec( $badscript );

    is( $output, undef, 'qexec: bad script' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0, SysFatal => 1 } );

    my $output = eval { $app1->qexec( $^X, '-e', 'print $ENV{Site1_App1}' ) };
    is( $@, '', 'qexec: good script call: SysFatal' );

    chomp( $output );

    is( $output, '1', 'qexec: good script results: SysFatal' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0, SysFatal => 1 } );

    my $output = eval { $app1->qexec( $badscript ) };
    isnt( $@, '', 'qexec: bad script call: SysFatal' );

    is( $output, undef, 'qexec: bad script' );
    App::Env::Site1::App1::reset();
}
