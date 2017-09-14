package App::RemoteCommand::Util;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(prompt DEBUG logger);

use constant DEBUG => $ENV{PERL_RCOMMAND_DEBUG} ? 1 : 0;

use POSIX ();
use Term::ReadKey 'ReadMode';

sub logger {
    my $msg;
    if (@_ == 1) {
        $msg = $_[0];
    } else {
        $msg = sprintf shift, @_;
    }
    warn "-> $msg\n";
}

sub prompt {
    my $msg = shift;
    local $| = 1;
    print $msg;
    ReadMode 'noecho', \*STDIN;
    my $SIGNAL = "Catch SIGINT\n";
    my $answer;
    eval {
        local $SIG{INT} = sub { die $SIGNAL };
        $answer = <STDIN>;
    };
    my $error = $@;
    ReadMode 'restore', \*STDIN;
    print "\n";
    die $error if $error;
    chomp $answer;
    $answer;
}

1;
