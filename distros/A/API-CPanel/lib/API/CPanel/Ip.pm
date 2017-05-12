package API::CPanel::Ip;

use strict;
use warnings;

use API::CPanel;
use Data::Dumper;

our $VERSION = 0.07;

# Возвращает список ip адресов
sub list {
    my $params = shift;

    return API::CPanel::fetch_array_abstract(
	params       => $params,
	func         => 'listips',
	container    => 'result',
	result_field => 'ip',
    );
}

# Добавить ip
sub add {
    my $params = shift;

    return API::CPanel::action_abstract( 
	params         => $params,
	func           => 'addip',
	container      => 'addip',
	allowed_fields => 'ip netmask',
    );
}

# Удалить ip
sub remove {
    my $params = shift;

    return API::CPanel::action_abstract( 
	params         => $params,
	func           => 'delip',
	container      => 'delip',
	allowed_fields => 'ip ethernetdev skipifshutdown',
    );
}


1;
