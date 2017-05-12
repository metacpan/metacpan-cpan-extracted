use strict;
use warnings FATAL => 'all';

package T::HTInherit::Root;
use base 'T::HTPage::Root';

__PACKAGE__->ht_add_widget(::HTV."::Marked", 'inhe_val');

sub ht_render {
	my ($self, $stash, $req) = @_;
	$self->inhe_val($req->param('inhe'));
	$self->SUPER::ht_render($stash, $req);
}

package T::HTInherit;
use base 'T::HTPage';

1;
