package App::Glacier::Command::Periodic;
use strict;
use warnings;
use App::Glacier::Core;
use parent qw(App::Glacier::Command);
use Carp;
use Data::Dumper;
use File::Basename;
use App::Glacier::Job;
use App::Glacier::Command::Get;

=head1 NAME

glacier periodic - periodic cronjob for Glacier

=head1 SYNOPSIS

B<glacier periodic>

=head1 DESCRIPTION

Scans glacier jobs, cleaning up expired and failed ones and finishing
up completed ones. For each completed archive retrieval job, the
target file is downloaded and stored in directory configured by
the B<transfer.download.cachedir> configuration setting (default -
F</var/lib/glacier/cache>). This file will be removed when the
corresponding jobs expires. For each completed inventory retrieval job,
the vault inventory is obtained and stored in the database.

It is recommended to schedule this command for periodic execution in
your crontab, e.g.:

  */4 * * * *  root  glacier periodic

=cut

sub run {
    my $self = shift;

    my $db = $self->jobdb();
    $db->foreach(sub {
	my ($key, $descr, $vault) = @_;

	my $res = $self->check_job($key, $descr, $vault);
	if ($res && $res->{Completed} ne $descr->{Completed}) {
	    $self->debug(2, $res->{StatusCode});
	    if ($res->{Completed} && $res->{StatusCode} eq 'Succeeded') {
		$self->debug(1, "$descr->{JobId}: processing $descr->{Action} for $vault");
		return if $self->dry_run;
		if ($res->{Action} eq 'InventoryRetrieval') {
		    require App::Glacier::Command::Sync;
		    my $sync = clone App::Glacier::Command::Sync($self);
	            $sync->sync($vault);
		} elsif ($res->{Action} eq 'ArchiveRetrieval') {
		    my $job = App::Glacier::Job->fromdb($self, $vault,
						        $key, $res);
		    my $localname = $self->archive_cache_filename($vault,
							     $res->{ArchiveId});
		    $self->touchdir(dirname($localname));

		    my $get = clone App::Glacier::Command::Get($self);
		    $get->option(quiet => 1);
		    $get->download($job, $localname);
	        }
	    }
	    $db->store($key, $res);
	}
		 });
}

1;

     
