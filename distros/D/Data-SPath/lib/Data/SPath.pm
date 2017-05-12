use strict;
use warnings;
package Data::SPath;
BEGIN {
  $Data::SPath::VERSION = '0.0004';
}
#ABSTRACT: lookup on nested data with simple path notation

use 5.010_000;
use feature qw(switch);
use Carp qw/croak/;
use Scalar::Util qw/reftype blessed/;
use Text::Balanced qw/
    extract_delimited
    extract_bracketed
    extract_multiple
/;

use Sub::Exporter -setup => {
    exports => [ spath => \&_build_spath ]
};

my @Error_Handlers = qw(
    method_miss
    key_miss
    index_miss
    key_on_non_hash
    args_on_non_method
);


sub _build_spath {
    my ( $class, $name, $args ) = @_;

    return sub {
        my ( $data, $path, $opts ) = @_;
        for ( @Error_Handlers ) {
            unless ( exists $opts->{ $_ } ) {
                if ( exists $args->{ $_ } ) {
                    $opts->{ $_ } = $args->{ $_ };
                }
                else {
                    $opts->{ $_ } = \&{ "_$_" };
                }
            }
            no warnings 'uninitialized';
            unless ( ref( $opts->{ $_ } ) eq 'CODE' ) {
                croak "$_ must be set to a code reference";
            }
        }
        return _spath( $data, $path, $opts );
    };
}

