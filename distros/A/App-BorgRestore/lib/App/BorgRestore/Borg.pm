package App::BorgRestore::Borg;
use v5.14;
use warnings;
use strict;

use App::BorgRestore::Helper;

use autodie;
use Function::Parameters;
use IPC::Run qw(run start new_chunker);
use Log::Any qw($log);

=encoding utf-8

=head1 NAME

App::BorgRestore::Borg - Borg abstraction

=head1 DESCRIPTION

App::BorgRestore::Borg abstracts borg commands used by L<App::BorgRestore>.

=cut

method new($class: $borg_repo) {
	my $self = {};
	bless $self, $class;

	$self->{borg_repo} = $borg_repo;

	return $self;
}

method borg_list() {
	my @archives;

	$log->debug("Getting archive list");
	run [qw(borg list), $self->{borg_repo}], '>', \my $output or die "borg list returned $?";

	for (split/^/, $output) {
		if (m/^([^\s]+)\s/) {
			push @archives, $1;
		}
	}

	return \@archives;
}

method borg_list_time() {
	my @archives;

	$log->debug("Getting archive list");
	run [qw(borg list), $self->{borg_repo}], '>', \my $output or die "borg list returned $?";

	for (split/^/, $output) {
		if (m/^([^\s]+)\s+(.+)$/) {
			my $time = App::BorgRestore::Helper::parse_borg_time($2);
			if ($time) {
				push @archives, {
					"archive" => $1,
					"modification_time" => $time,
				};
			}
		}
	}

	return \@archives;
}

method restore($components_to_strip, $archive_name, $path) {
	$log->debugf("Restoring '%s' from archive %s, stripping %d components of the path", $path, $archive_name, $components_to_strip);
	system(qw(borg extract -v --strip-components), $components_to_strip, $self->{borg_repo}."::".$archive_name, $path);
}

method list_archive($archive, $cb) {
	$log->debugf("Fetching file list for archive %s", $archive);
	open (my $fh, '-|', 'borg', qw/list --list-format/, '{isomtime} {path}{NEWLINE}', $self->{borg_repo}."::".$archive);
	while (<$fh>) {
		$cb->($_);
	}

	# this is slow
	#return start [qw(borg list --list-format), '{isomtime} {path}{NEWLINE}', "::".$archive], ">", new_chunker, $cb;
	#$proc->finish() or die "borg list returned $?";
}

1;

__END__
