package App::Glacier::Job::InventoryRetrieval;
use strict;
use warnings;

require App::Glacier::Job;
use parent qw(App::Glacier::Job);
use Carp;

# new(CMD, VAULT)
sub new {
    croak "bad number of arguments" unless $#_ >= 2;
    my ($class, $cmd, $vault, %opts) = @_;
    return $class->SUPER::new(
	$cmd, $vault, $vault,
	[ 'initiate_inventory_retrieval', $vault, 'JSON',
	  "Inventory retrieval for vault $vault" ],
	ttl => $cmd->cfget(qw(database inv ttl)),
	%opts);
}

