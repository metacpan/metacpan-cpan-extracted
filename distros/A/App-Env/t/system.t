#!perl

use Test2::V0;
use Test::Lib;

use Capture::Tiny 'capture', 'capture_stdout';
use File::Temp;
use File::Spec::Functions qw[ catfile ];

use App::Env;

my $script    = catfile( qw [ t bin appexec.pl ] );
my $badscript = catfile( qw [ t bin script_no_exist ] );

{
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );
    my $tmp  = File::Temp->new;

    my ( $stdout, $exit )
      = capture_stdout { $app1->system( $^X, $script, 'Site1_App1' ) };
    is( $exit, 0, 'successful system call' )
      or bail_out;

    chomp $stdout;
    is( $stdout, '1', 'successful system results' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0, SysFatal => 1 } );
    my $tmp  = File::Temp->new;

    my ( $stdout, $exit );

    ok(
        lives {
            ( $stdout, $exit )
              = capture_stdout { $app1->system( $^X, $script, 'Site1_App1' ) };
        },
        'successful system call: SysFatal'
    ) or bail_out( $@ );

    chomp $stdout;
    is( $stdout, '1', 'successful system results: SysFatal' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0 } );
    my $res
      = ( capture { $app1->system( $^X, $badscript ) } )[-1];
    isnt( $res, 0, 'unsuccessful system call' );
    App::Env::Site1::App1::reset();
}

{
    my $app1 = App::Env->new( 'App1', { Cache => 0, SysFatal => 1 } );
    like(
        dies {
            capture { $app1->system( $^X, $badscript ) }
        },
        qr/.+/,
        'unsuccessful system call: SysFatal',
    );
    App::Env::Site1::App1::reset();
}

{
    my $app1   = App::Env->new( 'App1', { Cache => 0 } );
    my $output = $app1->qexec( $^X, '-e', 'print $ENV{Site1_App1}' );
    chomp( $output );

    is( $output, '1', 'qexec: good script' );
    App::Env::Site1::App1::reset();
}

{
    my $app1   = App::Env->new( 'App1', { Cache => 0 } );
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

done_testing;
