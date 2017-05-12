package APISchema::Schema;
use strict;
use warnings;
use 5.014;

use APISchema::Route;
use APISchema::Resource;

use Class::Accessor::Lite (
    rw => [qw(title description)],
);

sub new {
    my ($class) = @_;

    bless {
        resources => {},
        routes => [],
    }, $class;
}

sub register_resource {
    my ($self, $title, $definition) = @_;

    my $resource = APISchema::Resource->new(
        title => $title,
        definition => $definition,
    );
    $self->{resources}->{$title} = $resource;

    return $resource;
}

sub get_resources {
    my ($self) = @_;

    [ sort { $a->title cmp $b->title } values %{$self->{resources}} ];
}

sub get_resource_by_name {
    my ($self, $name) = @_;

    $self->{resources}->{$name || ''};
}

sub get_resource_root {
    my ($self) = @_;
    return +{
        resource   => +{ map {
            $_ => $self->{resources}->{$_}->definition;
        } keys %{$self->{resources}} },
        properties => {},
    };
}

sub _next_title_candidate {
    my ($self, $base_title) = @_;
    if ($base_title =~ /\(([0-9]+)\)$/) {
        my $index = $1 + 1;
        return $base_title =~ s/\([0-9]+\)$/($index)/r;
    } else {
        return $base_title . '(1)';
    }
}

sub register_route {
     my ($self, %values) = @_;

     # make fresh title
     my $title = $values{title} // $values{route} // 'empty_route';
     while ($self->get_route_by_name($title)) {
         $title = $self->_next_title_candidate($title);
     }

     my $route = APISchema::Route->new(
         %values,
         title => $title,
     );
     push @{$self->{routes}}, $route;
     return $route;
}

sub get_routes {
    my ($self) = @_;

    $self->{routes};
}

sub get_route_by_name {
    my ($self, $name) = @_;
    my ($route) = grep { ($_->title||'') eq $name } @{$self->get_routes};
    return $route;
}

1;
