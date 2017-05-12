package App::Prove::Watch;
$App::Prove::Watch::VERSION = '0.3';

use strict;
use warnings;

use App::Prove;
use Filesys::Notify::Simple;
use File::Basename;
use Getopt::Long qw(GetOptionsFromArray);


=head1 NAME

App::Prove::Watch - Run tests whenever changes occur.

=head1 VERSION

version 0.3

=head1 SYNOPSIS

	$ provewatcher 

=head1 DESCRIPTION

Watches for changes in the current directroy tree and runs prove when there are
changes.

=head1 ARGUMENTS

C<provwatcher> takes all the arguments that C<prove> takes with two additions:

=head2 --watch

Specifies what directories should be watched:

	# just watch lib
	$ provewatcher --watch lib
	
	# watch lib and t
	$ provewatcher --watch lib --watch t
	
This defaults to C<.> if not given.

=head2 --run

Allows you to run something other than prove when changes happen. For example if
you where using L<Dist::Zilla>

	$ provewatcher --run 'dzil test'
	
=head1 NOTIFICATIONS

If you install L<Log::Dispatch::DesktopNotification>, desktop notifications will
be sent whenever the overall state of the tests change (failing to passing or
passing to failing).

L<Log::Dispatch::DesktopNotification> is not listed as a prereq for this module,
it will not be installed by default when you install this module.

=cut

sub new {
	my $class = shift;
	my ($args, $prove_args) = $class->_split_args(@_);
	

	my $watcher      = Filesys::Notify::Simple->new($args->{watch});
	my $prove        = $class->_get_prove_sub($args, $prove_args);

	return bless {
		watcher => $watcher,
		prove   => $prove,
		args    => $args,
	}, $class;
}

sub prove   { return $_[0]->{prove}->() }
sub watcher { 
	my $self = shift;
	
	if (@_) {
		$self->{watcher} = shift;
	}
	
	return $self->{watcher};
}


sub run {
	my ($self, $count) = @_;
	
	$self->prove;

	$count ||= -1;
	while ($count != 0) {
		$self->watcher->wait(sub {
			my $doit;
			FILE: foreach my $event (@_) {
				my $file = basename($event->{path});
				next FILE if $file =~ m/^(?:\.[~#])/;
				
				if ($self->{args}{ignore}) {
					next FILE if $file =~ $self->{args}{ignore};
				}
				
				$doit++;
				
			}
			
			if ($doit) {
				$self->prove();
				$count--;
			}
		});
	}
}


sub _split_args {
	my ($class, @args) = @_;
	
	my (@ours, @theirs);
	
	while (@args) {
		local $_ = shift @args;
		if ($_ eq '--watch' || $_ eq '--run' || $_ eq '--ignore') {
			push(@ours, $_, shift @args);
		}
		else {
			push(@theirs, $_);
		}
	}
	
	my %ours;
	GetOptionsFromArray(\@ours, \%ours,
		'watch=s@',
		'run=s',
		'ignore=s@',
	);
	
	if (!$ours{watch} || !@{$ours{watch}}) {
		$ours{watch} = ['.']
	}
	
	if ($ours{ignore}) {
		my $merged = join('|', map { qr/$_/ } @{$ours{ignore}});
		$ours{ignore} = qr/$merged/;
	}
	
	return (\%ours, \@theirs);
}

sub _get_prove_sub {
	my ($class, $args, $prove_args) = @_;
	
	my $handle_alert = $class->_get_notification_sub;
	
	my $last;
	my $prove;
	
	if ($args->{run}) {
		if (ref $args->{run}) {
			$prove = $args->{run};
		}
		else {
			$prove = sub {
				my $ret = system($args->{run});
				
				return $ret == 0 ? 1 : 0;
			};
		}
	}
	else {
		$prove = sub {
			my $app = App::Prove->new;
			
			$app->process_args(@$prove_args);
			
			return $app->run ? 1 : 0;
		};
	}
	
	return sub {
		my $ret = $prove->();
		
		if (defined $last && $ret != $last) {
			my $msg;
			if ($ret) {
				$msg = "Tests are now passing.";
			}
			else {
				$msg = "Tests are now failing.";
			}
			
			$handle_alert->($msg);
		}
		$last = $ret;
		
		return $ret;
	};
}


sub _get_notification_sub {
	my $has_desk_note = eval {
		require Log::Dispatch::DesktopNotification;
	};
	
	if ($has_desk_note) {
		my $notify = Log::Dispatch::DesktopNotification->new(
			name      => 'notify',
			min_level => 'notice',
			app_name  => 'provewatcher',
		);
		
		return sub {
			$notify->log(
				level   => 'notice',
				message => shift,
			);
		}
	}
	else {
		return sub {};
	}
}

=head1 TODO

=over 2

=item *

Ironically, for a TDD tool, there's not enough tests.

=back

=head1 AUTHORS

    Chris Reinhardt
    crein@cpan.org
    
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Test::Continuous>, L<App::Prove>, perl(1)

=cut
	

1;
