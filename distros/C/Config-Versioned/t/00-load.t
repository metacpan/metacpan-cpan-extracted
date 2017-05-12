## t/00-load.t
##
## Written 2012 by Scott Hardin for the OpenXPKI project
## Copyright (C) 2010-2012 by Scott T. Hardin
##
## vim: syntax=perl

use Test::More tests => 1;

BEGIN {
    my $gittestdir = 't/00-load.git';

    # remove artifacts from previous run
    use Path::Class;
    use DateTime;
    dir($gittestdir)->rmtree;

    use_ok(
        'Config::Versioned',
#        {
#            dbpath      => $gittestdir,
#            filename    => '00-load.conf',
#            path        => [qw( t )],
#            commit_time => DateTime->from_epoch( epoch => 1240341682 ),
#            author_name => 'Test User',
#            author_mail => 'test@example.com',
#        }
    );
}

diag("Testing Config::Versioned $Config::Versioned::VERSION, Perl $], $^X");
