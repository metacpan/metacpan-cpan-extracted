package CHI::Memoize;
$CHI::Memoize::VERSION = '0.07';
use Carp;
use CHI;
use CHI::Memoize::Info;
use CHI::Driver;
use Hash::MoreUtils qw(slice_grep);
use strict;
use warnings;
use base qw(Exporter);

my $no_memoize = {};
sub NO_MEMOIZE { $no_memoize }

our @EXPORT      = qw(memoize);
our @EXPORT_OK   = qw(memoize memoized unmemoize NO_MEMOIZE);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my %memoized;
my @get_set_options = qw( busy_lock expire_if expires_at expires_in expires_variance );
my %is_get_set_option = map { ( $_, 1 ) } @get_set_options;

sub memoize {
    my ( $func, %options ) = @_;

    my ( $func_name, $func_ref, $func_id ) = _parse_func_arg( $func, scalar(caller) );
    croak "'$func_id' is already memoized" if exists( $memoized{$func_id} );

    my $passed_key      = delete( $options{key} );
    my $cache           = delete( $options{cache} );
    my %compute_options = slice_grep { $is_get_set_option{$_} } \%options;
    my $prefix          = "memoize::$func_id";

    if ( !$cache ) {
        my %cache_options = slice_grep { !$is_get_set_option{$_} } \%options;
        $cache_options{namespace} ||= $prefix;
        if ( !$cache_options{driver} && !$cache_options{driver_class} ) {
            $cache_options{driver} = "Memory";
        }
        if ( $cache_options{driver} eq 'Memory' || $cache_options{driver} eq 'RawMemory' ) {
            $cache_options{global} = 1;
        }
        $cache = CHI->new(%cache_options);
    }

    my $wrapper = sub {
        my $wantarray = wantarray ? 'L' : 'S';
        my @key_parts =
          defined($passed_key)
          ? ( ( ref($passed_key) eq 'CODE' ) ? $passed_key->(@_) : ($passed_key) )
          : @_;
        if ( @key_parts == 1 && ( $key_parts[0] || 0 ) eq NO_MEMOIZE ) {
            return $func_ref->(@_);
        }
        else {
            my $key = [ $prefix, $wantarray, @key_parts ];
            my $args = \@_;
            return $cache->compute( $key, {%compute_options}, sub { $func_ref->(@$args) } );
        }
    };
    $memoized{$func_id} = CHI::Memoize::Info->new(
        orig       => $func_ref,
        wrapper    => $wrapper,
        cache      => $cache,
        key_prefix => $prefix
    );

    no strict 'refs';
    no warnings 'redefine';
    *{$func_name} = $wrapper if $func_name;

    return $wrapper;
}

sub memoized {
    my ( $func_name, $func_ref, $func_id ) = _parse_func_arg( $_[0], scalar(caller) );
    return $memoized{$func_id};
}

sub unmemoize {
    my ( $func_name, $func_ref, $func_id ) = _parse_func_arg( $_[0], scalar(caller) );
    my $info = $memoized{$func_id} or die "$func_id is not memoized";

    eval { $info->cache->clear() };
    no strict 'refs';
    no warnings 'redefine';
    *{$func_name} = $info->orig if $func_name;
    delete( $memoized{$func_id} );
    return $info->orig;
}

sub _parse_func_arg {
    my ( $func, $caller ) = @_;
    my ( $func_name, $func_ref, $func_id );
    if ( ref($func) eq 'CODE' ) {
        $func_ref = $func;
        $func_id  = "$func_ref";
    }
    else {
        $func_name = $func;
        $func_name = join( "::", $caller, $func_name ) if $func_name !~ /::/;
        $func_id   = $func_name;
        no strict 'refs';
        $func_ref = \&$func_name;
        die "no such function '$func_name'" if ref($func_ref) ne 'CODE';
    }
    return ( $func_name, $func_ref, $func_id );
}

1;

__END__

=pod

=head1 NAME

CHI::Memoize - Make functions faster with memoization, via CHI

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use CHI::Memoize qw(:all);
    
    # Straight memoization in memory
    memoize('func');
    memoize('Some::Package::func');

    # Memoize to a file or to memcached
    memoize( 'func', driver => 'File', root_dir => '/path/to/cache' );
    memoize( 'func', driver => 'Memcached', servers => ["127.0.0.1:11211"] );

    # Expire after one hour
    memoize('func', expires_in => '1h');
    
    # Memoize based on the second and third argument to func
    memoize('func', key => sub { $_[1], $_[2] });

