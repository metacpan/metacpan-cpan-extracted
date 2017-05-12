# $Id: $
package SITECODE::object::group;

use strict;
use Carp;

sub config {
	my $s = shift;
	
	return {
		id => 'group_id',
		table => 'groups',
		view => 'groups_v',
		functions => {
			create => 'Create',
			display => 'Display',
			save => 'Save',
			edit => 'Edit',
			delete => 'Delete',
			list => 'List',
			group_permission => 'Group Permission',
			copy_permission => 'Copy Permission',
			},
		display_functions => ['copy_permission','group_permission'],
		fields => [
			{ k => 'name', t => 'Name' },
			],
		relations => [
			{ t => 'employee_groups', 
				o => 'employee',
				k => 'employee_id', 
				n => 'employee_name', 
				},
			],
		};
}

sub copy_permission {
	my $s = shift;

	return unless($s->check_in_id());

	if ($s->{in}{copy_group_id}) {
		$s->{dbh}->begin_work;
		
		$s->db_q("DELETE FROM group_actions
			WHERE group_id=?
			",undef,
			v => [ $s->{in}{group_id} ]);

		$s->db_q("INSERT INTO group_actions (group_id, action_id)
			SELECT g.group_id, ga.action_id
			FROM groups g
				JOIN group_actions ga ON ga.group_id=?
			WHERE g.group_id=?
			",undef,
			v => [ $s->{in}{copy_group_id}, $s->{in}{group_id} ]);

		$s->{dbh}->commit;
		$s->redirect();
		return;
	}

	my @list = $s->db_q("
		SELECT *
		FROM groups_v
		WHERE group_id!=?
		ORDER BY name
		",'arrayhash',
		v => [ $s->{in}{group_id} ]);

	$s->add_action(function => 'display',
		params => "group_id=$s->{in}{group_id}");

	$s->tt('group/copy.tt', { s => $s, list => \@list });
}

sub group_permission {
	my $s = shift;

	return unless($s->check_in_id());

	if ($s->{in}{f} eq 'save') {
		my %exist = $s->db_q("
			SELECT action_id, group_id
			FROM group_actions
			WHERE group_id=?
			",'keyval',
			v => [ $s->{in}{group_id} ]);
		
		my %everyone = $s->db_q("
			SELECT a.action_id, count(ga.group_id)
			FROM actions a
				LEFT JOIN group_actions ga ON a.action_id=ga.action_id
			GROUP BY 1
			HAVING count(ga.group_id)=0
			",'keyval');

		$s->{dbh}->begin_work;
		foreach my $k (keys %{$s->{in}}) {
			if ($k =~ m/^a:(\d+)$/) {
				my $action_id = $1;
				next if (defined($everyone{$action_id}));
				if (defined($exist{$action_id})) {
					# it is still checked so
					# delete it so we know not to delete it below
					delete $exist{$action_id};
				} else {
					#$s->notify("Add $action_id");
					$s->db_insert('group_actions',{
						group_id => $s->{in}{group_id},
						action_id => $action_id,
						});
				}
			}
		}

		# delete any actions that were not checked but still defined
		foreach my $action_id (keys %exist) {
			#$s->notify("Delete $action_id");
			$s->db_q("DELETE FROM group_actions
				WHERE group_id=?
				AND action_id=?
				",undef,
				v => [ $s->{in}{group_id}, $action_id ]);
		}

		$s->{dbh}->commit;

		$s->notify("Permissions updated");
		$s->redirect();
		return;
	}

	my @list = $s->db_q("
		SELECT COALESCE(oc.name,'z_unclassified') as object_cat,
			o.name as object_name, o.code, a.name as action_name, a.action_id,
			CASE WHEN ga.group_id IS NOT NULL THEN TRUE ELSE NULL END as checked
		FROM objects o
			LEFT JOIN object_cats oc ON o.object_cat_id=oc.object_cat_id
			JOIN groups g ON g.group_id=?
			JOIN actions a ON o.code=a.a_object
			LEFT JOIN group_actions ga ON a.action_id=ga.action_id
				AND ga.group_id=g.group_id
		ORDER BY object_cat, object_name, action_name
		",'arrayhash',
		v => [ $s->{in}{group_id} ]);

	$s->add_action(function => 'display');

	$s->tt('group/edit_permission.tt', { s => $s, list => \@list });
}

sub delete {
	my $s = shift;

	return unless($s->check_in_id());

	unless($s->{in}{confirm}) {
		$s->confirm("Are you sure");
		return;
	}

	$s->{dbh}->begin_work;

	$s->db_q("DELETE FROM group_actions WHERE group_id=?", undef, v => [ $s->{in}{group_id} ]);
	$s->db_q("DELETE FROM employee_groups WHERE group_id=?", undef, v => [ $s->{in}{group_id} ]);
	$s->db_q("DELETE FROM groups WHERE group_id=?", undef, v => [ $s->{in}{group_id} ]);

	$s->{dbh}->commit;

	$s->redirect(function => 'list');
}

1;
