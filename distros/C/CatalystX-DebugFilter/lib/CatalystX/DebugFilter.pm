package CatalystX::DebugFilter;
$CatalystX::DebugFilter::VERSION = '0.13';
# ABSTRACT: Provides configurable filtering of data that is logged to the debug logs (and error screen)
use Moose::Role;
use namespace::autoclean;
use Scalar::Util qw(reftype blessed);
requires('dump_these','log_request_headers','log_response_headers');
our $CONFIG_KEY = __PACKAGE__;
my %filters = (
    Request  => \&_filter_request,
    Response => \&_filter_response,
    Stash    => \&_filter_stash,
    Session  => \&_filter_session,
);
around dump_these => sub {
    my $next = shift;
    my $c    = shift;
    my @dump = $next->( $c, @_ );
    if ( my $config = $c->config->{$CONFIG_KEY} ) {
        foreach my $d (@dump) {
            my ( $type, $obj ) = @$d;
            my $callback      = $filters{$type}  or next;
            my $filter_config = $config->{$type} or next;
            my $obj_type = reftype($obj);

            # poor-man's shallow cloning, none of the Clone
            # modules were problem-free...
            my $copy;
            if ( $obj_type eq 'HASH' ) {
                $copy = {%$obj};
            } elsif ( $obj_type eq 'ARRAY' ) {
                $copy = [@$obj];
            } else {
                $copy = "$obj";    # not going to bother with anything else
            }
            if(ref $copy and my $obj_ref = blessed $obj){
                bless $copy, $obj_ref;
            }

            if ( $callback->( $filter_config, $copy ) ) {
                $d->[1] = $copy;
            }
        }
    }
    return @dump;
};

sub _normalize_filters {
    my @filters = grep { defined $_ } ( ref( $_[0] ) eq 'ARRAY' ? @{ $_[0] } : @_ );
    my @normalized = map { _make_filter_callback($_) } @filters;
    return @normalized;
}

sub _make_filter_callback {
    my $filter = shift;

    my $filter_str = '[FILTERED]';
    if ( ref($filter) eq 'Regexp' ) {
        return sub { return $_[0] =~ $filter ? $filter_str : undef };
    } elsif ( ref($filter) eq 'CODE' ) {
        return $filter;
    } else {
        return sub { return $_[0] eq $filter ? $filter_str : undef };
    }
}

sub _filter_request {
    my ( $config, $req ) = @_;

    my $filtered = _filter_request_params( $config->{params}, $req );
    if ( my $h = _filter_headers( $config, $req->headers ) ) {
        $req->headers($h);
        $filtered++;
    }
    return $filtered;

}

sub _filter_request_params {
    my ( $param_filter, $req ) = @_;
    return if !$param_filter;
    my $is_filtered = 0;
    my @types       = ( 'query', 'body', '' );
    my @filters     = _normalize_filters($param_filter);
    foreach my $type (@types) {
        my $method = join '_', grep { $_ } $type, 'parameters';
        my $params = $req->$method;
        next unless defined $params && ref $params && %$params;
        my $copy = { %$params };
        $is_filtered += _filter_hash_ref( $copy, @filters );
        if($is_filtered){
            $req->$method($copy);
        }
    }
    return $is_filtered;
}

sub _filter_hash_ref {
    my $hash        = shift;
    my @filters     = @_;
    my $is_filtered = 0;
    foreach my $k ( keys %$hash ) {
        foreach my $f (@filters) {
            my $copy = $k;
            my $filtered = $f->( $copy => $hash->{$k} );
            if ( defined $filtered ) {
                $hash->{$k} = $filtered;
                $is_filtered++;
                last;
            }
        }
    }
    return $is_filtered;
}

sub _filter_headers {
    my ( $config, $headers ) = @_;
    my @filters          = _normalize_filters( $config->{headers} );
    my $filtered_headers = HTTP::Headers->new();
    my $filtered         = 0;
    foreach my $name ( $headers->header_field_names ) {
        my @values = $headers->header($name);

        # headers can be multi-valued
        foreach my $value (@values) {
            foreach my $f (@filters) {
                my ( $copy_name, $copy_value ) = ( $name, $value );
                my $new_value = $f->( $copy_name, $copy_value );

                # if a defined value is returned, we use that
                if ( defined $new_value ) {
                    $value = $new_value;
                    $filtered++;
                    last;    # skip the rest of the filters
                }
            }
            $filtered_headers->push_header( $name, $value );
        }
    }
    return $filtered ? $filtered_headers : undef;
}

