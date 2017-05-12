package Dancer::Plugin::Chain;
BEGIN {
  $Dancer::Plugin::Chain::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Chained actions for Dancer
$Dancer::Plugin::Chain::VERSION = '0.1.0';
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

register chain => sub {
    my $link = Dancer::Plugin::Chain::Link->new( args => [ @_ ] );
    
    return wantarray ? $link->as_route : $link;
};

register_plugin;

package 
    Dancer::Plugin::Chain::Link;

use Moose;

has "path_segments" => (
    traits => [ qw/ Array /],
    isa => 'ArrayRef',
    is => 'ro',
    default => sub { [] },
    handles => {
        add_to_path       => 'push',
        all_path_segments => 'elements'
    },
);

sub path {
    my $self = shift;
    return join '', $self->all_path_segments;
}

has code_blocks => (
    traits => [ qw/ Array /],
    isa => 'ArrayRef',
    is => 'ro',
    default => sub { [] },
    handles => {
        add_to_code     => 'push',
        all_code_blocks => 'elements'
    },
);

sub code {
    my $self = shift;

    my @code = $self->all_code_blocks;
    return sub {
        my $result;
        $result = $_->(@_) for @code;
        return $result;
    }
}

sub BUILD {
    my $self = shift;
    my @args = @{ $_[0]{args} };

    my $code;
    $code = pop @args if ref $args[-1] eq 'CODE';

    for my $segment ( @args ) {
        if ( ref $segment eq __PACKAGE__ ) {
            $self->add_to_path( $segment->all_path_segments );
            $self->add_to_code( $segment->all_code_blocks );
        }
        elsif( ref $segment eq 'CODE' ) {
            $self->add_to_code($segment);
        } 
        else {
            $self->add_to_path( $segment );
        }
    }

    $self->add_to_code($code) if $code;
}

sub as_route {
    my $self = shift;

    return ( $self->path, $self->code );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Dancer::Plugin::Chain - Chained actions for Dancer

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Chain;

    my $country = chain '/country/:country' => sub {
        # silly example. Typically much more work would 
        # go on in here
        var 'site' => param('country');
    };

    my $event = chain '/event/:event' => sub {
        var 'event' => param('event');
    };

    # will match /country/usa/event/yapc
    get chain $country, $event, '/schedule' => sub {
        return sprintf "schedule of %s in %s\n", map { var $_ } 
                       qw/ event site /;
    };

    my $continent = chain '/continent/:continent' => sub {
        var 'site' => param('continent');
    };

    my $continent_event = chain $continent, $event;

    # will match /continent/europe/event/yapc
    get chain $continent_event, '/schedule' => sub {
        return sprintf "schedule of %s in %s\n", map { var $_ } qw/ event site /;
    };

    # will match /continent/asia/country/japan/event/yapc
    # and will do special munging in-between!

    get chain $continent, 
            sub { var temp => var 'site' },
            $country, 
            sub {
                var 'site' => join ', ', map { var $_ } qw/ site temp /
            },
            $event, 
            '/schedule' 
                => sub {
                    return sprintf "schedule of %s in %s\n", map { var $_ } 
                                qw/ event site /;
            };

=head1 DESCRIPTION

Implementation of Catalyst-like chained routes.

The plugin exports a single keyword, C<chain>, which creates the chained
routes. 

=head2 KNOWN CAVEATS

The plugin does not support C<prefix> yet, and only support string-based urls
(so no regexes).

=head1 EXPORTED FUNCTIONS

=head2 chain @chain_items, $coderef

Create a chain out of the items provided, and assign it the final action coderef.

Each chain item can be
a string representing a path segment, a previously defined chain or an
anonymous function. The chain's final path and action will be the aggregate of
its parts. 

For example, the final route declaration of the  SYNOPSIS,

    get chain $continent, 
            sub { var temp => var 'site' },
            $country, 
            sub {
                var 'site' => join ', ', map { var $_ } qw/ site temp /
            },
            $event, 
            '/schedule' 
                => sub {
                    return sprintf "schedule of %s in %s\n", map { var $_ } 
                                qw/ event site /;
            };

would be is equivalent to 

    get '/continent/:continent/country/:country/event/:event/schedule' => sub {
        var 'site' => param('continent');
        var temp => var 'site';
        var 'site' => param('country');
        var 'site' => join ', ', map { var $_ } qw/ site temp /
        var 'event' => param('event');

        return sprintf "schedule of %s in %s\n", map { var $_ } 
                        qw/ event site /;
    }

In scalar context, C<chain> returns its underlying object. 
In list context, it returns a route / action pair of values (). That's how it
can work transparently with C<get>, C<post> and friends.

    # returns the object, that can be used to forge longer chains.
    my $foo_chain = chain '/foo', sub { ... };

    # returns the pair that makes 'get' happy
    get chain $foo_chain;

=head1 SEE ALSO

=over

=item *

Original blog entry: L<http://techblog.babyl.ca/entry/dancer-in-chains>

=item *

L<Dancer-Plugin-Dispatcher>

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
