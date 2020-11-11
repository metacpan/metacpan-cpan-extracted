package CPAN::Digger::CLI;
use strict;
use warnings FATAL => 'all';

our $VERSION = '1.03';

use Getopt::Long qw(GetOptions);

use CPAN::Digger;

sub run {
    my %args = (
        report => undef,
        author => undef,
        github => undef,
        recent => undef,
        log    => 'INFO',
        help   => undef,
        sleep  => 0,
        db     => undef,
        version => undef,
        limit   => undef,
    );

    GetOptions(
        \%args,
        'author=s',
        'db=s',
        'recent=i',
        'limit=i',
        'sleep=i',
        'github',
        'log=s',
        'report',
        'help',
        'version',
    ) or usage();
    usage() if $args{help};
    if ($args{version}) {
        print "CPAN::Digger VERSION $VERSION\n";
        exit();
    }
    usage() if not ($args{author} xor $args{recent});


    my $cd = CPAN::Digger->new(%args);
    $cd->collect();
}


sub usage {
    die qq{CPAN::Digger VERSION $VERSION

Usage: $0
    Required exactly one of them:
       --recent N         (Number of the most recent packages to check)
       --author PAUSEID

       --report           (Show text report at the end of processing.)
       --log LEVEL        [ALL, TRACE, DEBUG, INFO, WARN, ERROR, FATAL, OFF] (default is INFO)

       --github           Fetch information from github
       --sleep SECONDS    (Wait time between git clone operations, defaults to 0)

       --db PATH          (path to SQLite database file, if not supplied using in-memory database)

       --version
       --help

    Sample usage for authors:
        $0 --author SZABGAB --report --github --sleep 3

    Sample usage in general:
        $0 --recent 30 --report --github --sleep 3

};
}


42;

