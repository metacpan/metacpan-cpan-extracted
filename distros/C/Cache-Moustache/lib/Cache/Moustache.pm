package Cache::Moustache;

use 5.005;
my $cpants = q/
use strict;
use warnings;
/;

BEGIN {
	$Cache::Moustache::AUTHORITY = 'cpan:TOBYINK';
	$Cache::Moustache::VERSION   = '0.005';
}

sub isa
{
	my $what = $_[1];
	return !!1 if {
		'Cache'            => 1,
		'Cache::Cache'     => 1,
		'Cache::FastMmap'  => 1,
		'Cache::Moustache' => 1,
		'Cache::Ref'       => 1,
		'CHI'              => 1,
		'Mojo::Cache'      => 1,
	}->{$what};
	return !!0;
}

sub new
{
	my ($class, %args) = @_;
	return $class if ref $class && $class->isa(__PACKAGE__);
	my %self = map { ;"~~~~$_" => $args{$_} } keys %args;
	$self{'~~~~default_expires_in'} ||= 3600;
	bless {%self}, $class;
}

my %multipliers = (
	s        => 1,
	second   => 1,
	seconds  => 1,
	sec      => 1,
	m        => 60,
	minute   => 60,
	minutes  => 60,
	min      => 60,
	h        => 3600,
	hour     => 3600,
	hours    => 3600,
	d        => 86400,
	day      => 86400,
	days     => 86400,
	w        => 604800,
	week     => 604800,
	weeks    => 604800,
	M        => 2419200,
	month    => 2419200,
	months   => 2419200,
	y        => 31536000,
	year     => 31536000,
	years    => 31536000,
);

sub _clone
{
	require Storable;
	shift;
	goto \&Storable::dclone;
}

sub set
{
	my ($cache, $key, $data, $expires_in) = @_;
	return if $key =~ /^~~~~/;
	
	$data = $cache->_clone($data) if ref $data && $cache->{'~~~~clone_references'};
	
	$expires_in = $cache->{'~~~~default_expires_in'} if !defined $expires_in;
	
	if ($expires_in =~ /^(\d*)\s*([A-Za-z]+)$/)
	{
		($expires_in, my $mult) = ($1, $2);
		$expires_in = 1 unless defined $expires_in && length $expires_in;
		$expires_in *= ($multipliers{$mult} || $multipliers{lc $mult});
	}
	
	my $expires_at = ($expires_in < 0) ? $expires_in : (time + $expires_in);
	$cache->{$key} = [$data, $expires_at];
}

sub get
{
	my ($cache, $key) = @_;
	return if $key =~ /^~~~~/;
	return unless exists $cache->{$key};
	
	my $expires_at = $cache->{$key}[1];
	if ($expires_at >= 0 and $expires_at < time)
	{
		$cache->remove($key);
		return;
	}

	$cache->{$key}[0];
}

sub remove
{
	my ($cache, $key) = @_;
	return if $key =~ /^~~~~/;
	return( (delete $cache->{$key}) ? 1 : 0 );
}

sub clear
{
	my $cache = shift;
	my @keys = grep { !/^~~~~/ } keys %$cache;
	delete $cache->{$_} for @keys;
	return scalar(@keys);
}

sub purge
{
	my $cache = shift;
	my $now   = time;
	my @keys  =
		grep { my $e = $cache->{$_}[1]; $e >= 0 && $e < $now }
		grep { !/^~~~~/ } keys %$cache;
	delete $cache->{$_} for @keys;
	return scalar(@keys);
}

sub get_keys
{
	my $cache = shift;
	my @keys = grep { !/^~~~~/ } keys %$cache;
	return @keys;
}

sub size
{
	scalar( my @keys = shift->get_keys );
}

sub AUTOLOAD
{
	return;
}

__PACKAGE__
__END__

=head1 NAME

Cache::Moustache - you'd have to be insane to use a module called Cache::Moustache, wouldn't you?

=head1 SYNOPSIS

  my $cache = Cache::Moustache->new;
  $cache->set($key, $object);
  
  # later ...
  $object = $cache->get($key);

=head1 DESCRIPTION

If you subscribe to the worse-is-better philosophy, then this is
quite possibly the best cache module available on CPAN. It's the
kind of module a five-year-old might write if you gave them a
project to write a caching module. Not a particularly gifted
five-year-old.

It provides an interface similar to L<CHI>, L<Cache::Cache> and
other commonly-used caching modules. Thus, via polymorphism,
Cache::Moustache objects can often (if you're lucky) be used
when one of those is expected.

Why would you want to use such a dumb module instead of something
brilliant like L<CHI>? Because Cache::Moustache is pretty fast, has
a low memory footprint (except for the memory required to store the
cached objects), and has no dependencies. I didn't say "no non-core
dependencies"; I said no dependencies. This thing doesn't even
C<use strict>. It's basically just a hashref with methods.

I would have called it Cache::Tiny, but then people might have
been tempted to actually use it.

=head2 Constructor

=over

=item C<< new(%options) >>

Called as a class method returns a shiny new cache. Called as
an object (instance) method, just returns C<< $self >>.

Supported options:

=over

=item default_expires_in

The length of time (in seconds) before a cached value should be
considered expired. The default is an hour. If you specify -1,
then things will never expire. If you specify 0, that's dumb, so
Cache::Moustache will assume that you meant an hour.

=item clone_references

If true, then Cache::Moustache will clone any references you
ask it to cache. This feature uses the C<dclone> function from
L<Storable>, so violates Cache::Moustache's "no dependencies"
rule. Yeah, we're so cool we don't even follow our own rules!

This slows down the cache, so don't use it unless you have to.
(I only added this feature to pass some test cases, I don't
actually want to use it myself.)

=back

=back

=head2 Methods

=over

=item C<< set($key, $value, $expires_in) >>

Stores something in the cache. C<< $expires_in >> is an optional
argument that allows you to override I<default_expires_in>. You
can use strings like "3 minutes" like what Cache::Cache supports,
but I don't recommend it.

Cache::Moustache uses keys beginning with "~~~~" for its own
internal purposes. If you try to store a value with a key like that,
no error will be thrown, but it will not be stored; the value will
effectively expire instantly.

=item C<< get($key) >>

Retrieve the value associated with a key (unless it's expired).

=item C<< remove($key) >>

Removes a key/value pair from the cache. Returns the number of
pairs removed (one or none).

=item C<< clear >>

Empty everything from the cache. Returns the number of key/value
pairs removed.

=item C<< purge >>

Remove any expired key/value pairs from the cache. Returns the
number of pairs removed.

=item C<< size >>

Returns the number of items in the cache (including expired items
that have not been purged). Note that unlike L<Cache::Cache> and
L<CHI>, it does not return the total size of all items in bytes.

=item C<< size >>

Returns the number of items in the cache (including expired items
that have not been purged). Note that unlike L<Cache::Cache> and
L<CHI>, it does not return the total size of all items in bytes.

=item C<< get_keys >>

Returns the keys of the items in the cache (including expired items
that have not been purged). 

=item C<< isa($class) >>

Returns true if $class is one of 'Cache::Moustache', 'Cache',
'Cache::Cache', 'Cache::FastMmap', 'Cache::Ref', 'CHI' or
'Mojo::Cache'.

In other words, it tells great big porky pie lies.

=back

Calling any other method returns nothing, but does not die.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Cache-Moustache>.

=head1 SEE ALSO

L<CHI>, L<Cache::Cache>,
L<http://www.worldbeardchampionships.com/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

