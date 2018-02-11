package App::RemoteCommand::Util;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(prompt DEBUG logger);

use constant DEBUG => $ENV{PERL_RCOMMAND_DEBUG} ? 1 : 0;

use Term::ReadKey 'ReadMode';

sub logger {
    my $msg = @_ == 1 ? $_[0] : sprintf shift, @_;
    warn " | $msg\n";
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
