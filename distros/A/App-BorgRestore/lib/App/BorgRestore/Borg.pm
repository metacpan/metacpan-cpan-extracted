package App::BorgRestore::Borg;
use v5.14;
use strictures 2;

use App::BorgRestore::Helper qw(untaint);

use autodie;
use Date::Parse;
use Function::Parameters;
use IPC::Run qw(run start new_chunker);
use JSON;
use Log::Any qw($log);
use Version::Compare;

=encoding utf-8

=head1 NAME

App::BorgRestore::Borg - Borg abstraction

=head1 DESCRIPTION

App::BorgRestore::Borg abstracts borg commands used by L<App::BorgRestore>.

=cut

method new($class: $borg_repo, $backup_prefix) {
	my $self = {};
	bless $self, $class;

	$self->{borg_repo} = $borg_repo;
	$self->{backup_prefix} = $backup_prefix;

	$self->{borg_version} = $self->borg_version();

	return $self;
}

=head3 borg_version

Return the version of borg.

=cut

method borg_version() {
	run [qw(borg --version)], ">", \my $output or die $log->error("Failed to determined borg version")."\n";
	if ($output =~ m/^.* ([0-9.a-z]+)$/) {
		return $1;
	}
	die $log->error("Unable to extract borg version from borg --version output")."\n";
}


method borg_list() {
	my @archives;
	my $backup_prefix = $self->{backup_prefix};

	if (Version::Compare::version_compare($self->{borg_version}, "1.1") >= 0) {
		$log->debug("Getting archive list via json");
		run [qw(borg list --prefix), $backup_prefix, qw(--json), $self->{borg_repo}], '>', \my $output or die $log->error("borg list returned $?")."\n";
		my $json = decode_json($output);
		for my $archive (@{$json->{archives}}) {
			push @archives, $archive->{archive};
		}
	} else {
		$log->debug("Getting archive list");
		run [qw(borg list --prefix), $backup_prefix, $self->{borg_repo}], '>', \my $output or die $log->error("borg list returned $?")."\n";

		for (split/^/, $output) {
			if (m/^([^\s]+)\s/) {
				push @archives, $1;
			}
		}
	}

	$log->warning("No archives detected in borg output. Either you have no backups or this is a bug") if @archives == 0;

	return \@archives;
}

method borg_list_time() {
	my @archives;

	if (Version::Compare::version_compare($self->{borg_version}, "1.1") >= 0) {
		$log->debug("Getting archive list via json");
		run [qw(borg list --json), $self->{borg_repo}], '>', \my $output or die $log->error("borg list returned $?")."\n";
		my $json = decode_json($output);
		for my $archive (@{$json->{archives}}) {
			push @archives, {
				"archive" => $archive->{archive},
				"modification_time" => str2time($archive->{time}),
			};
		}
	} else {
		$log->debug("Getting archive list");
		run [qw(borg list), $self->{borg_repo}], '>', \my $output or die $log->error("borg list returned $?")."\n";

		for (split/^/, $output) {
			# example timestamp: "Wed, 2016-01-27 10:31:59" = 24 chars
			if (m/^([^\s]+)\s+(.{24})/) {
				my $time = App::BorgRestore::Helper::parse_borg_time($2);
				if ($time) {
					push @archives, {
						"archive" => $1,
						"modification_time" => $time,
					};
				}
			}
		}
	}

	$log->warning("No archives detected in borg output. Either you have no backups or this is a bug") if @archives == 0;

	return \@archives;
}

method restore($components_to_strip, $archive_name, $path) {
	$log->debugf("Restoring '%s' from archive %s, stripping %d components of the path", $path, $archive_name, $components_to_strip);
	$archive_name = untaint($archive_name, qr(.*));
	system(qw(borg extract -v --strip-components), $components_to_strip, $self->{borg_repo}."::".$archive_name, $path);
}

method list_archive($archive, $cb) {
	$log->debugf("Fetching file list for archive %s", $archive);
	my $fh;

	if (Version::Compare::version_compare($self->{borg_version}, "1.1") >= 0) {
		open ($fh, '-|', 'borg', qw/list --format/, '{mtime} {path}{NEWLINE}', $self->{borg_repo}."::".$archive);
	} else {
		open ($fh, '-|', 'borg', qw/list --list-format/, '{isomtime} {path}{NEWLINE}', $self->{borg_repo}."::".$archive);
	}

	while (<$fh>) {
		$cb->($_);
	}

	# this is slow
	#return start [qw(borg list --list-format), '{isomtime} {path}{NEWLINE}', "::".$archive], ">", new_chunker, $cb;
	#$proc->finish() or die "borg list returned $?";
}

1;

__END__
