package API::CPanel::Misc;

use strict;
use warnings;

use API::CPanel;
use Data::Dumper;

our $VERSION = 0.07;

# Перегружаем CPanel
sub reload {
    my $params = shift;

    return API::CPanel::action_abstract(
	params         => $params,
	func           => 'restartservice',
	container      => 'restart',
	allowed_fields => 'service',
    );
}

1;
