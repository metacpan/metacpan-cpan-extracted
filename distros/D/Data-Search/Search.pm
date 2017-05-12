package Data::Search;
use 5.005;
use strict;
use warnings;
require Exporter;
our $VERSION = '0.03';
our @ISA = qw(Exporter);
our @EXPORT= qw(datasearch);

=head1 NAME

Data::Search - Data structure search

=head1 SYNOPSIS

use Data::Search;

 $data = { ... };
 @results = datasearch( data => $data, search => 'values',
                        find => qr/string/, return => 'hashcontainer' );

=head1 DESCRIPTION

=head2 datasearch - Search data structures

This function allows you to search arbitrarily large/complex
data structures for particular elements.
You can search hash keys, or hash/array values, for a number/string
or regular expression.
The datasearch function can return either the found hash keys, the found
values (which could be data structures themselves) or the container
of the key or value (which is always going to be a data structure)

By default, hash keys are searched, and the corresponding values are returned.
To search hash or array values, specify SEARCH => 'values'.
To search both values and keys, specify SEARCH => 'all'.

To find an exact match of a string, set FIND => 'string'. To use a regular
expression use the qr operator: FIND => qr/^name.*/i
FIND may also be a 2 element array, to search for a key-value pair.

To return the hash keys found (or the hash keys corresponding to
searched values), specify RETURN => 'keys'.
To return both keys and values specify RETURN => 'all'.

You can also return the data structure containing the found key/value.

To do that, specify RETURN => 'container'. This will return the immediate
container, either a hash or an array reference. You can also choose to
get the closest hash container (even if the value was inside an array)
by specifying RETURN => 'hashcontainer'.

Similarly, you can return the closest array container (even though the
value found was a hash value or hash key) by specifying
RETURN => 'arraycontainer'

Also, you can get an outer container by doing RETURN => 'container:xyz'
in which case the container returned would be a structure pointed to
by key xyz (if found to contain the search element somewhere inside it).
Please see the examples at the end of this document.

ARGUMENTS
The following arguments are accepted (case-insensitively).
The only mandatory arguments are DATA and FIND.

 data   => Reference of structure to search
 search => What elements to search: keys|values|all (default: keys)
 find   => Look for: string | qr/regex/ | [ key => value ]
 return => What to return: keys|values|all|
             container|hashcontainer|arraycontainer|container:key_name
 
RETURN VALUES

