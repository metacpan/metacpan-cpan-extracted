###############################################################################
# Purpose : Cache data structures against a file
# Author  : John Alden
# Created : 22 Apr 2005 (based on IFL::FileCache)
# CVS     : $Id: AgainstFile.pm,v 1.16 2006/05/09 09:04:29 mattheww Exp $
###############################################################################

package Cache::AgainstFile;

use strict;
use Carp;

use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.16 $ =~ /: (\d+)\.(\d+)/;

#
# API
#
sub new
{
	my ($class, $loader, $options) = @_;
	my $usage = "USAGE: $class->new(\&loader, \%options)";
	croak($usage) unless $loader && $options;
	croak($usage . ". Supplied loader is not a code reference") unless ref $loader eq 'CODE';
	croak($usage . ". Supplied options is not a hash reference") unless ref $options eq 'HASH';
		
	#Select backend
	my $method = $options->{Method} || croak("No cache 'Method' option");
	TRACE("Cache: method = $method");

	#Load appropriate backend class on demand
	my $backend_name = (scalar $method =~ /::/? $method : "$class\::$method"); #If no namespace, assume in the Cache::AgainstFile::Backend namespace
	die("Package name '$backend_name' doesn't look valid") unless($backend_name =~ /^[\w:]+$/);
	eval "require $backend_name";
	die("Unable to load $backend_name - $@") if($@);

	#Wire up tracing stubs
	foreach my $stub (qw(TRACE DUMP)) {
		no strict 'refs';
		local $^W = undef;
		*{$backend_name."::".$stub} = \&{$stub};
	}

	my $backend = $backend_name->new($loader, $options);	
	my $self = {
		'loader' => $loader,
		'options' => $options,
		'method' => $method,
		'backend' => $backend,
	};
	bless $self, $class;
}

# Forward the methods to the backend
sub get
{
	my $self = shift;
	croak("File '$_[0]' does not exist") unless(-e $_[0]);
	return $self->{backend}->get(@_);
}

sub purge
{
	my $self = shift;
	return $self->{backend}->purge();
}

sub clear
{
	my $self = shift;
	return $self->{backend}->clear();
}

sub count
{
	my $self = shift;
	return $self->{backend}->count();
}

sub size
{
	my $self = shift;
	return $self->{backend}->size();
}

#Log::Trace stubs
sub TRACE {}
sub DUMP {}

1;

__END__

=head1 NAME

Cache::AgainstFile - Cache data structures parsed from files, watching for updates to the file

=head1 SYNOPSIS

	use Cache::AgainstFile;
	my $cache = new Cache::AgainstFile(\&loader, \%options);
	$cache->get($filename);
	$cache->purge();

	sub loader {
		my $filename = shift;
		my $data_structure = do_really_expensive_parsing($filename);
		return $data_structure;	
	}

=head1 DESCRIPTION

A module that caches a data structure against a filename, statting the file to
determine whether it has changed and needs to be re-parsed.  You supply a routine
to generate the data structure given the filename.

This module is recommended for files which change infrequently but are read often, especially if they are expensive to parse.
Example uses include caching precompiled templates, pre-parsed XML or data files on webservers.

This approach has the advantage over lazy caching (where cache items are not validated for a period of time)
that multiple processes (e.g. modperl daemons) holding a cache will all update at the same time so you will
not get inconsistent results if you request data from different processes.

The module itself is simply a factory for various backend modules (each exposing the same API).
The distribution includes backends for in-memory caching or file caching using Storable, plus
an adaptor to use any modules offering the Cache or Cache::Cache interfaces as the cache implementation.

Data structures are automatically serialised/deserialised by the backend modules
if they are being persisted somewhere other than in memory (e.g. on the filesystem).

=head1 API

The interface is designed to match that of Cache and Cache::Cache:

=over 4

=item new(\&loader, \%options)

 &loader is a subroutine which given a filename, returns a scalar to cache  
 %options can contain:

=over 4
 	
=item Method

Cache implementation (I<required>).  Valid values are:
Memory|Storable|CacheModule|Null or a package name supporting the
Cache::AgainstFile interface.

=item NoStat

Don't stat files to validate the cache - items are served from the cache without checking if the source
files have changed, until they are purged.

Valid values are 0|1 (default=0, i.e. files are statted)

=back
 
Also see the options for the backend associated with C<Method>.

=item get($filename, @options)

Fetches the scalar associated with $filename. 
You may optionally supply a list of other arguments which get passed to the loader routine

=item purge()

Purges stale items from the cache according to the options supplied to the constructor.
Items which are not stale remain in the cache.

=item clear()

Dumps the entire cache (including items which are not stale)

=item count()

Returns the number of items in the cache.  Note that this method (present in the Cache API) 
is an addition to the Cache::Cache API.
 
=item size()

Returns the total size of the cache in bytes
(may return undef if this is not implemented in the backend) 
 
=back

=head1 WARNINGS

If you are caching blessed objects to disk either using the Storable backend
or a filesystem caching module through Cache::AgainstFile::CacheModule, make sure
the code for the class has been compiled into the process you are loading cache items into.
Normally this isn't a problem if you explicitly C<use> the class, but if you are loading
classes at runtime, make sure that the appropriate class is loaded before any objects of that
class are fetched from cache.

Different backends may adopt slightly different rules regarding checking
the source file's mtime. Any approach could be vulnerable to odd conditions
which result in the source file at any given time having more than one
possible set of contents (e.g. multiple nonatomic writes in a second)
or the use of utilities (such as tar) which change contents, then set mtime
to some time in the past. The default behaviour should be pretty resilient
but you may want to pay attention to Locking options if using the Storable
backend.

=head1 SEE ALSO

=over 4

=item L<Cache::AgainstFile::Memory>

In-memory cache.

=item L<Cache::AgainstFile::Storable>

On-disk cache using storable to serialize data structures.

=item L<Cache::AgainstFile::CacheModule>

Modules with the following interfaces can be used as the caching implementation:

=over 4

=item L<Cache::Cache>

a set of modules for lazy caching

=item L<Cache> 

a rewrite of Cache::Cache with extra features such as validation callbacks

=back

=back

=head1 VERSION

$Revision: 1.16 $ on $Date: 2006/05/09 09:04:29 $ by $Author: mattheww $

=head1 AUTHOR

John Alden & Piers Kent <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
