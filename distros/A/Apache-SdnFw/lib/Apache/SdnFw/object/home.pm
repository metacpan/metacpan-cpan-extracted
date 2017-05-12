# $Id: $
package Apache::SdnFw::object::home;

use strict;
use Carp;

sub config {
	my $s = shift;

	return {
		functions => {
			list => 'List',
			setup => 'Setup',
			cats => 'Categories',
			},
		};
}

sub cats {
	my $s = shift;

	if ($s->{in}{save}) {
		my %update;
		foreach my $k (keys %{$s->{in}}) {
			if ($k =~ m/^(.+):(.+)$/) {
				$update{$1}{$2} = $s->{in}{$k};
			}
		}

		$s->{dbh}->begin_work;

		foreach my $k (keys %update) {
			if ($k =~ m/^\d+$/) {
				if ($update{$k}{name}) {
					$s->db_update_key('object_cats','object_cat_id',$k,\%{$update{$k}});
				} else {
					$s->db_q("DELETE FROM object_cats WHERE object_cat_id=?",
						undef, v => [ $k ]);
				}
			} elsif ($update{$k}{name}) {
				$s->db_insert('object_cats',\%{$update{$k}});
			}
		}

		$s->{dbh}->commit;

		$s->notify("Categories Updated");
		$s->redirect(function => 'setup');
		return;
	}

	my @list = $s->db_q("
		SELECT *
		FROM object_cats
		ORDER BY name
		",'arrayhash');

	$s->add_action(function => 'setup');

	$s->tt('home/cats.tt', { s => $s, list => \@list });
}

sub setup {
	my $s = shift;

	if ($s->{in}{save}) {
		my %update;
		foreach my $k (keys %{$s->{in}}) {
			if ($k =~ m/^(.+):(.+)$/) {
				$update{$1}{$2} = $s->{in}{$k};
			}
		}

		$s->{dbh}->begin_work;

		foreach my $k (keys %update) {
			$update{$k}{home} = '' unless($update{$k}{home});
			$s->db_update_key('objects','code',$k,\%{$update{$k}});
		}

		$s->{dbh}->commit;

		$s->notify("Settings Updated");
		$s->redirect(function => 'list');
		return;
	}

	my @list = $s->db_q("
		SELECT *
		FROM objects
		ORDER BY lower(name)
		",'arrayhash');

	my @cats = $s->db_q("
		SELECT *
		FROM object_cats
		ORDER BY name
		",'arrayhash');

	$s->add_action(function => 'list');

	$s->add_action(function => 'cats',
		title => 'Categories');

	$s->tt('home/setup.tt', { s => $s, list => \@list, cats => \@cats });
}

sub list {
	my $s = shift;

	$s->add_action(function => 'setup');

	my @list = $s->db_q("
		SELECT o.code, o.name, COALESCE(oc.name,'zOther') as cat_name
		FROM objects o
			LEFT JOIN object_cats oc ON o.object_cat_id=oc.object_cat_id
		WHERE o.home IS TRUE
		ORDER BY cat_name, name
		",'arrayhash');

	$s->tt('home/home.tt', { s => $s, list => \@list });
}

1;
