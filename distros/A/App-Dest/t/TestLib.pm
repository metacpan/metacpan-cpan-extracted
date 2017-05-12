package TestLib;

use strict;
use warnings;

use Cwd 'getcwd';
use File::Path qw( mkpath rmtree );

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( t_module t_dir t_startup t_teardown t_capture t_action_files );

require App::Dest;
sub t_module { App::Dest->clear }

{
    my ( $dir, $pwd );

    sub t_dir {
        $dir ||= ( $ENV{APPDESTDIR} ) ? $ENV{APPDESTDIR} . $$ : 'dest_test_' . $$;
    }

    sub t_startup {
        $pwd = getcwd();
        t_dir();
        mkpath($dir) unless ( -d $dir );
        chdir($dir);
    }

    sub t_teardown {
        chdir($pwd);
        rmtree($dir);
        ( $pwd, $dir ) = ( undef, undef );
    }
}

sub t_capture {
    my $sub = shift;

    local *STDOUT;
    my $stdout;
    open( STDOUT, '>', \$stdout );

    local *STDERR;
    my $stderr;
    open( STDERR, '>', \$stderr );

    eval { $sub->(@_) };

    return $stdout, $stderr, $@;
}

sub t_action_files {
    for my $action (@_) {
        my ( $deploy_prereq, $revert_prereq );
        ( $action, $deploy_prereq, $revert_prereq ) = @$action if ( ref $action );

        ( my $name = $action ) =~ s/\W/_/g;
        $name = 'state_' . $name . '.txt';

        mkpath($action);

        open( my $deploy, '>', $action . '/deploy.bat' );
        print $deploy "echo $action >> $name\n";
        print $deploy ':; # dest.prereq: ', $deploy_prereq, "\n" if ($deploy_prereq);
        close $deploy;

        open( my $verify, '>', $action . '/verify.bat' );
        print $verify ':<<CMDLITERAL', "\n";
        print $verify '@echo off', "\n";
        print $verify 'goto :CMDSCRIPT', "\n";
        print $verify 'CMDLITERAL', "\n";
        print $verify 'state=`grep ' . $action . ' ' . $name . ' 2> /dev/null`', "\n";
        print $verify 'if [ ${#state} -gt 0 ]; then echo 1; else echo 0; fi', "\n";
        print $verify 'exit', "\n";
        print $verify ':CMDSCRIPT', "\n";
        print $verify 'set /p state=<', $name, "\n";
        print $verify 'if %state%==' . $action . ' ( echo 1 ) else ( echo 0 )', "\n";
        close $verify;

        open( my $revert, '>', $action . '/revert.bat' );
        print $revert "echo '' > $name\n";
        print $revert ':; # dest.prereq: ', $revert_prereq, "\n" if ($revert_prereq);
        close $revert;

        chmod( 0755, map { $action . '/' . $_ } qw( deploy.bat verify.bat revert.bat ) );
    }

    return;
}

1;
