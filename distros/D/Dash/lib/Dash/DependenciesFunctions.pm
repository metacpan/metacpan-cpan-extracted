package Dash::DependenciesFunctions;

use warnings;
use strict;
use utf8;

use Dash::Dependencies::Output;
use Dash::Dependencies::Input;
use Dash::Dependencies::State;
use Exporter::Auto;

sub Output {
    my @params = @_;
    if ( scalar @_ == 2 ) {
        @params = ( component_id => $_[0], component_property => $_[1] );
    }
    return Dash::Dependencies::Output->new(@params);
}

sub Input {
    my @params = @_;
    if ( scalar @_ == 2 ) {
        @params = ( component_id => $_[0], component_property => $_[1] );
    }
    return Dash::Dependencies::Input->new(@params);

}

sub State {
    my @params = @_;
    if ( scalar @_ == 2 ) {
        @params = ( component_id => $_[0], component_property => $_[1] );
    }
    return Dash::Dependencies::State->new(@params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::DependenciesFunctions

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