=head1 DESCRIPTION

"`Memoizing' a function makes it faster by trading space for time.  It does
this by caching the return values of the function in a table.  If you call the
function again with the same arguments, C<memoize> jumps in and gives you the
value out of the table, instead of letting the function compute the value all
over again." -- quoted from the original L<Memoize|Memoize>

For a bit of history and motivation, see

    http://www.openswartz.com/2012/05/06/memoize-revisiting-a-twelve-year-old-api/

C<CHI::Memoize> provides the same facility as L<Memoize|Memoize>, but backed by
L<CHI|CHI>. This means, among other things, that you can

=over

=item *

specify expiration times (L<expires_in|CHI/expires_in>) and conditions
(L<expire_if|CHI/expire_if>)

=item *

memoize to different backends, e.g. L<File|CHI::Driver::File>,
L<Memcached|CHI::Driver::Memcached>, L<DBI|CHI::Driver::DBI>, or to
L<multilevel caches|CHI/SUBCACHES>

=item *

handle arbitrarily complex function arguments (via CHI L<key
serialization|CHI/Key transformations>)

=back

=head2 FUNCTIONS

All of these are importable; only C<memoize> is imported by default. C<use
Memoize qw(:all)> will import them all as well as the C<NO_MEMOIZE> constant.

=for html <a name="memoize">

=over

=item memoize ($func, %options)

Creates a new function wrapped around I<$func> that caches results based on
passed arguments.

I<$func> can be a function name (with or without a package prefix) or an
anonymous function. In the former case, the name is rebound to the new
function. In either case a code ref to the new wrapper function is returned.

    # Memoize a named function
    memoize('func');
    memoize('Some::Package::func');

    # Memoize an anonymous function
    $anon = memoize($anon);

By default, the cache key is formed from combining the full function name, the
calling context ("L" or "S"), and all the function arguments with canonical
JSON (sorted hash keys). e.g. these calls will be memoized together:

    memoized_function({a => 5, b => 6, c => { d => 7, e => 8 }});
    memoized_function({b => 6, c => { e => 8, d => 7 }, a => 5});

because the two hashes being passed are canonically the same. But these will be
memoized separately because of context:

     my $scalar = memoized_function(5);
     my @list = memoized_function(5);

By default, the cache L<namespace|CHI/namespace> is formed from the full
function name or the stringified code reference.  This allows you to introspect
and clear the memoized results for a particular function.

C<memoize> throws an error if I<$func> is already memoized.

See L<OPTIONS> below for what can go in the options hash.

=item memoized ($func)

Returns a L<CHI::Memoize::Info|CHI::Memoize::Info> object if I<$func> has been
memoized, or undef if it has not been memoized.

    # The CHI cache where memoize results are stored
    #
    my $cache = memoized($func)->cache;
    $cache->clear;

    # Code references to the original function and to the new wrapped function
    #
    my $orig = memoized($func)->orig;
    my $wrapped = memoized($func)->wrapped;

=item unmemoize ($func)

Removes the wrapper around I<$func>, restoring it to its original unmemoized
state.  Also clears the memoize cache if possible (not supported by all
drivers, particularly L<memcached|CHI::Driver::Memcached>). Throws an error if
I<$func> has not been memoized.

    memoize('Some::Package::func');
    ...
    unmemoize('Some::Package::func');

=back

=head2 OPTIONS

The following options can be passed to L</memoize>.

=over

=item key

Specifies a code reference that takes arguments passed to the function and
returns a cache key. The key may be returned as a list, list reference or hash
reference; it will automatically be serialized to JSON in canonical mode
(sorted hash keys).

For example, this uses the second and third argument to the function as a key:

    memoize('func', key => sub { @_[1..2] });

and this is useful for functions that accept a list of key/value pairs:

    # Ignore order of key/value pairs
    memoize('func', key => sub { %@_ });

Regardless of what key you specify, it will automatically be prefixed with the
full function name and the calling context ("L" or "S").

