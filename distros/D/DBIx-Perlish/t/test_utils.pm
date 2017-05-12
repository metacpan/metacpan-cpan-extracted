# $Id$
package t::test_utils;
package main;

sub format_value { $_[0] }

sub test_sql
{
	my ($dbop, $sub, $tname, $exp_sql, $exp_v, $exp_kf) = @_;
	my @kf;
	my ($sql, $v) = DBIx::Perlish::gen_sql($sub, $dbop, flavor => $main::flavor || 'pg', key_fields => \@kf);
	if ($dbop eq "update" && ref($exp_sql)) {
		$exp_kf = $exp_v;
		my $ok = 0;
		for my $variant (@$exp_sql) {
			if ($variant->{sql} eq $sql) {
				$ok = 1;
				is($sql, $variant->{sql}, "$tname: SQL");
				is(+@$v, @{$variant->{values}}, "$tname: number of bound values");
				for (my $i = 0; $i < @$v; $i++) {
					my $bv = format_value($variant->{values}[$i]);
					is($v->[$i], $variant->{values}[$i], "$tname: bound value is '$bv'");
				}
			}
		}
		if (!$ok) {
			fail("$tname: not one SQL variant matches");
		}
	} else {
		is($sql, $exp_sql, "$tname: SQL");
		is(+@$v, @$exp_v, "$tname: number of bound values");
		for (my $i = 0; $i < @$v; $i++) {
			my $bv = format_value($exp_v->[$i]);
			is($v->[$i], $exp_v->[$i], "$tname: bound value is '$bv'");
		}
	}
	if ($exp_kf) {
		is(+@kf, +@$exp_kf, "$tname: number of key fields");
		for (my $i = 0; $i < @kf; $i++) {
			is($kf[$i], $exp_kf->[$i], "$tname: key field is '$exp_kf->[$i]'");
		}
	}
}

sub test_bad_sql
{
	my ($sub, $tname, $rx, $dbop) = @_;
	eval { DBIx::Perlish::gen_sql($sub, $dbop, flavor => $main::flavor || 'pg'); };
	my $err = $@||"";
	like($err, $rx, $tname);
}

sub test_select_sql (&$$$;$) { test_sql("select", @_) }
sub test_update_sql (&$$;$) { test_sql("update", @_) }
sub test_delete_sql (&$$$) { test_sql("delete", @_) }

sub test_bad_select (&$$) { test_bad_sql(@_,"select") }
sub test_bad_update (&$$) { test_bad_sql(@_,"update") }
sub test_bad_delete (&$$) { test_bad_sql(@_,"delete") }

1;
