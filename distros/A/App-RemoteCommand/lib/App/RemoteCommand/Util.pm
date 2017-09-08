package App::RemoteCommand::Util;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(prompt);

use Term::ReadKey 'ReadMode';

sub prompt {
    my $msg = shift;
    local $| = 1;
    print $msg;
    ReadMode 'noecho', \*STDIN;
    my $SIGNAL = "catch signal INT\n";
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