# taken from Data::DPath
sub _unescape {
    my ( $str ) = @_;
    return unless defined $str;
    $str =~ s/(?<!\\)\\(["'])/$1/g; # '"$
    $str =~ s/\\{2}/\\/g;
    return $str;
}

# Modified from Data::DPath. Added /s modifier to allow new lines in keys (why
# not?)
# this originally only supported double quote
sub _unquote {
    my ($str) = @_;
    $str =~ s/^(['"])(.*)\1$/$2/sg;
    return $str;
}

sub _quoted { shift =~ m,^/["'], }

sub _method_miss {
    my ( $method_name, $current, $depth ) = @_;
    my $reftype = reftype( $current );
    croak "tried to call nonexistent method '"
        . $method_name
        . "' on object with type $reftype at spath path element "
        . $depth;
}

sub _key_miss {
    my ( $key, $current, $depth ) = @_;
    croak "tried to access nonexistent key '"
        . $key
        . "' in hash at spath path element "
        . $depth;
}

sub _index_miss {
    my ( $index, $current, $depth ) = @_;
    croak "tried to access nonexistent index '"
        . $index
        . "' in array at spath path element "
        . $depth;
}

sub _key_on_non_hash {
    my ( $key, $current, $depth ) = @_;
    my $reftype = reftype( $current ) || '(non reference)';
    croak "tried to access key '"
        . $key
        . "' on a non-hash type "
        . $reftype
        . " at spath path element "
        . $depth;
}

sub _args_on_non_method {
    my ( $key, $current, $args, $depth ) = @_;
    my $reftype = reftype( $current ) || '(non reference)';
    croak "tried to pass arguments '"
        . $args
        . "' to a non-method '"
        . $key
        . "' of type "
        . $reftype
        . "at spath path element "
        . $depth;
}



sub _tokenize {
    my ( $path ) = @_;

    my $remaining_path = $path;
    my $extracted;
    my @tokens;

    while ( $remaining_path ) {
        my ( $prefix, $args );
        my $key;

        if ( _quoted( $remaining_path ) ) {
            ( $key,  $remaining_path ) = extract_delimited( $remaining_path, q|'"|, '/' );
            ( $args, $remaining_path ) = extract_bracketed( $remaining_path, q|('")| );
            $key = _unescape _unquote $key;

        }
        else {
            # must extract arguments first to keep extract_delimited from getting
            # quoted structures with / in them
            if ( $remaining_path =~ m,^/[^/]+\(, ) {
                ( $extracted, $remaining_path, $prefix ) = extract_bracketed( $remaining_path, q|('")|, '[^(]*' );
                if ( defined $prefix or defined $remaining_path ) {
                    no warnings 'uninitialized';
                    $remaining_path = $prefix . $remaining_path;
                    $args = $extracted;
                }
                else {
                    $remaining_path = $extracted;
                }
            }
            ( $extracted, $remaining_path ) = extract_delimited( $remaining_path, '/' );
            if ( not $extracted ) {
                ( $extracted, $remaining_path ) = ( $remaining_path, undef );
            }
            else {
                $remaining_path = ( chop $extracted ) . $remaining_path;
            }
            ( $key ) = $extracted =~ m,^/(.*),gs;
            $key = _unescape $key;
        }

        push @tokens, [ $key, $args ];
    }
    return \@tokens;
}

sub _tokenize_args {
    my $args = shift;
    ( $args ) = $args =~ /^\((.*)\)$/;
    return map { _unescape( $_ =~ /^['"]/ ? _unquote( $_ ) : $_ ) }
            extract_multiple( $args, [
                # quoted structures
                sub { extract_delimited( $_[0], q|'"| ) },
                # handle unquoted bare words
                qr/\s*(\w+)/s,
                qr/\s*([^,]+)(.*)/s
            ], undef, 1 );
}

sub _spath {
    my ( $data, $path, $opts ) = @_;

    my $current = $data;
    my $depth = 0;
    my $wantlist = wantarray;

    my $tokens = _tokenize( $path );

    for my $token ( @{ $tokens } ) {
        $depth++;
        my ( $key, $args ) = @{ $token };

        if ( blessed $current ) {

            my @args;
            @args = _tokenize_args( $args )
                if defined $args;

            return $opts->{method_miss}->( $key, $current, $depth )
                unless my $method = $current->can( $key );

            if ( $wantlist ) {
                my @current = $current->$method( @args );
                $current = @current > 1 ? \@current : $current[0];
            }
            else {
                $current = $current->$method( @args );
            }
        }
        else {

            return $opts->{args_on_non_method}->( $key, $current, $args, $depth )
                if defined $args;

            given ( ref $current ) {
                when( 'HASH' ) {

                    return $opts->{key_miss}->( $key, $current, $depth )
                        unless exists $current->{ $key };

                    $current = $current->{ $key };
                }
                when ( 'ARRAY' ) {

                    return $opts->{key_on_non_hash}->( $key, $current, $depth )
                        unless $key =~ /^\d+$/;
                    return $opts->{index_miss}->( $key, $current, $depth )
                        if $#{ $current } < $key;

                    $current = $current->[ $key ];
                }
                default {
                    return $opts->{key_on_non_hash}->( $key, $current, $depth );
                }
            }
        }
    }
    return $current;
}


1;


__END__
=pod

=head1 NAME

Data::SPath - lookup on nested data with simple path notation

=head1 VERSION

version 0.0004

=head1 SYNOPSIS

    use Data::SPath
        spath => {
            # sets up default error handling
            method_miss => \&_method_miss,
            key_miss => \&_key_miss,
            index_miss => \&_index_miss,
            key_on_non_hash => \&_key_on_non_hash,
            args_on_non_method => \&_args_on_non_method
        };

    my $data = {
        foo => [ qw/foobly fooble/ ],
        bar => [ { bat => "boo" }, { bat => "bar" } ]
        "foo bar" => 1,
        "foo\"bar" => { "foo/bar" => 20 }
        obj => SomeClass->new,
    };

    my $match;

    # returns foobly
    $match = spath $data, "/foo/0";

    # returns boo
    $match = spath $data, "/bar/0/bat";

    # returns { bat => "bar" }
    $match = spath $data, "/bar/1";

    # returns 1
    $match = spath $data, q{/"foo bar"};

    # returns 20
    $match = spath $data, q{/"foo\\"bar/"foo/bar"};

    # returns the call to method passing arguments
    $match = spath $data, q{/obj/method( "arg1", 'arg2', bareword )};

=head1 DESCRIPTION

This module implements very simple path lookups on nested data structures. At
the time of this writing there are two modules that implement path matching.
They are L<Data::Path> and L<Data::DPath>. Both of these modules have more
complicated matching similar to C<XPath>. This module does not support
B<matching>, only lookups. So one call will alway return a single match. Also,
when this module encounters a C<blessed> reference, instead of access the references
internal data structure (like L<Data::DPath>) a method call is made on the object
by the name of the key. See L</SYNOPSIS>.

=head1 FUNCTIONS

=head2 C<spath( $data, $path, $opts )>

C<spath> takes the data to perform lookup on as the first argument. The second
argument should be a string with a path specification in it. The third optional
argument, if specified, should be a hash reference of options. Currently the
only supported options are error handlers.  See L</"ERROR HANDLING">. C<spath>
returns the lookup if it is found, calls croak() otherwise with the error. This
behavior can be changed by setting error handlers. If the error handler
returns, that value is returned.

=over 4

=item *

data

Data can be any type of data, although it makes little sense to pass in
something other than a hash reference, an array reference or an object.

=item *

path

Path should start with a slash and be a slash separated list of keys to lookup.
Each level of key is one level deeper in the data.

=over 4

=item *

hash

When the current level in the data is a hash reference, the key is looked up in
the hash, and the current level is set to the return of the lookup on the hash.

=item *

array

When the current level is an array reference, the key should be an index into
the array, the current level is then set to the return of the lookup on the
array reference.

=item *

object

If the current level is an object, the key is treated as the name of a method
to call on the object. The method is called in list context if C<spath> was
called in list context, otherwise scalar context. If the method returns more
than one item, the current level is set to an array reference of the return,
otherwise the current level is set to the return of the method call.  It is
possible to pass in arguments to object methods. Arguments are expected to be a
comma separated list of either quoted structures or barewords which must match
C<\w+>. See L</SYNOPSIS> for examples.

=back

Quotes are allowed on each level. You only need quotes if you have spaces
or C</> in your keys. For example:

    my $data = { "foo bar" => 1, "foo/bar" => 1 };
    spath $data, q{/"foo bar"};
    spath $data, q{/"foo/bar"};

You can also use C<\> to escape quotes:

    spath $data, q{/"foo\"bar"}; # embedded quotes

=item *

opts

The only options currently accepted are error handlers. See L</"ERROR
HANDLING">.

=back

=head1 EXPORTS

Nothing is exported by default. You can request C<spath> be exported to you
namespace.  This module uses L<Sub::Exporter> for exporting.

=head1 ERROR HANDLING

Data::SPath defaults to calling Carp::croak() when any kind of error occurs.
You can change any of the error handlers by passing in a third argument to
C<spath>:

    spath $data, "/path", {
        method_miss => \&_method_miss,
        key_miss => \&_key_miss,
        index_miss => \&_index_miss,
        key_on_non_hash => \&_key_on_non_hash,
        args_on_non_method => \&_args_on_non_method
    };

Or you can setup default error handlers at compile time by passing them into
your call to C<import()>:

    use Data::SPath
        spath => {
            method_miss => \&_method_miss,
            key_miss => \&_key_miss,
            index_miss => \&_index_miss,
            key_on_non_hash => \&_key_on_non_hash,
            args_on_non_method => \&_args_on_non_method
        };

The default error handlers look like this:

    sub _method_miss {
        my ( $method_name, $current, $depth ) = @_;
        my $reftype = reftype( $current );
        croak "tried to call nonexistent method '"
            . $method_name
            . "' on object with type $reftype at spath path element "
            . $depth;
    }

    sub _key_miss {
        my ( $key, $current, $depth ) = @_;
        croak "tried to access nonexistent key '"
            . $key
            . "' in hash at spath path element "
            . $depth;
    }

    sub _index_miss {
        my ( $index, $current, $depth ) = @_;
        croak "tried to access nonexistent index '"
            . $index
            . "' in array at spath path element "
            . $depth;
    }

    sub _key_on_non_hash {
        my ( $key, $current, $depth ) = @_;
        my $reftype = reftype( $current ) || '(non reference)';
        croak "tried to access key '"
            . $key
            . "' on a non-hash type $reftype at spath path element "
            . $depth;
    }

    sub _args_on_non_method {
        my ( $key, $current, $args, $depth ) = @_;
        my $reftype = reftype( $current ) || '(non reference)';
        croak "tried to pass arguments '"
            . $args
            . "' to a non-method '"
            . $key
            . "' of type "
            . $reftype
            . "at spath path element "
            . $depth;
    }

If you return from an error handler, that value is returned from C<spath>.

=head1 AUTHOR

Scott Beck <scottbeck@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Scott Beck <scottbeck@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

