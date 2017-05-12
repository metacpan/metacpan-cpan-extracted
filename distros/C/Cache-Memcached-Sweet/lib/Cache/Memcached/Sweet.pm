package Cache::Memcached::Sweet;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Exporter 'import';

use Cache::Memcached;

our @EXPORT = qw(memcached);

our $VERSION = '0.04';

my $memcached = new Cache::Memcached( servers => [ $ENV{MEMCACHED_HOST} || 'localhost:11211' ] );

sub memcached {
	my ($k, $v, $ttl) = @_;
	if( @_ >= 2) {
		if (ref($v) eq 'CODE') {
			my $code = $v;
			$v = $memcached->get($k);
			unless (defined $v) {
				$v = $code->();
				$memcached->set($k, $v, $ttl);
			}
			return $v;			
		} else {
			$memcached->set($k, $v, $ttl) || warn "Setting $k failed";
			return $v;
		}
	} elsif (@_ == 1) { 
		$v = $memcached->get($k);
		return $v;
	} else {
		return $memcached;
	}
}

=head1 NAME

Cache::Memcached::Sweet - sugary memcached with callbacks 

=head1 SYNOPSIS

  # Reads MEMCACHED_HOST from env, and defaults to localhost:11211 if not set

  use Cache::Memcached::Sweet; # exports the subroutine "memcached"

  my $value = memcached($key, sub { 
 	return some_expensive_operation($foo, $bar, $baz);
  });

  my $value = memcached($key); # retrieve value

  memcached($other_key, { a => 1, b => 2 }, 600); # set value with TTL


=head1 FUNCTIONS

L<Cache::Memcached::Sweet> implements and exports the following function

=head2 memcached
  
  # Set's a value with no TTL
  memcached('foo', $cache_this);

  # Sets a value, with optional ttl
  memcached('bar', { a => 1, b => 2 }, 600);

  # Retrieves a value from the cache
  my $value = memcached('baz');

  # Gets a value if it exists or sets it with the return value from executing the coderef
  # Note: The coderef is called in scalar context
  my $result = memcached('blurgh', sub { 
     buzz($blirp, $blurp) 
  });

  my $mc = memcached; # Exposes package global instance of Cache::Memcached
  $mc->set_servers()  # ... etc, but not recommended
  
=head1 CAUTION

This module is meant to provide convenience, and is hardcoded to get the memcached server address from MEMCACHED_HOST or will default to localhost:11211. If you're running some fancy memcached cluster, then this module is probably not for you.

=head1 AUTHOR

Stig Palmquist, C<< <stig at stig.io> >>

=head1 BUGS

https://github.com/pqx/cache-memcached-sweet


=head1 LICENSE AND COPYRIGHT

Copyright 2013 pqx Limited.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

42; 
