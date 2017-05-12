#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Config;
# ABSTRACT: magpie configuration storage & retrieval
$App::Magpie::Config::VERSION = '2.010';
use Config::Tiny;
use File::HomeDir::PathClass;
use MooseX::Singleton;
use MooseX::Has::Sugar;

my $CONFIGDIR   = File::HomeDir::PathClass->my_dist_config( "App-Magpie", {create=>1} );
my $config_file = $CONFIGDIR->file( "config.ini" );

has _config => ( ro, isa => "Config::Tiny", lazy_build );

sub _build__config {
    my $self = shift;
    my $config = Config::Tiny->read( $config_file );
    $config  //= Config::Tiny->new;
    return $config;
}

# -- public methods


sub dump {
    my $self = shift;
    return $config_file->slurp;
}



sub get {
    my ($self, $section, $key) = @_;
    return $self->_config->{ $section }->{ $key };
}



sub set {
    my ($self, $section, $key, $value) = @_;
    my $config = $self->_config;
    $config->{ $section }->{ $key } = $value;
    $config->write( $config_file );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Config - magpie configuration storage & retrieval

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $config = App::Magpie::Config->instance;
    my $value  = $config->get( $section, $key );
    $config->set( $section, $key, $value );

=head1 DESCRIPTION

This module allows to store some configuration for magpie.

It implements a singleton responsible for automatic retrieving & saving
of the various information. No check is done on sections and keys, so
it's up to the caller to implement a proper config hierarchy.

=head1 METHODS

=head2 dump

    my $str = $config->dump;

Return the whole content of the configuration file.

=head2 get

    my $value = $config->get( $section, $key );

Return the value associated to C<$key> in the wanted C<$section>.

=head2 set

    $config->set( $section, $key, $value );

Store the C<$value> associated to C<$key> in the wanted C<$section>.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
