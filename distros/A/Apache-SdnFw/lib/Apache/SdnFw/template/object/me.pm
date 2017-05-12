# $Id: $
package SITECODE::object::me;

use strict;
use Carp;

sub config {
	my $s = shift;

	return {
		id => 'employee_id',
		table => 'employees',
		view => 'employee_v',
		functions => {
			change_password => 'Change Password',
			save => 'Save',
			edit => 'Edit',
			list => 'List',
			},
		fields => [ { k => '', t => '', }, ],
		};
}

sub change_password {
	my $s = shift;

	$s->add_action(function => 'list', title => 'display');

	if ($s->{in}{passwd}) {
		if (length $s->{in}{passwd} < 4) {
			$s->alert("Your new password must be at least 4 characters");
		} else {
			if ($s->{in}{passwd} eq $s->{in}{confirm_passwd}) {
				$s->db_q("UPDATE employees SET passwd=?
					WHERE employee_id=?
					",undef,
					v => [ $s->{in}{passwd}, $s->{employee_id} ]);

				$s->notify("Your password has been changed.  You will need to login again...");
				return;
			} else {
				$s->alert("Your new password and confirm password do not match");
			}	
		}
	}

	$s->tt("me/change_password.tt", { s => $s });
}

sub save {
	my $s = shift;

	my %hash = $s->db_q("
		SELECT *
		FROM employees_v
		WHERE employee_id=?
		",'hash',
		v => [ $s->{employee_id} ]);

	my %update;

	foreach my $k (qw(email)) {
		if ($s->{in}{$k}) {
			unless($s->verify_email(\$s->{in}{$k})) {
				croak "$s->{in}{$k} is not a valid email";
			}
		}
		$update{$k} = $s->{in}{$k};
	}

	foreach my $k (qw(login name)) {
		$update{$k} = $s->{in}{$k};
	}

	# only update what has changed
	foreach my $k (keys %update) {
		if ($hash{$k} eq $update{$k}) {
			delete $update{$k};
		}
	}

	$s->db_update_key('employees','employee_id',$s->{employee_id},\%update)
		if (keys %update);

	$s->{redirect} = "$s->{ubase}/$s->{object}/list";
}

sub edit {
	my $s = shift;

	my %hash = $s->db_q("
		SELECT *
		FROM employees_v
		WHERE employee_id=?
		",'hash',
		v => [ $s->{employee_id} ]);

	$s->add_action(function => 'list', title => 'display');
	$s->add_action(function => 'change_password');

	$s->tt('me/edit.tt',{ s => $s, hash => \%hash });
}

sub list {
	my $s = shift;

	my %hash = $s->db_q("
		SELECT *
		FROM employees_v
		WHERE employee_id=?
		",'hash',
		v => [ $s->{employee_id} ]);

	$s->add_action(function => 'edit');
	$s->add_action(function => 'change_password');

	$s->tt('me/list.tt',{ s => $s, hash => \%hash });
}

1;

