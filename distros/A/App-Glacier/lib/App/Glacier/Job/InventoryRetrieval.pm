package App::Glacier::Job::InventoryRetrieval;
use strict;
use warnings;

use parent qw(App::Glacier::Job);
use App::Glacier::Core;
use Carp;

# new(CMD, VAULT)
sub new {
    croak "bad number of arguments" unless $#_ >= 2;
    my ($class, $cmd, $vault, %opts) = @_;
    return $class->SUPER::new(
	$cmd, $vault, $vault,
	ttl => $cmd->cfget(qw(database inv ttl)),
	%opts);
}

sub init {
    my $self = shift;
    my $jid = $self->glacier->Initiate_inventory_retrieval(
		          $self->vault,
		          'JSON',
		          "Inventory retrieval for vault ".$self->vault
              );
    if ($self->glacier->lasterr) {
	if ($self->glacier->lasterr('code') == 404) {
	    $self->command->abend(EX_TEMPFAIL,
				  $self->glacier->last_error_message
				  . "\n"
				  . "Try again later or use the --cached option to see the cached content.")
	} else {
	    $self->command->abend(EX_FAILURE,
				  "can't create job: ",
				  $self->glacier->lasterr('code'),
				  $self->glacier->last_error_message);
	}
    }
    return $jid;
}

1;

