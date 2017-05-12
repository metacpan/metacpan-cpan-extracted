use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Template;
use base 'Apache::SWIT::Maker::Skeleton';

__PACKAGE__->mk_accessors(qw(config_entry));

sub output_file {
	return shift()->config_entry->{entry_points}->{r}->{template};
}

sub template { return <<'ENDS' };
<html>
<body>
</body>
</html>
ENDS

1;
