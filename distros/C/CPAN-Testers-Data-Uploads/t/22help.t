#!/usr/bin/perl -w
use strict;

use Test::More tests => 10;
use Test::Trap;

{
    use CPAN::Testers::Data::Uploads;

    my $VERSION = '0.21';

    my $obj;
    my $stdout;
    my $config = 't/_DBDIR/10attributes.ini';

    {
        trap { $obj = CPAN::Testers::Data::Uploads->new() };

        like($trap->stdout,qr/Must specify at least one option from/,'.. no option');
        like($trap->stdout,qr/Usage:.*--config=<file>/,'.. got help');
    }

    {
        trap { $obj = CPAN::Testers::Data::Uploads->new( generate => 1 ) };

        like($trap->stdout,qr/Must specific the configuration file/,'.. no file name');
        like($trap->stdout,qr/Usage:.*--config=<file>/,'.. got help');
    }

    {
        trap { $obj = CPAN::Testers::Data::Uploads->new( config => 'bogus.file', generate => 1 ) };

        like($trap->stdout,qr/Configuration file .*? not found/,'.. no file found');
        like($trap->stdout,qr/Usage:.*--config=<file>/,'.. got help');
    }

    {
        trap { $obj = CPAN::Testers::Data::Uploads->new( config =>  $config, help => 1 ) };

        like($trap->stdout,qr/Usage:.*--config=<file>/,'.. got help');
        like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
    }

    {
        trap { $obj = CPAN::Testers::Data::Uploads->new( config => $config, version => 1 ) };

        unlike($trap->stdout,qr/Usage:.*--config=<file>/,'.. no help');
        like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
    }

}
