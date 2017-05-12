package Apache::Wyrd::Bot;
use 5.006;
use strict;
use warnings;
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(slurp_file);
use XML::Dumper;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Bot - Spawn a process and monitor it

=head1 SYNOPSIS

  <BASENAME::Bot basefile="/var/www/watchme" perl="/usr/bin/perl" />

=head1 DESCRIPTION

The Bot Wyrd provides a class of objects which operate in
the background and independent of the apache process, while
being monitored in a browser window.  This is useful for
showing updates to a time-consuming process, such as
building an index or converting a file between different
formats.

Because it uses HTML http-equivalent metadata to trigger the
browser reload, it should always be the outermost Wyrd on an
HTML page.

Bot uses the default UNIX shell and the machine filesystem
to communicate with the apache process.  If another instance
of the 'bot is launched, this will be detected, and the
browser will continue to follow the previous instance.

Unlike other Wyrds, 'Bots have two methods of being invoked.
One is via the shell, using C</path/to/perl -MBOTCLASSNAME
-ego>. This ultimately invokes the C<_work> method. The
other is via the traditional Wyrd route, and creates the
reloading page.

=head2 HTML ATTRIBUTES

=over

=item basefile

(Required, absolute path) The "base" file location for the
'bot to store it's process ID, output, and error log.  These
will be files with this base name plus .pid, .out, and .err
respectively.  They must be readable and writeable by the
apache process.  Note that they do not need to be in a
browser-accessible place on the filesystem.

=item pidfile, errfile, outfile

Absolute pathnames for the files normally derived from
basefile can be specified, if necessary.

=item refresh

How many seconds between browser refreshes.  Default is 2.

=item expire

If the user does not wait for the 'bot to complete and
instead closes the browser window, the previous instance
will not have it's results automatically removed.  This
parameter defines how old the results should be before a
completely new instance is invoked.  The default is 30
seconds, but it shouldn't be much less than this.

=item perl

Absolute path to the perl executeable.  Bot will attempt to
determine this itself, but it is best if it is explicitly
declared.

=item Flags

=over

=item raw

Use when output is not HTML.  Causes the Wyrd to use
E<lt>PREE<gt>E<lt>/PREE<gt> to enclose the output of the
'Bot.

=item reverse

Display the lines of the output file in reverse.

=back

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (hashref) C<params> (void)

Provide a reference to a hash of attribute value pairs to give defaults to
attributes.  The params method is called at runtime, so it has all Wyrd
methods available to it and can be used to pass CGI data to the bot before
launching it as a process.  The spawned bot can access this data by calling
referring to C<$self-E<gt>>{I<E<lt>keynameE<gt>>} or calling a method with
that keyname.

The other use is for creating a base class of 'Bots from which bots that
perform different jobs can be derived.

=cut

sub params {
	return {}
}

=pod

=item (hashref) C<_work> (void)

Perform the actual work of the 'Bot.  Output (what you want
to have appear on the web page) should be sent to STDOUT
(i.e. use plain C<print()>) and errors should be sent to
STDERR (i.e. use plain C<carp()>, C<warn()>, etc.).  Do not
explicitly  exit unless the process must be terminated
irregularly (i.e. using C<die()>, C<exit()>, etc.)

The default C<_work> is to count to 20.

=cut

sub _work {
	my ($self) = @_;
	for (my $i=0; $i < 20; $i++) {
		print "$i<br>\n";
		sleep 2;
	}
}

=pod

=item (void) C<_process_results> (scalar, scalar)


=cut

sub _process_results {
	my ($self, $status, $view) = @_;
	my $status_message = "Unknown";
	$status_message = "Finished" if ($status == 0);
	$status_message = "Working..." if ($status == 1);
	return ($status_message, $view);
}

=pod

=back

=head1 BUGS/CAVEATS

Spawns shells, invokes interpreters.  All security caveats
associated with these actions must be taken into account.

Many reserved methods in addition to C<_format_output>:
C<errfile>, C<expire>, C<go>, C<lib>, C<outfile>, C<params>,
C<perl>, C<pidfile>, C<refresh>, C<template>, C<_cleanup>,
C<_go>, C<_init_params>, C<_message>, C<_prepare>,
C<_process_params>, C<_read_message>, C<_write_message>.

=cut

sub go {
	my ($class) = @_;
	my $self = {};
	bless $self, $class;
	$self->_go;
	exit 0;
}


