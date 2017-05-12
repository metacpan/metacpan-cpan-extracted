package App::RunCron::CLI;
use strict;
use warnings;
use utf8;

use Getopt::Long;
use Pod::Usage;
use Time::Piece;
use YAML::Tiny ();

use App::RunCron;

sub new {
    my ($class, @argv) = @_;

    local @ARGV = @argv;
    my $p = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case bundling auto_help/],
    );
    $p->getoptions(\my %opt, qw/
        logfile=s
        timestamp
        print
        reporter=s
        error_reporter=s
        common_reporter=s
        announcer=s
        tag|t=s
        config|c=s
    /) or pod2usage(1);

    $opt{command} = [@ARGV];
    for my $rep (qw/reporter error_reporter announcer/){
        $opt{$rep} = ucfirst $opt{$rep} if $opt{$rep};
    }
    $class->new_with_options(%opt);
}

sub new_with_options {
    my ($class, %opt) = @_;

    if ($opt{logfile}) {
        my $now = localtime;
        $opt{logfile} = $now->strftime($opt{logfile});
    }

    if (!$opt{config} && -e 'runcron.yml') {
        $opt{config} = 'runcron.yml';
    }
    if ($opt{config}) {
        my $config_file = $opt{config};
        my $conf = eval { YAML::Tiny::LoadFile($config_file) };
        if ($@) {
            warn "Bad config: $config_file: $@";
        }
        else {
            %opt = (
                %$conf,
                %opt,
            );
        }
    }

    bless {
        runner => App::RunCron->new(%opt),
    }, $class;
}

sub run {
    shift->{runner}->run
}

1;
