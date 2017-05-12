package TestLib::redir;

use Apache2::ModLogConfig;
use Apache2::Const -compile=>qw/OK/;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::SubRequest ();
use APR::Pool ();

sub handler {
    my ($r)=@_;

    if( $r->is_initial_req ) {
	# we require modperl 2.0.4. Hence the natural way is not possible:
	# 1 while $r->read($buf, 8000, length $buf);
	my $buf='';
	my $chunk='';
	$buf.=$chunk while $r->read($chunk, 8000);
	$r->pnotes->{input}=$buf;

	$r->internal_redirect($r->uri);
	return Apache2::Const::OK;
    }

    $r->pool->cleanup_register
	(sub {
	     my ($r)=@_;
	     my $log=$r->server->custom_log_by_name(q!logs/perl.log!);
	     $log->print($r, '>>> ', $r->notes->{'My::Hnd'}, "\n");
	 }, $r);

    $r->content_type('text/plain');
    $r->print($r->prev->pnotes->{input});

    return Apache2::Const::OK;
}

1;
