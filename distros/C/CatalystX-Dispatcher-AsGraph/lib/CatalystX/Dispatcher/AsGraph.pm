package CatalystX::Dispatcher::AsGraph;

# ABSTRACT: Create a graph from Catalyst dispatcher

use MooseX::Declare;

our $VERSION = '0.03';

class CatalystX::Dispatcher::AsGraph {

    use Graph::Easy;
    with 'MooseX::Getopt';

    has [qw/appname output/] => (is => 'ro', isa => 'Str', required => 1);

    has graph => (
        traits  => ['NoGetopt'],
        is      => 'ro',
        default => sub { Graph::Easy->new }
    );
    has app => (
        traits  => ['NoGetopt'],
        is      => 'rw',
        isa     => 'Object',
        lazy    => 1,
        handles => [qw/dispatcher/],
        default => sub {
            my $self = shift;
            Class::MOP::load_class($self->appname);
            my $app = $self->appname->new;
            $app;
        }
    );

    method run{
        my $routes = $self->dispatcher->_tree;
        $self->_new_node($routes, '');
    }

    method _new_node($parent, $prefix) {
        my $name = $prefix . $parent->getNodeValue || '';
        my $node = $self->graph->add_node($name);

        my $actions = $parent->getNodeValue->actions;
        for my $action ( keys %{$actions} ) {
            next if ( ( $action =~ /^_.*/ ) );
            $self->graph->add_edge( $node, "[action] " . $action);
        }
        for my $child ( $parent->getAllChildren ) {
            my $child_node = $self->_new_node( $child, $name . ' -> ' );
            $self->graph->add_edge( $node, $child_node );
        }
        return $node;
    }
}

1;


__END__
=pod

=head1 NAME

CatalystX::Dispatcher::AsGraph - Create a graph from Catalyst dispatcher

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use CatalystX::Dispatcher::AsGraph;

    my $graph = CatalystX::Dispatcher::AsGraph->new(
        appname => 'MyApp',
        output  => 'myactions.png',
    );
    $graph->run;

=head1 DESCRIPTION

CatalystX::Dispatcher::AsGraph create a graph for a Catalyst application using his dispatcher.

At the time, only private actions are graphed.

=head1 SEE ALSO

L<http://www.catalystframework.org/calendar/2009/14>

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

