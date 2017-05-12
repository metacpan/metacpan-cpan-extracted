###############################################################################
# Purpose : Cache::AgainstFile wrapper for CPAN caching modules
# Author  : John Alden
# Created : 25 Apr 2005
# CVS     : $Id: CacheModule.pm,v 1.9 2005/10/31 21:10:41 johna Exp $
###############################################################################

package Cache::AgainstFile::CacheModule;

use strict;
use vars qw($VERSION %StatHistory);
$VERSION = sprintf"%d.%03d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($class, $loader, $options) = @_;
	
	#Load appropriate backend class on demand
	my $backend_name = $options->{CacheModule};
	die("Package name '$backend_name' doesn't look valid") unless($backend_name =~ /^[\w:]+$/);
	eval "require $backend_name";
	die("Unable to load $backend_name - $@") if($@);

	#Wire up tracing stubs
	foreach my $stub qw(TRACE DUMP) {
		no strict 'refs';
		*{$backend_name."::".$stub} = \&{$stub} if(defined &{$backend_name."::".$stub});
	}

	my $backend = $backend_name->new($options->{CacheModuleOptions});
	my $self = {
		'loader' => $loader,
		'options' => $options,
		'backend' => $backend,
		'serialize' => _explicitly_serialize($backend),
		'stat' => \%StatHistory,
	};
	return bless $self, $class;
}

#File statting magic happens here
sub get {
	my ($self, $filename, @opts) = @_;	
	my $record = $self->_get($filename);
	my ($last_modified, $data);
	if(defined $record)
	{
		($last_modified, $data) = @$record;
		unless($self->{options}->{NoStat})
		{
			my $grace = $self->{options}->{Grace} || 0;
			my $last_checked = $self->{'stat'}{$filename} || 0;
	
			#Are we within the grace period since our last stat?
			unless($grace > time - $last_checked)
			{
				TRACE("stat: $filename");
				$data = undef if((stat($filename))[9] > $last_modified); #stat and maybe mark as stale
				$self->{'stat'}{$filename} = time;
			}
		}
	}
	unless(defined $data)
	{
		TRACE("stale: $filename");
		$data = $self->{loader}->($filename, @opts);
		$last_modified = (stat($filename))[9];
		$self->_set($filename, [$last_modified, $data]);
	}
	else
	{
		TRACE("not stale: $filename");
	}
	return $data;	
}

#Forward all other methods to backend
sub purge {
	shift()->{backend}->purge();
}

sub clear {
	shift()->{backend}->clear();
}

sub size {
	shift()->{backend}->size();
}

# Allow for slight difference in count functionality between Cache::Cache and Cache APIs
sub count {
	my $backend = shift()->{backend};
	
	#Cache:: module have a count() method
	return $backend->count() if($backend->can('count'));
	
	#Cache::Cache modules currently don't - but they do have a get_keys method
	if($backend->can('get_keys')) {
		my @keys = $backend->get_keys();
		return scalar @keys;
	}
	
	return undef;
}

# Allow for slight difference in serialization between Cache::Cache and Cache APIs
sub _set {
	my $self = shift;
	if($self->{serialize}) {
		my ($k, $v, @args) = @_;
		return $self->{backend}->freeze(@_);
	} else {
		return $self->{backend}->set(@_);
	}
}

sub _get {
	my $self = shift;
	if($self->{serialize}) {
		return $self->{backend}->thaw(@_);
	} else {
		return $self->{backend}->get(@_);		
	}	
}

sub _explicitly_serialize {
	my ($backend) = @_;
	return 1 if($backend->isa('Cache'));
	return 0;
}

#Log::Trace stubs
sub TRACE {}
sub DUMP{}

1;

=head1 NAME

Cache::AgainstFile::CacheModule - use Cache or Cache::Cache modules for Cache::AgainstFile

=head1 SYNOPSIS

	use Cache::AgainstFile;
	my $cache = new Cache::AgainstFile(
		\&loader, 
		{
			Method => 'CacheModule',
			CacheModule => 'Cache::MemoryCache', #This will be loaded on demand
			CacheModuleOptions => {'default_expires_in' => 300},
			# ...
		}
	);

	$data = $cache->get($filename);


=head1 DESCRIPTION

This backend allows you to apply Cache::AgainstFile to any of the modules on CPAN that conform to the Cache::Cache or Cache interfaces.  Data structures are automatically serialised into the cache.

=head1 OPTIONS

=over 4

=item CacheModule

The module to use for the cache implementation (e.g. Cache::MemoryCache)

=item CacheModuleOptions

A hashref of options to pass to the cache module's constructor

=item Grace

How long to defer statting the file (in seconds).
This option is only any use with memory caches for two reasons:  

First, for filesystem caches, the cost of fetching an item from the cache far exceeds the cost of statting a file.  

Second, unlike the file modification time which is stored within the cache itself, the history of 
when files were last statted is held in memory, so that the cache does not need to be reserialised on 
each stat.  Therefore the stat history is not shared between processes.

Be careful if you use this in modperl environments as it will result in some children having a
new version of the cached item, and some still having the old version.

=item NoStat

Don't stat files to validate the cache - items are served from the cache until they are purged.
Valid values are 0|1 (default=0, i.e. files are statted)

Setting this to 1 is equivalent to setting Grace to an infinite value.

=back

=head1 VERSION

$Revision: 1.9 $ on $Date: 2005/10/31 21:10:41 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