sub _init_params {
	my ($self) = @_;
	$self->{'message'} = {};
	$self->_data($self->template) unless $self->_data;
	my $params = $self->params;
	$params = {} unless (ref($params) eq 'HASH');
	foreach my $attribute (qw(basefile pidfile errfile outfile refresh expire perl)) {
		#allow html-specified attributes to override builtin defaults
		$params->{$attribute} = $self->{$attribute} || $params->{$attribute};
	}
	$params = $self->_process_params($params);
	map {$self->{$_} = $$params{$_}} keys %$params;
	$self->_message($params);
}

sub _format_output {
	my ($self) = @_;
	$self->_init_params;
	my $running = 0;
	my $start = 1;
	my $view = '';
	my $status = 0;
	my $meta = '';
	if (-f $self->pidfile) {
		my $pid = ${slurp_file($self->pidfile)};
		($pid) = $pid =~ /^(\d+)$/; #untainting
		$running = kill(0, $pid) if ($pid);
		if (not($pid)) {
			$self->_raise_exception("Pidfile " . $self->pidfile . " exists, but can't be read. Cannot continue.");
		} elsif ($running) {
			$self->_info("An instance of this Bot is running.  A new bot will not be launched.");
			$start = 0;
		} else {
			sleep 1;#making sure the other process wasn't just about to remove the file, and we caught it in mid-state
			if (-f $self->pidfile) {
				$self->_error("A stale pidfile was found.  Removing it and continuing... ");
				unlink($self->pidfile) || $self->_raise_exception("Could not remove stale pidfile " . $self->pidfile . ". Cannot continue.");
			}
		}
	}
	if (not($running) and (-f $self->outfile)) {
		my @stat = stat _;
		#warn "$stat[9] -- " . time;
		if ($stat[9] < (time - $self->expire)) {
			$self->_error("Found old results.  Cleaning up.");
			unlink $self->outfile || $self->_raise_exception("Could not remove stale outfile " . $self->outfile);
		} else {
			$start = 0;
		}
	}
	$view = ${slurp_file($self->outfile)} || '';
	$view = join("\n", reverse(split("\n", $view))) if ($self->_flags->reverse);
	$view = "<pre>$view</pre>" unless($self->_flags->raw);
	if ($start) {
		my $lib = '';
		$lib = ' -I' . $self->lib if ($self->lib);
		my $command = '| ' . $self->{'perl'} . $lib . ' -M' . $self->_class_name . q( -e') . $self->_class_name . q(->go');
		#warn $command;
		my $result = open (SPAWN, $command);
		#warn "result was $result";
		my $message = $self->_write_message;
		print SPAWN $message;
		close (SPAWN) || $self->_raise_exception("Failed to send message:\n$message\n to daemon.  It probably died.");
		#$self->_raise_exception("Spawned Bot failed and could not recover") if ($result > 1);
		#$self->_error("Spawned Bot detected another instance and is letting it continue") if ($result == 1);
		$running = 1;
	}
	if ($running) {
		$status = 1;
		$meta = '<meta http-equiv="refresh" content="' . $self->refresh . ';url=' . $self->dbl->req->parsed_uri->unparse . '">'
	}
	($status, $view) = $self->_process_results($status, $view);
	$self->_data($self->_set({status => $status, view => $view, meta => $meta}));
	unlink ($self->outfile) unless($running);

}

