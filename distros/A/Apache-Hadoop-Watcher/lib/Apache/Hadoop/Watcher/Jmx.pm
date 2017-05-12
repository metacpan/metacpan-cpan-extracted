#
# (C) 2015, Snehasis Sinha
#
package Apache::Hadoop::Watcher::Jmx;

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
		jmx   => 'http://'.($args{'host'}||'localhost').':'.($args{'port'}||'50070').'/jmx',
		out   => undef,
		qlist => {
			'java_runtime' => 'java.lang:type=Runtime',
			'java_memory' => 'java.lang:type=Memory',
			'namenode_status' => 'Hadoop:service=NameNode,name=NameNodeStatus',
			'port9000_detailed' => 'Hadoop:service=NameNode,name=RpcDetailedActivityForPort9000',
			'namenode_activity' => 'Hadoop:service=NameNode,name=NameNodeActivity',
			'port9000_activity' => 'Hadoop:service=NameNode,name=RpcActivityForPort9000',
			'namenode_retry_cache' => 'Hadoop:service=NameNode,name=RetryCache.NameNodeRetryCache',
			'ugi_metrics' => 'Hadoop:service=NameNode,name=UgiMetrics',
			'control_metrics' => 'Hadoop:service=NameNode,name=MetricsSystem,sub=Control',
			'jvm_metrics' => 'Hadoop:service=NameNode,name=JvmMetrics',
			'fsname_state' => 'Hadoop:service=NameNode,name=FSNamesystemState',
			'fsname_system' => 'Hadoop:service=NameNode,name=FSNamesystem',
			'startup_progress' => 'Hadoop:service=NameNode,name=StartupProgress',
			'stats_metrics' => 'Hadoop:service=NameNode,name=MetricsSystem,sub=Stats',
			'namenode_info' => 'Hadoop:service=NameNode,name=NameNodeInfo',
		},
	};
	bless $self, $class;
	return $self;
}

# dumps output hashref
sub print {
	my ($self) = (@_);
	Apache::Hadoop::Watcher::Base->new->_print ( output=>$self->{'out'} );
}

# returns list of services
sub list {
	my ($self) = (@_);
	my @servicelist;
	foreach my $href ( @{$self->{'out'}} ) {
		push @servicelist, $href->{'name'};
	}
	return \@servicelist;
}
	
# returns output hashref
sub get {
	my ($self) = (@_);
	return $self->{'out'};
}

sub set {
	my ($self, %opts) = (@_);
}

sub get_system_properties {
	my ($self) = (@_);
	my $href;

	$self->_query (query=>$self->{'qlist'}->{'system_properties'});
	$href = $self->{'out'}->[0]->{'SystemProperties'};
	foreach my $e (sort @{$href}) {
		if ( $e->{'key'} eq 'java.class.path' ) {
			print sprintf "%30s  %s\n", $e->{'key'}, ' ';
			foreach ( split /:/, $e->{'value'} ) {
				print sprintf "%30s  %s\n", ' ', $_;
			}
			next;
		}

		if ( $e->{'key'} eq 'sun.boot.class.path' ) {
			print sprintf "%30s  %s\n", $e->{'key'}, ' ';
			foreach ( split /:/, $e->{'value'} ) {
				print sprintf "%30s  %s\n", ' ', $_;
			}
			next;
		}

		print sprintf "%30s  %s\n", $e->{'key'}, $e->{'value'};
	}
}

# jmx json methods
sub _query {
	my ($self, %opts) = (@_);
	my $base = Apache::Hadoop::Watcher::Base->new;
	my $url = defined $opts{'query'} ? $self->{'jmx'}.'?qry='.$opts{'query'} : $self->{'jmx'};
	$self->{'out'} = (decode_json $base->_wget (url=>$url))->{'beans'};
	#$self->{'out'} = (decode_json $base->_wget (url=>$url));
	$base->_jsonjmx ( $self->{'out'} );
	$self->{'out'} =~ s/\'//g;
}

# request
sub request {
	my ($self, %opts) = (@_);
	my $q = undef;

	$q = $self->{'qlist'}->{$opts{'method'}} if  defined $opts{'method'};
	$q = $opts{'service'} if  defined $opts{'service'};
	$self->_query (query => $q);
	return $self;
}

1;

__END__

=head1 NAME

Apache::Hadoop::Watcher::Jmx - Hadoop JMX extractor

=head1 SYNOPSIS

  use Apache::Hadoop::Watcher::Jmx;
  
  my $w = Apache::Hadoop::Watcher::Jmx->new;
  my $listref = $w->request->list;

  $w->request (service=>'Hadoop:service=NameNode,name=FSNamesystemState')->print;
  $w->request (method =>'system_state')->print;


=head1 DESCRIPTION

This package Apache::Hadoop::Watcher::Jmx connects to JMX webservice
to extract runtime information about the cluster. It connects to namenode
/jmx context.

To list all possible service options:
  
  my $list = $w->request->list;
  foreach ( @{$list} ) { print $_,"\n"; }

For individual service extraction:

  $w->request (service=>'Hadoop:service=NameNode,name=FSNamesystemState')->print;

Or, by method name, such as 'system_state':

  $w->request (method =>'system_state')->print;

Methods can be customized using add subroutine:

  $w->add (method=>'system_memory', service=>

=head1 SEE ALSO

  Apache::Hadoop::Watcher
  Apache::Hadoop::Watcher::Base
  JSON

=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
