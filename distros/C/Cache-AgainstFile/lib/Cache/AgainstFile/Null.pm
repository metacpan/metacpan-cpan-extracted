###############################################################################
# Purpose : No caching backend for Cache::AgainstFile
# Author  : John Alden
# Created : 22 Apr 2005 (based on IFL::FileCache)
# CVS     : $Id: Null.pm,v 1.5 2005/05/26 15:52:19 simonf Exp $
###############################################################################

package Cache::AgainstFile::Null;

use strict;
use vars qw($VERSION);
$VERSION = sprintf"%d.%03d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

sub new {
	my ($class, $loader, $options) = @_;	
	my $self = {
		'loader' => $loader,
		'options' => $options,
	};
	return bless $self, $class;
}

sub get {
	my $self = shift;
	TRACE("Get called on null cache - calling loader");
	my $data = $self->{loader}->(@_);
	return $data;
}

sub purge {}
sub clear {}
sub count {return 0}
sub size  {return 0}

# Documented in Cache::AgainstFile::Base
sub remove   {}
sub accessed { +{} }
sub stale    { () }

#Log::Trace stubs
sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Cache::AgainstFile::Null - backend for Cache::AgainstFile to disable caching

=head1 SYNOPSIS

	my $cache = new Cache::AgainstFile(
		\&loader, 
		{
			Method => 'Null',
			...
		}
	);

	$data = $cache->get($filename);

=head1 DESCRIPTION

This implementation simply calls the cache loader each time get() is called, thus no caching is done.
It is useful for testing when you want to quickly disable caching by flipping the Method passed to Cache::AgainstFile.

=head1 OPTIONS

There are no additional options for this backend

=head1 VERSION

$Revision: 1.5 $ on $Date: 2005/05/26 15:52:19 $ by $Author: simonf $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
