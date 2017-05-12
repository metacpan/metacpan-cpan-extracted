package CalDAVTest;
use Cal::DAV;

use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(get_cal_dav);

sub get_cal_dav {
	my $file   = shift;
    my $commit = shift || 0;
	return eval {
		Cal::DAV->new(
			user        => $ENV{CAL_DAV_USER},
			pass        => $ENV{CAL_DAV_PASS},
			url         => $ENV{CAL_DAV_URL_BASE}."/$file",
            auto_commit => $commit,
		)	
	};
}

1;
