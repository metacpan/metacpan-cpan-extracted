#
# (C) 2015, Snehasis Sinha
#
package Apache::Hadoop::Watcher::Yarn;

use 5.010001;
use strict;
use warnings;
use JSON;

require Apache::Hadoop::Watcher::Base;

our @ISA = qw();
our $VERSION = '0.01';


# Preloaded methods go here.
sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = {
		host    => $args{'host'} || 'localhost',
		qlist   => {
			resourcemanager => {
				port    => 8088,
				baseurl => '/ws/v1/cluster/',
				context => {
					info => 'info', 
					metrics => 'metrics', 
					scheduler => 'scheduler', 
					apps => 'apps', 
					appstatistics => 'appstatistics', 
					nodes => 'nodes',
				},
			},
			nodemanager     => {
				port    => 8042,
				baseurl => '/ws/v1/node/',
				context => {
					info => 'info', 
					apps => 'apps', 
					containers => 'containers',
				},
			},
			appmaster       => {
				port    => 8888,
				baseurl => '/proxy/{appid}/ws/v1/mapreduce/',
				context => {
					info => 'info',
					jobs => 'jobs',
				},
			},
			historyserver   => {
				port    => 19888,
				baseurl => '/ws/v1/history/',
				context => {
					info => 'info',
					jobs => 'mapreduce/jobs', 
				},
			},
		},

		out   => undef,
		debug => $args{'debug'} || 1,
	};
	bless $self, $class;
	return $self;
}

# set context: service, context
sub _mkurl {
	my ($self, %opts) = (@_);
	my $url;

	$url = 'http://'.$self->{'host'}.
	    ':'.$self->{'qlist'}->{$opts{'service'}}->{'port'}.
		$self->{'qlist'}->{$opts{'service'}}->{'baseurl'}.
		$self->{'qlist'}->{$opts{'service'}}->{'context'}->{$opts{'context'}};
	return $url;
}

# dumps output hashref
sub print {
	my ($self) = (@_);
	Apache::Hadoop::Watcher::Base->new->_print ( output=>$self->{'out'} );
}

# returns list of services
sub options {
	my ($self, %opts) = (@_);
	$self->{'out'} = (defined $opts{'service'}) 
		? $self->{'qlist'}->{$opts{'service'}}->{'context'}
		: $self->{'qlist'};
	return $self;
}

# returns output hashref
sub get {
	my ($self) = (@_);
	return $self->{'out'};
}

# check valid service, context and appid as applicable
sub _isvalid {
	my ($self, %opts) = (@_);
	unless (defined $self->{'qlist'}->{$opts{'service'}}->{'context'}->{$opts{'context'}}) {
		my $error = "invalid service or context!";
		$self->{'out'} = $error;
		#print $error,"\n" if $self->{'debug'};
		return undef;
	}
	return 1;
}

sub request {
	my ($self, %opts) = (@_);
	my $base = Apache::Hadoop::Watcher::Base->new;

	# check validity
	return $self unless defined $self->_isvalid (%opts);

	# construct url
	my $url  = $self->_mkurl (
		service=>$opts{'service'}, 
		context=>$opts{'context'},
		appid  =>$opts{'appid'},
	);

	# appid for appmaster
	if ( $opts{'service'} eq 'appmaster' ) {
		$url =~ s/{appid}/$opts{'appid'}/g;
	}

	# print url
	print $url,"\n" if $self->{'debug'};

	# actual work
	$self->{'out'} = (decode_json $base->_wget (url=>$url)); #->{'nodeInfo'};
	$base->_jsontr ( $self->{'out'} );
	return $self;
}

1;

__END__

=head1 NAME

Apache::Hadoop::Watcher::Yarn - extracts Hadoop Yarn runtime information

=head1 SYNOPSIS

  use Apache::Hadoop::Watcher;
  
  my $w = Apache::Hadoop::Watcher::Yarn->new;
  $w->request(service=>'nodemanager', context=>'info')->print;

=head1 DESCRIPTION

  There are 4 services and a list of contexts for each service. This
  provide information about hosts, cluster, jobs and tasks from Yarn.
  The services are 

  	foreach my $service (keys %{$w->options->get}) {
		print $service,"\n";
	}

  The context options for a service can be listed as below:

  	my $service='nodemanager';
	foreach my $context (keys %{$w->options(service=>$service)->get}) {
		print $context,"\n";
	}

  For the entire query list dump:

	$w->options->print;

  

=head1 SEE ALSO

Apache::Hadoop::Watcher
Apache::Hadoop::Watcher::Base
Apache::Hadoop::Watcher::Conf
Apache::Hadoop::Watcher::Jmx


=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
