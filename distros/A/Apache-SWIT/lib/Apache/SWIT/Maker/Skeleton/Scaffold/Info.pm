use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Scaffold::Info;
use base qw(Apache::SWIT::Maker::Skeleton::Page
		Apache::SWIT::Maker::Skeleton::Scaffold);

sub template { return <<'ENDS'; }
use strict;
use warnings FATAL => 'all';

package [% class_v %]::Root;
use base 'HTML::Tested::ClassDBI';
use [% root_class_v %]::DB::[% table_class_v %];
__PACKAGE__->ht_add_widget(::HTV."::Form", form => default_value => 'u');
[% FOREACH fields_v %]
__PACKAGE__->ht_add_widget(::HTV."::Marked"
	, [% field %] => cdbi_bind => '');[% END %]
__PACKAGE__->ht_add_widget(::HTV, [% table_v %]_id => cdbi_bind => 'Primary');
__PACKAGE__->bind_to_class_dbi('[% root_class_v %]::DB::[% table_class_v %]');

package [% class_v %];
use base qw(Apache::SWIT::HTPage);


sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->cdbi_load;
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	return "r";
}

1;
ENDS

1;
