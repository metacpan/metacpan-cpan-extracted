package TestApache::trap_subrequest;

use strict;
use warnings FATAL => 'all';

use Apache2::TrapSubRequest  ();
use Apache2::RequestRec      ();
use Apache2::RequestIO       ();

use APR::Table              ();

use Apache2::Const   -compile => qw(OK DECLINED FORBIDDEN);

sub handler {
    my $r = shift;
    $r->content_type('text/plain');
    my $output;
    $r->write("1..1\n");
    my $subr = $r->lookup_uri('/subreq_output');
    $subr->run_trapped(\$output);
    $r->log->debug($output);
    my ($loc) = ($r->location =~ /^(.*?)\s*$/);
    return Apache2::Const::FORBIDDEN unless $output eq "$loc\n";
    $r->write("ok 1\n");
    Apache2::Const::OK;
}

1;
