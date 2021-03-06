package ResultClassTwo;

use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('Bar');

__PACKAGE__->add_columns(
	foo => {
		data_type => 'INTEGER',
		is_auto_increment => 1,
	},
	bar => {
		data_type => 'VARCHAR',
		size => '10'
	},
);

__PACKAGE__->set_primary_key('foo');

package SchemaClassTwo;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

our $VERSION = '1.0';

__PACKAGE__->register_class('Bar', 'ResultClassTwo');
__PACKAGE__->load_components('DeploymentHandler::VersionStorage::Standard::Component');

1;
