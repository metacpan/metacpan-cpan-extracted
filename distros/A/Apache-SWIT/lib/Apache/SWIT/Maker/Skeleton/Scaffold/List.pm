use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Scaffold::List;
use base qw(Apache::SWIT::Maker::Skeleton::Page
		Apache::SWIT::Maker::Skeleton::Scaffold);
use Apache::SWIT::Maker::Conversions;

sub list_fields_v {
	my $res = shift()->fields_v;
	shift @$res;
	return $res;
}

sub link_title_v { return conv_table_to_class(shift()->col1_v); }

sub template { return <<'ENDS'; }
use strict;
use warnings FATAL => 'all';


package [% class_v %]::Root::Item;
use base 'HTML::Tested::ClassDBI';
use [% root_class_v %]::DB::[% table_class_v %];
__PACKAGE__->ht_add_widget(::HTV."::Link", '[% col1_v %]'
		, href_format => '../info/r?[% table_v %]_id=%s'
		, cdbi_bind => [ [% col1_v %] => 'Primary' ]
		, column_title => '[% link_title_v %]'
		, 0 => { isnt_sealed => 1 });
[% FOREACH list_fields_v %]__PACKAGE__->ht_add_widget(::HTV."::Marked"
			, '[% field %]', cdbi_bind => ''
			, column_title => '[% title %]');
[% END %]
__PACKAGE__->bind_to_class_dbi('[% root_class_v %]::DB::[% table_class_v %]');

package [% class_v %]::Root;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Form", 'form', default_value => 'u');
__PACKAGE__->ht_add_widget(::HT."::List", '[% list_name_v %]'
	, __PACKAGE__ . '::Item', render_table => 1);

package [% class_v %];
use base qw(Apache::SWIT::HTPage);


sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->[% list_name_v %]_containee_do(query_class_dbi => 'retrieve_all');
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	return "r";
}

1;
ENDS

1;
