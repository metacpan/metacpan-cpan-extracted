package Schema::Foo::0_1_0::Result::Person;

use base qw(DBIx::Class::Core);
use strict;
use warnings;

our $VERSION = 0.04;

__PACKAGE__->load_components('InflateColumn::DateTime');
__PACKAGE__->table('person');
__PACKAGE__->add_columns(
	'person_id' => {
		'data_type' => 'integer',
		'is_auto_increment' => 1,
	},
	'email' => {
		'data_type' => 'text',
		'size' => 255,
	},
	'name' => {
		'data_type' => 'text',
		'size' => 255,
	},
);
__PACKAGE__->set_primary_key('person_id');
__PACKAGE__->add_unique_constraint(
	'person_email_unique_key' => ['email'],
);

1;

__END__
