use strict;
use warnings FATAL => 'all';

package T::SWIT;
use base 'Apache::SWIT';
use File::Slurp;
use Carp;
use File::Basename qw(dirname);

sub swit_startup {
	append_file("/tmp/swit_startup_test", sprintf("%d %s %s\n"
			, $$, $_[0], (caller)[1]));
}

sub swit_render {
	my ($class, $r) = @_;
	if ($r->uri !~ /huge/) {
		my $f = dirname($INC{'T/SWIT.pm'}) . "/../templates/test.tt";
		$r->pnotes('SWITTemplate', $f);
	}
	return { hello => 'world', request => 'reqboo' };
}

sub swit_update {
	my ($class, $r) = @_;
	my $f = $r->param('file') or die "No file given";
	if ($f =~ /RESPOND/) {
		return [ Apache2::Const::OK, 'This is RESPONSE' ];
	} elsif ($f =~ /CTYPE/) {
		return [ Apache2::Const::OK, undef, 'text/plain' ];
	} else {
		write_file($f, $r->param('but') || '');
		write_file("$f.uri", $r->uri);
	}
	return '/test/res/r?res=hhhh';
}

sub ct_handler($$) {
	my ($class, $r) = @_;
	# check that session has our request
	my $rs = $r->pnotes('SWITSession')->request;
	return Apache2::Const::FORBIDDEN if $r->uri ne $rs->uri;
	$class->swit_send_http_header($r, "text/plain");

	# check that we have no session anymore
	return Apache2::Const::FORBIDDEN if $r->uri ne $rs->uri;
	return Apache2::Const::OK;
}

1;
