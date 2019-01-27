package App::Perlambda::CLI;

use strict;
use warnings;
use utf8;
use Getopt::Long;

use App::Perlambda;

sub run {
    my ($class, @args) = @_;

    my $p = Getopt::Long::Parser->new(
        config => ['no_ignore_case', 'posix_default', 'gnu_compat'],
    );

    my @commands;
    my $version;
    $p->getoptions(
        'h|help' => sub {unshift @commands, 'help'},
        'version' => sub {
            print "perlambda: $App::Perlambda::VERSION\n";
            exit 0;
        },
    );

    push @commands, @ARGV;
    my $cmd = shift @commands || 'help';
    my $klass = sprintf("App::Perlambda::CLI::%s", ucfirst($cmd));

    ## no critic
    if (eval sprintf("require %s; 1;", $klass)) {
        eval {
            $klass->run(@commands);
        };
        if ($@) {
            print "[ERROR] $@\n";
            exit 1;
        }

        if ($klass ne 'App::Perlambda::CLI::Help') {
            print "[INFO] Done.\n";
        }
        exit 0;
    }

    print "[ERROR] could not find command '$cmd'\n";
    if ($@ !~ m!^Can't locate App/Perlambda!) {
        print("[ERROR] $@\n");
    }
    exit 2;
}

1;

__END__

