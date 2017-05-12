package Catalyst::Plugin::AutoRestart;

# The same accessor that Catalyst core uses
use Moose;
with qw/Catalyst::ClassData/;
use MRO::Compat;
use Text::SimpleTable;
use Proc::ProcessTable;

__PACKAGE__->mk_classdata(qw/_autorestart_state/);

our $VERSION = '0.96';

=head1 NAME

Catalyst::Plugin::AutoRestart - Catalyst plugin to restart server 
processes when specified memory threshold is reached 

=head1 SYNOPSIS

use Catalyst qw/AutoRestart/;

 __PACKAGE__->config->{Plugin::AutoRestart} = {
	active => '1',
	check_each => '20',
	max_bits => 576716800,
	min_handled_requests => '150',
        size_field => 'size', # or any other field supported by
                              # Proc::ProcessTable::Process
        restart => 'exit', # alternative is kill for a more graceful restart
 }

 <Plugin::AutoRestart>
    active   1
    check_each   20
    max_bits  576716800
    min_handled_requests   150
    restart exit
 </Plugin::AutoRestart>

=head1 DESCRIPTION

Catalyst plugin to force the application to restart server processes when they reach 
a configurable memory threshold. Memory checks are performed every 'N' requests.  This is 
intended as a band-aid to deal with problems like memory leaks; it's here to buy you 
time to find and solve the underlying issues.

=head1 CONFIGURATION

=head2 active 

This is used to turn the plugin on and off 

=head2 check_each 

This is the number of requests to wait between checks 

=head2 min_handled_requests

Minimum application requests before process size check starts occurring. 
This is to prevent your application processes from exiting immediately in 
case your application is bigger than your max_bits limit.  

The default is 500 requests

=head2 max_bits

This is the size virtual memory can grow to before triggering a restart

The default is 524288000 bits (500 mb)

=head2 size_field

Which size field to measure. Defaults to C<size>. Other values are anything
that L<Proc::ProcessTable::Process> has an accessor for, which depends on your
OS. Most people will want C<size> (virtual memory size) or C<rss>
(resident set size)

=head1 SEE ALSO

For trying to solve memory leaks see L<Devel::Leak::Object>

=head1 EXTENDED METHODS

The following methods are extended from the main Catalyst application class.

=head2 setup

Create sane defaults

=cut

sub setup {
	my $c = shift @_;
	my $config = $c->config->{'Plugin::AutoRestart'} || {};

	$c->_autorestart_state( {
		_process_table => Proc::ProcessTable->new,
		max_bits => 524288000,
		min_handled_requests => 500,
		size_field => 'size',
                restart => 'exit',
		%$config
	} );

	return $c->next::method(@_)
}

=head2 handle_request

Count each handled request and when a threshold is met, restart.

=cut

sub handle_request {
	my ($c, @args) = (shift,  @_); 
	my $ret = $c->next::method(@args);
	my $state = $c->_autorestart_state;
	    
	return $ret
	 unless $state->{active};
	 
	my $check_each = $state->{check_each};
     
	if( ($Catalyst::COUNT >= $state->{min_handled_requests}) && ($Catalyst::COUNT % $check_each) == 0 ) {
		$c->log->debug('Checking Memory Size.');

		my $size = $c->_debug_process_table($c);
		
		$c->log->debug("Found size is $size");
		
		if(defined $size && $size > $state->{max_bits} ) {
			# this wont output to log since it exits unless
			# $config->{restart} is set to 'kill'
			$c->log->warn("$size is bigger than: ".$state->{max_bits}. " exiting now...");
			$c->log->_flush if $c->log->can("_flush");
                        if ($state->{restart} eq 'exit') {
                            exit(0);
                        }
                        elsif ($state->{restart} eq 'kill') {
                            kill 'HUP', $$;
                        }
		}
		$c->log->_flush if $c->log->can("_flush");
	}
	return $ret;
}


=head2 _debug_process_table

Send to the log the full running process table and return the size of the 
process

=cut

sub _debug_process_table {
	my ($c) = @_;
	my $state = $c->_autorestart_state;
	
	foreach my $p ( @{$state->{_process_table}->table} ) {
		next
		 unless $p->pid == $$;
		 
		my $table = new Text::SimpleTable( [ 6, 'PID' ], [ 12, 'VIRT' ], [ 12, 'RES' ], [ 15, 'COMMAND' ] );
		$table->row($p->pid, $p->size, $p->rss, $p->cmndline);
		$c->log->debug("Process Info:\n" . $table->draw);
		
		my $fld = $state->{size_field};
		return $p->$fld;
	}
	return 0;
}


=head1 AUTHORS

 John Napiorkowski <john.napiorkowski@takkle.com>
 John Goulah       <jgoulah@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