If the coderef returns C<CHI::Memoize::NO_MEMOIZE> (or C<NO_MEMOIZE> if you
import it), this call won't be memoized. This is useful if you have a cache of
limited size or if you know certain arguments will yield nondeterministic
results. e.g.

    memoize('func', key => sub { $is_worth_caching ? @_ : NO_MEMOIZE });

=item set and get options

You can pass any of CHI's L<set|CHI/set> options (e.g.
L<expires_in|CHI/expires_in>, L<expires_variance|CHI/expires_variance>) or
L<get|CHI/get> options (e.g. L<expire_if|CHI/expire_if>,
L<busy_lock|CHI/busy_lock>). e.g.

    # Expire after one hour
    memoize('func', expires_in => '1h');
    
    # Expire when a particular condition occurs
    memoize('func', expire_if => sub { ... });

=item cache options

Any remaining options will be passed to the L<CHI constructor|CHI/CONSTRUCTOR>
to generate the cache:

    # Store in file instead of memory
    memoize( 'func', driver => 'File', root_dir => '/path/to/cache' );

    # Store in memcached instead of memory
    memoize('func', driver => 'Memcached', servers => ["127.0.0.1:11211"]);

Unless specified, the L<namespace|CHI/namespace> is generated from the full
name of the function being memoized.

You can also specify an existing cache object:

    # Store in memcached instead of memory
    my $cache = CHI->new(driver => 'Memcached', servers => ["127.0.0.1:11211"]);
    memoize('func', cache => $cache);

=back

=head1 CLONED VS RAW REFERENCES

By default C<CHI>, and thus C<CHI::Memoize>, returns a deep clone of the stored
value I<even> when caching in memory. e.g. in this code

    # func returns a list reference
    memoize('func');
    my $ref1 = func();
    my $ref2 = func();

C<$ref1> and C<$ref2> will be references to two completely different lists
which have the same contained values. More specifically, the value is
L<serialized|CHI/serializer> by L<Storable|Storable> on C<set> and deserialized
(hence cloned) on C<get>.

The advantage here is that it is safe to modify a reference returned from a
memoized function; your modifications won't affect the cached value.

    my $ref1 = func();
    push(@$ref1, 3, 4, 5);
    my $ref2 = func();
    # $ref2 does not have 3, 4, 5

The disadvantage is that it takes extra time to serialize and deserialize the
value, and that some values like code references may be more difficult to
store. And cloning may not be what you want at all, e.g. if you are returning
objects.

Alternatively you can use L<CHI::Driver::RawMemory|CHI::Driver::RawMemory>,
which will store raw references the way C<Memoize> does. Now, however, any
modifications to the contents of a returned reference will affect the cached
value.

    memoize('func', driver => 'RawMemory');
    my $ref1 = func();
    push(@$ref1, 3, 4, 5);
    my $ref2 = func();
    # $ref1 eq $ref2
    # $ref2 has 3, 4, 5

=head1 CAVEATS

The L<caveats of Memoize|Memoize/CAVEATS> apply here as well.  To summarize:

=over

=item *

Do not memoize a function whose behavior depends on program state other than
its own arguments, unless you explicitly capture that state in your computed
key.

=item *

Do not memoize a function with side effects, as the side effects won't happen
on a cache hit.

=item *

Do not memoize a very simple function, as the costs of caching will outweigh
the costs of the function itself.

=back

=head1 KNOWN BUGS

=over

=item *

Memoizing a function will affect its call stack and its prototype.

=back

=head1 RELATED MODULES

A number of modules address a subset of the problems addressed by this module,
including:

=over

=item *

L<Memoize::Expire> - pluggable expiration of memoized values

=item *

L<Memoize::ExpireLRU> - provides LRU expiration for Memoize

=item *

L<Memoize::Memcached> - use a memcached cache to memoize functions

=back

=head1 SUPPORT

Questions and feedback are welcome, and should be directed to the perl-cache
mailing list:

    http://groups.google.com/group/perl-cache-discuss

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Memoize
    bug-chi-memoize@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-chi-memoize
    git clone git://github.com/jonswar/perl-chi-memoize.git

=head1 SEE ALSO

L<CHI|CHI>, L<Memoize|Memoize>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
