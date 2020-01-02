package Dash::BaseComponent;

use Mojo::Base -base;

sub DashNamespace {
    return 'no_namespace';
}

sub TO_JSON {
    my $self       = shift;
    my @components = split( /::/, ref($self) );
    my $type       = $components[-1];
    my %hash       = %$self;
    return { type      => $type,
             namespace => $self->DashNamespace,
             props     => \%hash
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::BaseComponent

=head1 VERSION

version 0.04

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
