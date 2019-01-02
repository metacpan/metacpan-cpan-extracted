package App::Glacier::Job::ArchiveRetrieval;
use strict;
use warnings;

use parent qw(App::Glacier::Job);
use App::Glacier::Core;
use Carp;

# new(CMD, VAULT, ARCHIVE[, description => DESCR, OPTS...])
sub new {
    croak "bad number of arguments" if $#_ < 3;
    my ($class, $cmd, $vault, $archive, %opts) = @_;
    my $descr = delete $opts{description};
    my $self = $class->SUPER::new(
	$cmd,
	$vault,
	$vault . ':' . $archive,
	%opts
	);
    $self->{_archive} = $archive;
    $self->{_descr} = $descr;
    return $self;
}

sub init {
    my $self = shift;
    my $jid = $self->glacier->Initiate_archive_retrieval($self->vault,
			  			         $self->{_archive},
						         $self->{_descr});
    if ($self->glacier->lasterr) {
	if ($self->glacier->lasterr('code') == 404) {
	    $self->command->abend(EX_TEMPFAIL,
				  $self->glacier->last_error_message
				  . "\n"
				  . "Try again later or use the --cached option to see the cached content.")
	} else {
	    $self->command->abend(EX_FAILURE,
				  "can't create job: ",
				  $self->command->lasterr('code'),
				  $self->command->last_error_message);
	}
    }
    return $jid;
}

1;
