#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Uploads::Mailer;
use File::Slurp;
use File::Path;
use IO::File;
use Test::More tests => 7;

my %params = (
    source      => 't/samples/uploads.log',
    lastfile    => 't/test/uploads-mailer.txt',
    logfile     => 't/test/uploads-mailer.log',
    debug       => 1,
    test        => 1
);

rmtree('t/test');

mkpath('t/test');
write_file($params{lastfile},39941);

{
    my $mailer;
    eval { 
        $mailer = CPAN::Testers::Data::Uploads::Mailer->new(%params); 
        $mailer->process();
    };

    is($@,'','.. processed without errors');
    my $id = read_file($params{lastfile});
    is($id,39968,'.. last id updated');

    is(-f $params{logfile},undef,'.. logfile not created');
}

$params{source} = 't/samples/uploads-big.log';
rmtree('t/test');

{
    my $mailer;
    eval { 
        $mailer = CPAN::Testers::Data::Uploads::Mailer->new(%params); 
        $mailer->process();
    };

    is($@,'','.. processed without errors');
    my $id = read_file($params{lastfile});
    is($id,40030,'.. last id updated');

    is(-f $params{logfile},1,'.. logfile created');

    my $text = read_file($params{logfile});
    like($text,qr/barbie\@missbarbell\.co\.uk/,'.. logfile updated');
}
