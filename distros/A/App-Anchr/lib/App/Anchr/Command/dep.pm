package App::Anchr::Command::dep;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => 'check or install dependances';

sub opt_spec {
    return ( [ 'install', 'install dependances', ], { show_defaults => 1, } );
}

sub usage_desc {
    return "anchr dep [options]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 0 ) {
        my $message = "This command need no input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $stopwatch = AlignDB::Stopwatch->new;

    $stopwatch->block_message("Check basic infrastructures");
    if ( IPC::Cmd::can_run("brew") ) {
        print "OK: find [brew] in \$PATH\n";
    }
    else {
        print "Failed: can't find [brew] in \$PATH\n";
    }

    if ( IPC::Cmd::can_run("cpanm") ) {
        print "OK: find [cpanm] in \$PATH\n";
    }
    else {
        print "Failed: can't find [cpanm] in \$PATH\n";
    }

    if ( $opt->{install} ) {
        $stopwatch->block_message("Install dependances via Linuxbrew");
        my $sh = File::ShareDir::dist_file( 'App-Anchr', 'install_dep.sh' );
        if ( IPC::Cmd::run( command => [ "bash", $sh ], verbose => 1, ) ) {
            $stopwatch->block_message("OK: all dependances installed");
        }
        else {
            $stopwatch->block_message("*Failed*");
            exit 1;
        }

        $stopwatch->block_message("Install Perl modules via cpanm");
        my $tar = "https://github.com/wang-q/App-Anchr/archive/0.1.4.tar.gz";
        if ( IPC::Cmd::run( command => [ "cpanm", "--installdeps", $tar ], verbose => 1, ) ) {
            $stopwatch->block_message("OK: all Perl modules installed");
        }
        else {
            $stopwatch->block_message("*Failed*");
            exit 1;
        }
    }
    else {
        $stopwatch->block_message("Check other dependances");

        my $sh = File::ShareDir::dist_file( 'App-Anchr', 'check_dep.sh' );
        if ( IPC::Cmd::run( command => [ "bash", $sh ], verbose => 1, ) ) {
            $stopwatch->block_message("OK: all dependances present");
        }
        else {
            $stopwatch->block_message("*Failed*");
            exit 1;
        }
    }
}

1;
