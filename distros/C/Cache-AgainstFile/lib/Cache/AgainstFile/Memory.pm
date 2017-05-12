###############################################################################
# Purpose : Cache data structures in memory against a file 
# Author  : John Alden
# Created : 22 Apr 2005 (based on IFL::FileCache)
# CVS     : $Id: Memory.pm,v 1.15 2005/11/10 15:13:57 johna Exp $
###############################################################################

package Cache::AgainstFile::Memory;

use strict;
use Cache::AgainstFile::Base;

use vars qw($VERSION @ISA);
$VERSION = sprintf"%d.%03d", q$Revision: 1.15 $ =~ /: (\d+)\.(\d+)/;
@ISA = qw(Cache::AgainstFile::Base);

use constant HAVE_FILE_POLICY => eval {
	require File::Policy; 
	import File::Policy qw(check_safe);
	1;
};


#
# Public interface
#

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->{'cache'} = {};	
	$self->{'modified'} = {};	#Time file was last modified (days ago)
	$self->{'accessed'} = {};	#Time file was last accessed (days ago)
	$self->{'stat'} = {};	    #Timestamp of last stat (seconds since epoch)

	return $self;
}

sub get {
	my ($self, $filename, @opts) = @_;	
	my $stale = (! exists $self->{cache}{$filename});
	my $source_mtime;
	unless ($self->{options}->{NoStat} && !$stale)
	{
		#Are we within the grace period since our last stat?
		my $grace = $self->{options}->{Grace} || 0;
		my $last_checked = $self->{'stat'}{$filename} || 0;
		unless($grace > time - $last_checked)
		{
			TRACE("stat: $filename");
			check_safe($filename, "r") if(HAVE_FILE_POLICY);
			$source_mtime = (stat($filename))[9];
			my $last_modified = $self->{modified}{$filename};
			$stale |= (!defined $source_mtime) || (!defined $last_modified) || ($source_mtime ne $last_modified);
			$self->{'stat'}{$filename} = time;
		}
	}
	my $data;
	if($stale)
	{
		TRACE("stale memory: $filename");
		$data = $self->{loader}->($filename, @opts);
		if (defined $source_mtime) {
			$self->{cache}{$filename} = $data;
			$self->{modified}{$filename} = $source_mtime;
		}
	}
	else
	{
		TRACE("not stale memory: $filename");
		$data = $self->{cache}{$filename};
	}
	$self->{accessed}{$filename} = time();
	return $data;
}

sub count {
	my $self = shift();
	return scalar keys %{$self->{cache}};
}

sub size {
	my $self = shift();
	eval {
		no warnings;
		require Devel::Size;
		local $Devel::Size::warn = 0;
		return Devel::Size::total_size($self->{cache});
	};
	return undef;
}

#
# Protected methods referenced from Base class
#

sub _remove {
	my($self, $keys) = @_;
	foreach(@$keys)
	{
		TRACE("clearing $_");
		delete $self->{cache}{$_};	
		delete $self->{modified}{$_};	
		delete $self->{accessed}{$_};	
		delete $self->{'stat'}{$_};	
	}
}

sub _accessed {
	my($self) = @_;
	my %atimes = %{$self->{accessed}};
	return \%atimes;
}

sub _stale {
	my($self) = @_;
	my $modified = $self->{modified};
	return grep { 
		my $src = (stat($_))[9];
		(!defined $src) || ($src ne $modified->{$_})
	} keys %$modified;
}

#
# Log::Trace stubs
#

sub TRACE {}
sub DUMP {}

1;


=head1 NAME

Cache::AgainstFile::Memory - cache data parsed from files in memory

=head1 SYNOPSIS

	use Cache::AgainstFile;
	my $cache = new Cache::AgainstFile(
		\&loader, 
		{
			Method => 'Memory',
			MaxItems => 16,
			# ...
		}
	);

	$data = $cache->get($filename);


=head1 DESCRIPTION

Data structures parsed from files are cached in memory.
This is particularly suited to persistent environments such as modperl or other daemon processes.

For short-lived processes such as CGI scripts, the Storable backend might be more appropriate.

Note that the C<size()> method uses Devel::Size if available, otherwise it returns undef.
Devel::Size can consume a reasonable amount of memory working out how much memory you are using!
This memory is released after the operation but it will have expanded your process' memory footprint in the process.

=head1 OPTIONS

=over 4

=item Grace

How long to defer statting the file (in seconds).
Be careful if you use this in modperl environments as it will result in some children having a
new version of the cached item, and some still having the old version.

=item NoStat

Don't stat files to validate the cache - items are served from the cache until they are purged.
Valid values are 0|1 (default=0, i.e. files are statted)

Setting this to 1 is equivalent to setting Grace to an infinite value.

=item MaxATime

Purge items older than this.
Value is in seconds (default=undefined=infinity)

=item MaxItems

Purge oldest items to reduce cache to this size.
Value should be an integer (default=undefined=infinity)

=back

=head1 VERSION

$Revision: 1.15 $ on $Date: 2005/11/10 15:13:57 $ by $Author: johna $

=head1 AUTHOR

John Alden & Piers Kent <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
