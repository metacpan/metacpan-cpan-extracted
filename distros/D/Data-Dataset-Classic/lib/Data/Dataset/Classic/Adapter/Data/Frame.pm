package Data::Dataset::Classic::Adapter::Data::Frame;

use strict;
use warnings;
use utf8;

use Module::Load;

our $VERSION = '0.001';    # VERSION

# ABSTRACT: Adapter for Data::Frame

sub new {
    my $class_name = shift();
    return bless( {}, $class_name );
}

sub from {
    my $self = shift();
    my $data = shift();

    my $class_name = 'Data::Frame';
    Module::Load::load $class_name;
    Module::Load::autoload PDL;
    my @keys = sort keys %$data;
    my $data_frame = $class_name->new( columns => [ map { ( $_ => pdl( $data->{$_} ) ) } @keys ] );
    return $data_frame;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Dataset::Classic::Adapter::Data::Frame - Adapter for Data::Frame

=head1 VERSION

version 0.001

=head1 SYNOPSIS

	use Data::Dataset::Classic::Anscombe
	my $anscombe = Data::Dataset::Classic::Anscombe::get(as => 'PDL')

=head1 DESCRIPTION

Adapts a Data::Dataset::Classic to a PDL object. 

=head1 METHODS

=head2 new

Constructs a new adapter

=head2 from

Construct a Data::Frame object from a Data::Dataset::Classic

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
