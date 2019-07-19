package Datahub::Factory::Error;

use Datahub::Factory::Sane;

our $VERSION = '1.77';

use Moo;
use namespace::clean;

extends 'Throwable::Error';

with 'Datahub::Factory::Logger';

has message => (is => 'ro', default => sub {""},);

sub BUILD {
    my ($self) = @_;
    my $msg = $self->log_message;
    if ($self->log->is_debug) {
        $msg .= "\n\n" . $self->stack_trace->as_string;
    }
    $self->log->error($msg);
}

sub log_message {
    my ($self) = @_;
    $self->message;
}

package Datahub::Factory::InvalidCondition;

use Moo;
use namespace::clean;

extends 'Datahub::Factory::Error';

package Datahub::Factory::InvalidPipeline;

use Datahub::Factory::Sane;

use Moo;
use namespace::clean;

extends 'Datahub::Factory::Error';

package Datahub::Factory::FixFileNotFound;

use Datahub::Factory::Sane;

use Moo;
use namespace::clean;

extends 'Datahub::Factory::Error';

package Datahub::Factory::ModuleNotFound;

use Datahub::Factory::Sane;

use Moo;
use namespace::clean;

extends 'Datahub::Factory::Error';

1;

__END__

