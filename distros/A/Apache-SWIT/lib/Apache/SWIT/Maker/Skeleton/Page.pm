use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Page;
use base 'Apache::SWIT::Maker::Skeleton::Class';

__PACKAGE__->mk_accessors(qw(config_entry));

sub class_v { return shift()->config_entry->{class}; }

sub template { return <<'ENDS' };
use strict;
use warnings FATAL => 'all';

package [% class_v %];
use base qw(Apache::SWIT);

sub swit_render {
	my ($class, $req) = \@_;
	my $res = {};
	return $res;
}

1;
ENDS

1;
