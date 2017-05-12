package TestLib::print;

use Apache2::ModLogConfig;
use Apache2::Const -compile=>qw/OK/;
use APR::Const -compile=>qw/SUCCESS/;
use Apache2::RequestRec ();
use Apache2::RequestIO ();

sub handler {
    my ($r)=@_;

    my $log=$r->server->custom_log_by_name(q!logs/perl.log!);
    my @rc=$log->print($r, qw/hier war wasja/, "\n");

    $r->content_type('text/plain');
    $r->print(0+@rc, " @rc");

    return Apache2::Const::OK;
}

1;
