package Data::Dataset::Classic::Adapter::PDL::Matrix;

use strict;
use warnings;
use utf8;

use Module::Load;

our $VERSION = '0.001';    # VERSION

# ABSTRACT: Adapter for PDL::Matrix

sub new {
    my $class_name = shift();
    return bless( {}, $class_name );
}

sub from {
    my $self = shift();
    my $data = shift();

    Module::Load::autoload PDL;
    Module::Load::load PDL::Matrix;
    my @keys = sort keys %$data;
    my $pdl_matrix = PDL::Matrix->pdl( [ @{$data}{@keys} ] );
    return transpose $pdl_matrix;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Dataset::Classic::Adapter::PDL::Matrix - Adapter for PDL::Matrix

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	use Data::Dataset::Classic::Anscombe
	my $anscombe = Data::Dataset::Classic::Anscombe::get(as => 'PDL::Matrix')

=head1 DESCRIPTION

Adapts a Data::Dataset::Classic to a PDL::Matrix object. 

=head1 METHODS

=head2 new

Constructs a new adapter

=head2 from

Construct a PDL::Matrix object from a Data::Dataset::Classic

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