Returns a list of matching elements (could be strings or references
to internal parts (hashes/arrays) of the data structure.

EXAMPLES

 my @results = datasearch( data => $ref, find => 'name' );
That will return all values pointed to by hash keys called 'name'

 my @results = datasearch( data => $ref, search => 'values',
     find => qr/alex/i, return => 'key' );
That will return all keys that point to strings that match "alex"
case insensitively.

 my @results = datasearch( data => $ref, search => 'keys',
     find => qr/_id$/, return => 'all' );
That will return all keys that end with "_id", and all values
pointed to by those keys.

 my @results = datasearch( data => $ref, return => 'container:myrecord',
                 find => [ suffix => 'Jr' ] )
That implies search=>'all', searches for a key 'suffix'
that has value 'Jr', and returns any matching hashes pointed to by a key
named myrecord (even if suffix is deep inside those hashes)

=cut

sub datasearch {
    my $args = get_args( [qw(FIND SEARCH RETURN DATA)], @_ );

    die "FIND argument is required" unless defined $args->{FIND};
    die "DATA argument is required" unless defined $args->{DATA};

    my $sk = 1 if !$args->{SEARCH} || $args->{SEARCH} =~ /key|all/
      or ref($args->{FIND}) eq 'ARRAY';
    my $sv = 1 if $args->{SEARCH} && $args->{SEARCH} =~ /value|all/;

    my $rv = 1 if !$args->{RETURN} || $args->{RETURN} =~ /value|all/;
    my $rk = 1 if $args->{RETURN} && $args->{RETURN} =~ /key|all/;
    my $rc = $args->{RETURN} && $args->{RETURN} =~ /container/
           ? $args->{RETURN} : 0;

    my (@results, @refs, $container);
    @results = _datasearch( $args->{DATA}, $args->{FIND}, $sk, $sv, $rv, $rk,
            $rc, \@refs, undef, undef, undef, 0 );

    my @unique;
    foreach my $p ( @results ) { # Weed out duplicate references
        push @unique, $p unless ref($p) and grep { ref && $_ == $p } @unique;
    }
    return @unique;
} ## end sub datasearch

# Internal recursive function called by datasearch
sub _datasearch {
    my ($p, $f, $sk, $sv, $rv, $rk, $rc, $refs, $container, $key, $rr, $depth)
      = @_;
    # print "DEPTH  IN=$depth\n";
    my ($root) = $rc =~ /:(.+)/;
    if ( ref($p) ) {
        if ( grep { $p == $_ } @$refs ) {
            warn "Skipping duplicate reference to $p";
            return;
        }
        push @$refs, $p;
    }

    my @results;
    if ( ref($p) && $p =~ /HASH/ ) {
        $container = $p unless $rc =~ /array/;
        foreach my $k ( keys %$p ) {
            $rr = $p->{$k} if $root && $root eq $k;
            my ($f1, $f2) = ref($f) eq 'ARRAY' ? ($f->[0], $f->[1]) : $f;
            if ( $sk and ref($f1) eq 'Regexp' && $k =~ /$f1/ || $k eq $f1 ) {
                if ( ! defined $f2 or
                        ref($f2) eq 'Regexp' && $p->{$k} =~ /$f2/
                        || $p->{$k} eq $f2 ) {
                    if ( $rc ) {
                        if ( $root ) {
                            push @results, $rr if $rr;
                        } else {
                            push @results, $container;
                        }
                    } else {
                        push @results, $k if $rk;
                        push @results, $p->{$k} if $rv;
                    }
                }
            }
            if ( my @r = _datasearch( $p->{$k}, $f, $sk, $sv, $rv, $rk,
                        $rc, $refs, $container, $k, $rr, $depth+1 ) ) {
                push @results, @r;
            }
        }
    } elsif ( ref($p) && $p =~ /ARRAY/ ) {
        $container = $p unless $rc =~ /hash/;
        foreach ( @$p ) {
            if ( my @r = _datasearch( $_, $f, $sk, $sv, $rv, $rk,
                        $rc, $refs, $container, $key, $rr, $depth+1 ) ) {
                push @results, @r;
            }
        }
    } elsif ( !ref($p) && defined $p && $sv and
            ref($f) eq 'Regexp' && $p =~ /$f/ || $p eq $f ) {
        if ( $rc ) {
            if ( $root ) {
                push @results, $rr if $rr;
            } else {
                push @results, $container;
            }
        } else {
            push @results, $p if $rv;
            push @results, $key if $rk && defined $key;
        }
    }
    # print "DEPTH OUT=$depth\n";
    return @results;
} ## end sub datasearch

# Return a hash of named parameters (keys converted to upper case)
sub get_args {
    # Called as get_args(@_) or as get_args( [arg, arg2...], @_ )
    my $valid_arg_list = ( ref($_[0]) eq 'ARRAY' ? shift : '' );

    die "get_args got odd number of arguments"
      unless (@_/2 == int(@_/2));

    my $args;
    for ( my $n = 0 ; $n < $#_ ; $n += 2 ) {
        $args->{ uc $_[$n] } = $_[ $n + 1 ];
    }

    # Do argument checking, if list of valid arguments was given
    if ($valid_arg_list) {
        foreach my $arg (keys %$args) {
            die "get_args: Argument \"$arg\" is invalid"
                unless grep (/^\Q$arg\E$/, @$valid_arg_list);
        }
    }
    return $args;
}

1;

