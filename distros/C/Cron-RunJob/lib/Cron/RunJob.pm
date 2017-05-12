package Cron::RunJob;

use 5.014002;
use strict;
use warnings;
use vars qw($AUTOLOAD);
use Scalar::Util 'refaddr';
use Mail::Mailer;
use IO::Select;
use IO::File;
use IPC::Open3;
use POSIX ":sys_wait_h";
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '0.06';

my ($job_pid, %_data);
$SIG{TERM} = $SIG{INT} = sub {
	kill 9, $job_pid if $job_pid;
	exit;
};

sub new {
	my ($self, %opt) = @_;
	$self = bless {}, $self;
	$_data{refaddr $self}{uc $_} = $opt{$_} 
        	for keys %opt; 
	return $self;
}

sub runfile_name {
	my ($self, $cmd) = @_;
	$cmd =~ s/.*\///;
	my $dir = $self->runfile_dir || '/var/run';
	return $dir .'/'. $cmd . ".pid";
}

sub create_runfile {
	my ($self, $runfile) = @_;
	my $fh = new IO::File;
	$fh->open("> $runfile");
	die $! unless defined $fh;
	print $fh $self->pid;
	$fh->close;
}

sub unlink_runfile {
	my ($self, $runfile) = @_;
	if (-e $runfile) {
		unlink $runfile or die $!;
	}
}

sub is_running {
	my ($self, $runfile) = @_;
	if (-e $runfile) {
		my $fh = new IO::File;
		die $! unless defined $fh; 
		$fh->open($runfile) or die "Open run file $runfile $!\n";
		my $pid = <$fh>;
		$fh->close;
		return if $pid == $$;
		$self->pid($pid);
		return kill 0, $pid;
	}
	return 0;	
}

sub run {
	my ($self, $cmd, @argv) = @_;
	
	if ($self->only_me and $self->is_running($self->runfile_name($cmd))) {
		$self->stderr("Proccess is already running");
		$self->failed(1);
		return 0;
	}	
	
	my $select = IO::Select->new();
	my $chld_stderr = new IO::File;
	my $chld_stdin = new IO::File;
	my $chld_stdout = new IO::File;

	$job_pid = open3($chld_stdin, $chld_stdout, $chld_stderr, $cmd, @argv);
	$self->pid($job_pid);
	$self->create_runfile($self->runfile_name($cmd)) 
		if $self->only_me;
	
	$select->add($chld_stderr);
	$select->add($chld_stdout);

	my ($buff, $std_error, $std_out);
	foreach my $fh ($select->can_read) {
		while (my $buff = <$fh>) {
			if ($fh == $chld_stderr) {
				$std_error .= $buff;
			} elsif ($fh == $chld_stdout)  {
				$std_out .= $buff;		
			}
		}	
	}

	$chld_stderr->close;
	$chld_stdout->close;
	$chld_stdin->close;
	
	waitpid($job_pid, 0);
	
	if ($std_error) {
		$self->stderr($std_error);
		if ($self->mail_stderr) {
			my $mailer = new Mail::Mailer 'sendmail';
			$mailer->open({
				To => $self->mail_to,
				From => $self->mail_from,
				Subject => 'STDERR: '. $self->mail_subject,
			});

			print $mailer "Error: $cmd failed with error(s): ".($std_error ? $std_error:'unknown errors')."\n";
			$mailer->close;
		}
		$self->failed(1);
	} else {
		$self->failed(0);
		$self->stdout($std_out);
		if ($self->mail_stdout) {
			my $mailer = new Mail::Mailer 'sendmail';
			$mailer->open({
				From => $self->mail_from,
				To => $self->mail_to,
				Subject => 'STDOUT: '. $self->mail_subject,
			});
			
			print $mailer $self->stdout;
		}
	}

	$self->unlink_runfile($self->runfile_name($cmd))
		if $self->only_me;
}

sub AUTOLOAD {
	my $self = shift;
	(my $attr = $AUTOLOAD) =~ s/^.*:://;
	if (exists $_data{refaddr $self}->{uc $attr} and $_data{refaddr $self}->{uc $attr}) {
		return $_data{refaddr $self}->{uc $attr};
	} else {
		my $value = shift;
		$_data{refaddr $self}->{uc $attr} = $value if $value;
	}
}

1;
__END__

=head1 NAME

Cron::RunJob - Monitor Cron Jobs

=head1 SYNOPSIS

	use strict;
	use Cron::RunJob;

	my $job = Cron::RunJob->new(
		ONLY_ME => 1,
		MAIL_STDERR => 1,
		MAIL_STDOUT => 1,
		MAIL_TO => 'kielstr@cpan.org',
		MAIL_FROM => 'kielstr@cpan.org',
		MAIL_SUBJECT => 'Cron::RunJob test',
		RUNFILE_DIR => '.'
	);

	$job->run(shift, @ARGV);

	print (($job->failed) ? $job->stderr : $job->stdout);
	
=head1 DESCRIPTION


Run and monitor a command.


=head2 new()

=pod

ONLY_ME

If true only allow one instance of the command.

RUNFILE_DIR

The location to create a run file.

MAIL_STDOUT

If true mail STDOUT to MAIL_TO.

MAIL_STDERR

If true mail STDERR to MAIL_TO.

MAIL_FROM 

The return address for the email.
 
MAIL_SUBJECT 

The subject of the email.

=head2 run(cmd, (args))

Runs the command.

=head2 failed()

Returns true if the command failed.

=head2 stderr()

Returns STDERR of the command. 

=head2 stdout()

Returns STDOUT of the command.

=head1 AUTHOR

Kiel R Stirling, E<lt>kielstr@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kiel R Stirling

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
