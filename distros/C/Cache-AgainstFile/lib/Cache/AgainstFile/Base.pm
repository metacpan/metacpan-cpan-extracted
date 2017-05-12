###############################################################################
# Purpose : Base class for default Cache::AgainstFile implementations
# Author  : John Alden
# Created : 24th April 2004
# CVS     : $Id: Base.pm,v 1.8 2005/06/03 14:29:55 johna Exp $
###############################################################################

package Cache::AgainstFile::Base;

use strict;
use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.8 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($class, $loader, $options) = @_;
	
	my $self = {
		'loader' => $loader,
		'options' => $options,
	};

	TRACE("Cache: Stat disabled") if($self->{options}->{NoStat});
	return bless $self, $class;
}

sub purge {
	my($self, $all) = @_;
	my @keys;
	my $accessed = $self->_accessed();
	if($all)
	{
		TRACE("Purging all keys in cache");
		@keys = keys %$accessed;
	}
	else
	{
		#Identify items to delete
		if($self->{options}->{NoStat})
		{
			TRACE("purging stale items");
			push @keys, $self->_stale(); #Stale items
		}
		if(defined $self->{options}->{MaxATime})
		{
			my $max = $self->{options}->{MaxATime}; #seconds
			TRACE("purging files older than $max");
			DUMP($accessed);
			push @keys, grep {time - $accessed->{$_} > $max} keys %$accessed; #Inactive items
		}
		if($self->{options}->{MaxItems})
		{
			my $max = $self->{options}->{MaxItems};
			TRACE("keeping $max youngest files");
			my @agelist = sort {$accessed->{$a} <=> $accessed->{$b}} keys %$accessed; #sort by age
			while(scalar(@agelist) > $max)
			{
				push @keys, shift @agelist; #keys of the oldest ones
			}
		}
		
		#Remove duplicates
		my %unique = map {$_ => undef} @keys;
		@keys = keys %unique;
	}
	DUMP("keys to purge", \@keys);
	$self->_remove(\@keys) if(@keys);
}

sub clear {
	my $self = shift;
	return $self->purge(1);
}

sub TRACE {}
sub DUMP {}

=head1 NAME

Cache::AgainstFile::Base - base class for default backends

=head1 SYNOPSIS

 package Cache::AgainstFile::MyBackend;

 use Cache::AgainstFile::Base;
 @ISA = qw(Cache::AgainstFile::Base);
 
 ...implement methods...

 1;


=head1 DESCRIPTION

This provides a default implementation for purging the cache, based on a list of stale files
and a hashref of access times.

Classes inheriting from this base class should provide the following public methods:

=over 4

=item $b = new Cache::AgainstFile::MyBackend(\&loader, \%options)

This should call the base class constructor.

=item $data = $b->get($filename, @opts)

Fetch an item from the cache.  
@opts should be passed after the filename to the loader coderef.

=item $n = $b->count()

Number of items in the cache

=item $bytes = $b->size()

Total size of the cache in bytes

=back

They should also provide the following protected methods which are used to support purge():

=over 4

=item $b->_remove(\@filenames)

Remove a number of items from the cache

=item $hashref = $b->_accessed()

A hashref of filename => access time

=item @filenames = $b->_stale()

A list of cache items which are stale with respect to their original files

=back

=head1 OPTIONS

The implementation of purge() supports the options:

=over 4

=item NoStat

=item MaxItems

=item MaxATime

=back

=head1 VERSION

$Revision: 1.8 $ on $Date: 2005/06/03 14:29:55 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