sub _process_params {
	my ($self, $params) = @_;
	my $basefile = $params->{'basefile'};
	$self->_raise_exception("basefile is required.  Please supply a value for the key 'basefile' in your initialization hash.") unless ($basefile);
	$self->_raise_exception("basefile requires an absolute pathname") unless ($basefile =~ /^\//);
	$params->{'pidfile'} ||= $basefile . '.pid';
	$params->{'outfile'} ||= $basefile . '.out';
	$params->{'errfile'} ||= $basefile . '.err';
	$params->{'refresh'} ||= 2;
	$params->{'expire'} ||= 30;
	die "expire should never be less than 20 seconds more than the refresh rate" if ($params->{'expire'} - $params->{'refresh'} < 20);
	$params->{'perl'} ||= '/usr/bin/perl';
	unless ($params->{'lib'}) {
		my $testlib = $self->dbl->req->server_root_relative('lib/perl');
		$params->{'lib'} = $testlib if (-d $testlib);
	}
	$self->_raise_exception('Must specify a valid, full-path, httpd-executable perl binary if your binary is not /usr/bin/perl and/or cannot be executed by mod_perl.  Use the "perl" attribute.') unless (-f $params->{'perl'} && -x _);
	my ($pid_directory) = ($params->{'pidfile'} =~ /(.+)\//);
	$self->_raise_exception('Must specify a valid, writable directory location in your pidfile attribute.  Directory given: ' . $pid_directory) unless (-d $pid_directory && -w _);
	$params->{'pid_directory'} = $pid_directory;
	my ($out_directory) = ($params->{'outfile'} =~ /(.+)\//);
	$self->_raise_exception('Must specify a valid, writable directory location in your outfile attribute.  Directory given: ' . $out_directory) unless (-d $out_directory && -w _);
	$params->{'out_directory'} = $out_directory;
	my ($err_directory) = ($params->{'errfile'} =~ /(.+)\//);
	$self->_raise_exception('Must specify a valid, writable directory location in your errfile attribute.  Directory given: ' . $err_directory) unless (-d $err_directory && -w _);
	$params->{'err_directory'} = $err_directory;
	return $params;
}

sub template {
	my ($self) = @_;
	my $template = <<'__VIEW__';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<title>Botwatch</title>
	$:meta
</head>
<body>

<H1>$:status</H1>

$:view

</body>
</html>
__VIEW__
	return $template;
}

sub pidfile {
	my ($self) = @_;
	return $self->{'pidfile'};
}

sub outfile {
	my ($self) = @_;
	return $self->{'outfile'};
}

sub errfile {
	my ($self) = @_;
	return $self->{'errfile'};
}

sub refresh {
	my ($self) = @_;
	return $self->{'refresh'};
}

sub expire {
	my ($self) = @_;
	return $self->{'expire'};
}

sub perl {
	my ($self) = @_;
	return $self->{'perl'};
}

sub lib {
	my ($self) = @_;
	return $self->{'lib'};
}

#These methods are called when the Bot is running as a spawned process

sub _prepare {
	my ($self) = @_;
	open (PID, "> " . $self->pidfile);
	print PID $$;
	close PID;
}

sub _go {
	my ($self) = @_;
	$self->_read_message;
	my $params = $self->_message;
	map {$self->{$_} = $$params{$_}} keys %$params;
	if (-f $self->pidfile) {
		my $pid = ${slurp_file($self->pidfile)};
		my $running = kill(0, $pid);
		if ($pid == 0) {
			warn "Pidfile " . $self->pidfile . " exists, but can't be read. Cannot continue.";
			exit 2;
		} elsif ($running) {
			warn "An instance of this Bot is running.  This instance will not launch a new one.";
			exit 1;
		} else {
			sleep 1;#making sure the other process wasn't just about to remove the file, and we caught it in mid-state
			if (-f $self->pidfile) {
				warn "A stale pidfile was found.  Removing it and continuing... ";
				my $result = unlink $self->pidfile;
				unless ($result) {
					warn "Could not remove stale pidfile " . $self->pidfile . ". Cannot continue.";
					exit 2;
				}
			}
		}
	}
	my $pid = fork();
	exit 0 if ($pid);#exit, leaving the child to do the work
	#I am a child, I last a while.
	open (STDERR, "> " . $self->errfile) || die "Cannot open error file " . $self->errfile;
	open (STDOUT, "> " . $self->outfile) || die "Cannot open output file " . $self->outfile;
	local $\ = "\n";
	local $| = 1;
	$self->_prepare;
	$self->_work;
	$self->_cleanup;
	close (STDOUT);
	close (STDERR);
	exit;
}

sub _read_message {
	my ($self) = @_;
	my $message = '';
	while (my $line = <STDIN>) {
		$message .= $line;
	}
	my $xd = XML::Dumper->new;
	#warn $message;
	my $data = $xd->xml2pl($message);
	$self->_message($data);
}

sub _write_message {
	my ($self) = @_;
	my $message = $self->_message;
	my $xd = XML::Dumper->new;
	my $data = $xd->pl2xml($message);
	return $data;
}

sub _message {
	my ($self, $value) = @_;
	if (scalar(@_) == 2) {
		$self->{'message'} = $value;
	}
	return $self->{'message'};
}

sub _cleanup {
	my ($self) = @_;
	unlink $self->pidfile || die "Can't remove my own pidfile " . $self->pidfile;
	my $log = slurp_file($self->errfile);
	unlink $self->errfile unless ($$log);
	return;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;