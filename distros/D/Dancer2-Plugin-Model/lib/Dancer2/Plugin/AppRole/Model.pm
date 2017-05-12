package Dancer2::Plugin::AppRole::Model;

use strictures 2;

use Module::Runtime 'use_module';
use Types::Standard 'HashRef';

use Moo::Role;

our $VERSION = '1.152120'; # VERSION

# ABSTRACT: role for the gantry to hang a model layer onto Dancer2

#
# This file is part of Dancer2-Plugin-Model
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

has model =>    #
  is      => "rw",
  lazy    => 1,
  builder => sub {
    my ( $self ) = @_;

    for ( $self->setting( "parent_model" ) ) { return $_ if $_ }

    my %args  = %{ $self->model_args };
    my $model = use_module( $self->name . "::Model" )->new( %args );
    return $model;
  };

has model_args =>    #
  ( is => 'rw', isa => HashRef, lazy => 1, builder => sub { {} } );

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::AppRole::Model - role for the gantry to hang a model layer onto Dancer2

=head1 VERSION

version 1.152120

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
