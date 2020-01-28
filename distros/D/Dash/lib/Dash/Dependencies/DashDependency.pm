package Dash::Dependencies::DashDependency;

use Moo;
use strictures 2;
use namespace::clean;
use overload '""' => "_stringify";

has component_id => ( is => 'ro' );

has component_property => ( is => 'ro' );

sub _stringify {
    my $self = shift;
    return $self->component_id . "." . $self->component_property;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Dependencies::DashDependency

=head1 VERSION

version 0.10

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
