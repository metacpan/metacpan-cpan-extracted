#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
use Test::Trap;

{
    use CPAN::Testers::Data::Uploads::Mailer;

    my $VERSION = '0.06';

    my $obj;
    my $stdout;

    {
        trap { $obj = CPAN::Testers::Data::Uploads::Mailer->new( help => 1 ) };

        like($trap->stdout,qr/Usage:/,'.. got help');
        like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
    }

    {
        trap { $obj = CPAN::Testers::Data::Uploads::Mailer->new( version => 1 ) };

        unlike($trap->stdout,qr/Usage:/,'.. no help');
        like($trap->stdout,qr/$0 v$VERSION/,'.. got version');
    }

    {
        trap { $obj = CPAN::Testers::Data::Uploads::Mailer->new( source => 'nonextistentfile' ) };

        like($trap->stdout,qr/No uploads source log file/,'.. no source');
        like($trap->stdout,qr/Usage:/,'.. got help');
    }

}