sub _filter_response {
    my ( $config, $res ) = @_;
    my $filtered = 0;
    if ( my $h = _filter_headers( $config, $res->headers ) ) {
        $res->headers($h);
        $filtered++;
    }
    return $filtered;
}

sub _filter_stash {
    my ( $config, $stash ) = @_;
    my @filters = _normalize_filters($config);
    return _filter_hash_ref($stash);
}

sub _filter_session {
    my ( $config, $stash ) = @_;
    my @filters = _normalize_filters($config);
    return _filter_hash_ref($stash);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::DebugFilter - Provides configurable filtering of data that is logged to the debug logs (and error screen)

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    package MyApp;

    use Catalyst;
    with 'CatalystX::DebugFilter';

    __PACKAGE__->config(
        'CatalystX::DebugFilter' => {

            # filter all "Cookie" headers as well as "password" and "SECRET" parameters
            Request => { headers => 'Cookie', params => [ 'password', qr/SECRET/ ] },

            # filter all Set-Cookie values in the response
            Response => { headers => 'Set-Cookie' },

            Stash => [
                sub {
                    my ( $key, $value ) = @_;
                    my $type = ref($value);

                    # ignore any non-ref values
                    return undef if !$type;

                    if ( $type->isa('DBIx::Class::ResultSet') ) {    # dump ResultSet objects as SQL
                        return $value->as_query;
                    } elsif ( $type->isa('DBIx::Class::Result') ) {    # dump Result objects as simple HASH
                        return { $value->get_columns };
                    } else {                                           # ignore these
                        return undef;
                    }
                },
            ],
            Session => [
                'secret_session_key'
            ],
        }
    );

=head1 DESCRIPTION

This module provides a Moose role that will filter certain elements of
a request/response/stash/session before they are logged to the debug logs (or
the error screen).

=head1 METHODS

=head2 dump_these

This role uses an "around" method modifier on the L<Catalyst/dump_these>
method and modifies the elements returned according to the configuration
provided by the user as demonstrated in the L<SYNOPSIS> section.

=head1 FILTER CONFIGURATION

There are few different types of filters that can be defined:

=over 4

=item * Exact Match

The parameter/header/stash key is compared against a literal string.
If it matches, the value is replaced with C<[FILTERED]>

=item * Regular Expression

The parameter/header/stash key is compared against a regular expression.
If it matches, the value is replaced with C<[FILTERED]>

=item * Callback

The parameter/header/stash key and value are passed to a callback
function.  If the function returns a defined value, that value is used
instead of the original value.

=back

This module supports filtering a few different types of data (naturally,
these could all be combined into a single C<config> call):

=over 4

=item * Request Parameters

    __PACKAGE__->config( 'CatalystX::DebugFilter' => { Request => { params => $filters } } );

=item * Request Headers

Useful with L<CatalystX::Debug::RequestHeaders>:

    __PACKAGE__->config( 'CatalystX::DebugFilter' => { Request => { headers => $filters } } );

=item * Response Headers

Useful with L<CatalystX::Debug::ResponseHeaders>:

    __PACKAGE__->config( 'CatalystX::DebugFilter' => { Response => { headers => $filters } } );

=item * Stash Data

    __PACKAGE__->config( 'CatalystX::DebugFilter' => { Stash => $filters } );

=back

In each of the above examples, C<$filters> can be one of a few things:

=over 4

=item * A non-ref scalar, implying an exact match

=item * A Regexp reference, implying an regular expression match

=item * A CODE reference, implying a callback matching function

=item * An ARRAY reference of any of the above

=back

=head1 CAVEATS

This module will not magically remove all references to a specific piece
of data unless filters are explicitly defined for each place this data
is stored.  For instance, you may define a request parameter filter to
prevent passwords from being logged to the debug logs but if you create
an object that contains that password and store it in the stash, the
password value may still appear on the error screen.

Also, the stash and session are only filtered at the top level.  If you
would like to filter more extensively, you can use a filter callback to
traverse the hash, modifying whatever data you like (a shallow copy is
made before passing the value to the callback).

=head1 SEE ALSO

=over 4

=item * L<CatalystX::Debug::RequestHeaders>

=item * L<CatalystX::Debug::ResponseHeaders>

=back

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
