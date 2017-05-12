use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::Test;
use base 'Exporter';
use Apache::SWIT::Test::Utils;
use Apache::SWIT::Maker::Config;
use File::Slurp;
use URI;
use HTML::Tested::Test::Request;

our @EXPORT_OK = qw(Find_Open_URLs Is_URL_Secure);

sub Is_URL_Secure {
	my ($t, $url, %args) = @_;
	my $r = $t->session->request;
	$r->set_params(\%args);
	$r->uri($t->root_location . "/");
	return !$t->session->is_allowed($url) unless $t->mech;
	my $ef = ASTU_Read_Error_Log();
	$t->mech->max_redirect(0);
	my $qs = join("&", map { "$_=" . $r->param($_) } $r->param);
	$url .= "?$qs" if $qs;
	$t->mech_get_base($url);
	$t->mech->max_redirect(7);
	write_file(ASTU_Module_Dir() . "/t/logs/error_log", $ef);
	return $t->mech->status == 403;
}

sub Find_Open_URLs {
	my ($t, %args) = @_;
	my @res;
	Apache::SWIT::Maker::Config->instance->for_each_url(sub {
		my ($url, $pname, $pentry, $ep) = @_; 
		push @res, $url unless Is_URL_Secure($t, $url, %args);
	});
	return sort @res;
}

1;
