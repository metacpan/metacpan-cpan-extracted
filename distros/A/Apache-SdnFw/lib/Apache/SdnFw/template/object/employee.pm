# $Id: $
package SITECODE::object::employee;

use strict;
use Carp;

sub config {
	my $s = shift;

	return {
		id => 'employee_id',
		table => 'employees',
		view => 'employees_v',
		functions => {
			list => 'List',
			create => 'Create',
			save => 'Save',
			edit => 'Edit',
			delete => 'Delete',
			display => 'Display',
			log => 'Log',
			},
		fields => [
			{ k => 'login', t => 'Login', },
			{ k => 'name', t => 'Name', },
			{ k => 'email', t => 'Email', },
			{ k => 'passwd', t => 'Password (encrypted)', },
			],
		relations => [
			{ t => 'employee_groups', 
				o => 'group', 
				k => 'group_id', 
				n => 'group_name', 
				},
			],
		};
}

1;

