#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use Test::Trap;

# -------------------------------------------------------------------
# Variables

my $CONFIG = 't/_DBDIR/preferences.ini';

# -------------------------------------------------------------------
# Tests

{
    use CPAN::Testers::WWW::Reports::Mailer;

    my $VERSION = '0.37';

    my $obj;
    my $stdout;
    my $config = 't/_DBDIR/preferences.ini';

    {
        trap { $obj = CPAN::Testers::WWW::Reports::Mailer->new() };

        #diag("DIE:" . $trap->die);
        #diag("EXIT:" . $trap->exit);
        #diag("STDOUT:" . $trap->stdout);
        #diag("STDERR:" . $trap->stderr);

        like($trap->die,qr/Must specify a configuration file/,'.. no file name');
        unlike($trap->stdout,qr/Usage:.*--config=<file>/,'.. got help');
    }

    {
        trap { $obj = CPAN::Testers::WWW::Reports::Mailer->new( config => 'bogus.file' ) };

        like($trap->die,qr/Configuration file .*? not found/,'.. no file found');
        unlike($trap->stdout,qr/Usage:.*--config=<file>/,'.. got help');
    }


    SKIP: {
        skip "No supported databases available", 4  unless(-f $CONFIG);

        {
            trap { $obj = CPAN::Testers::WWW::Reports::Mailer->new( config =>  $config, help => 1 ) };

            like($trap->stdout,qr/Usage:.*--config=<file>/,'.. got help');
            like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
        }

        {
            trap { $obj = CPAN::Testers::WWW::Reports::Mailer->new( config => $config, version => 1 ) };

            unlike($trap->stdout,qr/Usage:.*--config=<file>/,'.. no help');
            like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
        }
    }

}
