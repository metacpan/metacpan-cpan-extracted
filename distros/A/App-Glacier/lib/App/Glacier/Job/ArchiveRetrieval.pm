package App::Glacier::Job::ArchiveRetrieval;
use strict;
use warnings;

require App::Glacier::Job;
use parent qw(App::Glacier::Job);
use Carp;

# new(CMD, VAULT, ARCHIVE[, description => DESCR, OPTS...])
sub new {
    croak "bad number of arguments" if $#_ < 3;
    my ($class, $cmd, $vault, $archive, %opts) = @_;
    my $descr = delete $opts{description};
    return $class->SUPER::new(
	$cmd,
	$vault,
	$vault . ':' . $archive,
	[ 'initiate_archive_retrieval', $vault, $archive, $descr ],
	%opts
    );
}
