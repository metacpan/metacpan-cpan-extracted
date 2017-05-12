use strict;
use warnings FATAL => 'all';

package Apache::SWIT::HTPage::Safe;
use base 'Apache::SWIT::HTPage';
use Carp;

sub swit_render {
	my ($class, $r) = @_;
	my $stash = $class->SUPER::swit_render($r);
	my $es = $r->param('swit_errors') or goto OUT;
	$class->ht_root_class->ht_error_render($stash, 'swit_errors', $es);
OUT:
	return $stash;
}

sub _encode_errors {
	return shift()->swit_encode_errors(@_);
}

sub swit_encode_errors {
	my ($class, $errs) = @_;
	my $es = $class->ht_root_class->ht_encode_errors(@$errs);
	return "r?swit_errors=$es";
}

sub ht_swit_validate_die {
	my ($class, $errs, $r, $root) = @_;
	return $class->swit_encode_errors($errs);
}

sub ht_swit_update_die {
	my ($class, $msg, $r, $root) = @_;
	my ($uq) = ($msg =~ /unique constraint "(\w+)"/);
	goto ORIG_ERROR unless $uq;

	my $dbh = Apache::SWIT::DB::Connection->instance->db_handle;
	my $idef = $dbh->selectcol_arrayref("select indexdef from pg_indexes"
		. " where indexname = ? and tablename = ?", undef, $uq
			, $root->CDBI_Class->table);
	goto ORIG_ERROR unless ($idef && $idef->[0]);

	my ($iargs) = ($idef->[0] =~ /\((.*)\)$/);
	confess "No index args for $idef->[0]" unless $iargs;

	my %cols = map { ($_, 1) } split(/, /, $iargs);
	my @errs = map { [ $_->[1], "unique" ] } grep { $cols{$_->[0]} }
		map { [ ($_->options->{cdbi_bind} || $_->options->{safe_bind}
				|| $_->name), $_->name ] }
		grep { exists($_->options->{cdbi_bind})
				|| exists($_->options->{safe_bind}) }
			@{ $root->Widgets_List };
	return $class->swit_encode_errors(\@errs);

ORIG_ERROR:
	return shift()->SUPER::ht_swit_update_die(@_);
}

1;
