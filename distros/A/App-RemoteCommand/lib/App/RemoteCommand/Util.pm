package App::RemoteCommand::Util;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use Exporter 'import';
our @EXPORT_OK = qw(prompt DEBUG logger);

use constant DEBUG => $ENV{PERL_RCOMMAND_DEBUG} ? 1 : 0;

use Term::ReadKey 'ReadMode';

sub logger (@args) {
    my $msg = @args == 1 ? $args[0] : sprintf shift(@args), @args;
    warn " | $msg\n";
}

sub prompt ($msg) {
    local $| = 1;
    print $msg;
    ReadMode 'noecho', \*STDIN;
    my $SIGNAL = "Catch SIGINT\n";
    my $answer;
    eval {
        local $SIG{INT} = sub (@) { die $SIGNAL };
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
