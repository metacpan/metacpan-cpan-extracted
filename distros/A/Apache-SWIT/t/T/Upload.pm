use strict;
use warnings FATAL => 'all';

package T::Upload::Image;
use base 'HTML::Tested::Value::Upload';

sub absorb_one_value {
	my ($self, $root, $val, @path) = @_;
	return unless $val->size;
	$self->SUPER::absorb_one_value($root, $val, @path);
}

package T::Upload::DB;
use base 'Apache::SWIT::DB::Base';
__PACKAGE__->set_up_table('upt');

package T::Upload::Root;
use base 'HTML::Tested::ClassDBI';
use HTML::Tested qw(HTV);

__PACKAGE__->ht_add_widget(::HTV, id => is_sealed => 1
					=> cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::Upload", the_upload => cdbi_upload =>
				'loid');
__PACKAGE__->ht_add_widget('T::Upload::Image', mime_upload =>
		cdbi_upload_with_mime => 'loid');
__PACKAGE__->ht_add_widget(::HTV, loid => is_sealed => 1 => cdbi_bind => ''
				, cdbi_readonly => 1, skip_undef => 1);
__PACKAGE__->ht_add_widget(::HTV."::Form", form => default_value => 'u');
__PACKAGE__->ht_add_widget(::HTV."::EditBox", "val");
__PACKAGE__->bind_to_class_dbi("T::Upload::DB");

sub ht_validate { return (); }

package T::Upload;
use base 'Apache::SWIT::HTPage';

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->cdbi_load;
	return $root;
}

sub swit_post_max { return '20000'; }

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	my $m = $r->body_status =~ /maximum/;
	my $to = $m ? "r?val=too_big" : "r";
	return $class->swit_failure($to, 'the_upload') if ($m || $root->val);

	$root->cdbi_create_or_update;
	return $root->ht_make_query_string("r", "id");
}

1;
