package TestApache::does_it_work;

use strict;
use warnings FATAL => 'all';

BEGIN {
    if ($ENV{MOD_PERL_API_VERSION}) {
        require Apache2::RequestRec;
        require Apache2::RequestIO;
        require Apache2::LogF;
        require Apache2::Const;
        Apache2::Const->import(-compile => qw(OK));
    }
    elsif ($ENV{MOD_PERL}) {
        require Apache::LogF;
        require Apache::Constants;
        Apache::Constants->import(qw(OK));
        *Apache2::Const::OK = \&OK;
    }
    else {
        *Apache2::Const::OK = sub () { 1 };
    }
}

sub handler {
    my $r   = shift;
    my $log = $r->log;

    # because i really am that lazy.

    $log->debugf('%s', 'hi');
    $log->infof('%s', 'hi');
    $log->noticef('%s', 'hi');
    $log->warnf('%s', 'hi');
    $log->errorf('%s', 'hi');
    $log->critf('%s', 'hi');
    $log->alertf('%s', 'hi');
    $log->emergf('%s', 'hi');


    for my $method 
        (qw(emergf alertf critf errorf warnf noticef infof debugf)) {
        no strict 'refs';
        $log->$method('%s is really neat %d %f wow that was great.', 
            $method, $$, 3.1337);
    }

    $r->print("1..1\n");
    $r->print("ok 1\n");

    return Apache2::Const::OK;
}

1;
