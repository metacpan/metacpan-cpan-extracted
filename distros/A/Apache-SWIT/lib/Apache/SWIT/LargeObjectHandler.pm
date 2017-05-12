use strict;
use warnings FATAL => 'all';

package Apache::SWIT::LargeObjectHandler;
use base qw(Apache::SWIT);
use HTTP::Date;
use Carp;

sub serve_lo {
	my ($class, $r, $dbh, $loid, $bufsiz) = @_;
	my $lo_fd = $dbh->func($loid, $dbh->{'pg_INV_READ'}, 'lo_open');
	defined($lo_fd) or die "# Unable to lo_open $loid";
	my $buf = '';
	$dbh->func($lo_fd, $buf, $bufsiz, 'lo_read');
	my $ct = $r->param("ct");
	($ct, $buf) = HTML::Tested::ClassDBI::Upload->strip_mime_header($buf) if (!$ct);
	confess "No content type found!" unless $ct;
	$r->headers_out->add('Expires', HTTP::Date::time2str(
				time + 240*24*60*60));
	$class->swit_send_http_header($r, $ct);
	do {
		$r->print($buf);
	} while ($dbh->func($lo_fd, $buf, $bufsiz, 'lo_read'));
}

sub swit_render_handler($$) {
	my($class, $ar) = @_;
	my $r = Apache2::Request->new($ar);
	my $enc_loid = $r->param("loid") or confess "No loid was given";
	my $loid = HTML::Tested::Seal->instance->decrypt($enc_loid)
			or confess "Unable to decrypt loid: $enc_loid";
	my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
	$dbh->begin_work;
	eval { $class->serve_lo($r, $dbh, $loid, 4096 * 4); };
	if ($@) {
		$dbh->rollback;
		confess "Original error $@";
	} else {
		$dbh->commit;
	}
	return Apache2::Const::OK;
}

1;
