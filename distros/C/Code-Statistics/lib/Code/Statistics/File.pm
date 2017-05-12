use strict;
use warnings;

package Code::Statistics::File;
{
  $Code::Statistics::File::VERSION = '1.112980';
}

# ABSTRACT: loads a file, searches for targets in it and measures their metrics

use 5.004;

use Moose;
use MooseX::HasDefaults::RO;
use Code::Statistics::MooseTypes;

use PPI::Document;
use Path::Class qw(file);

has relative_paths => ( isa => 'Bool' );
has foreign_paths => ( isa => 'Str' );

has path => (
    isa      => 'Str',
    required => 1,
);

has original_path => (
    isa      => 'Str',
    required => 1,
);

has targets => (
    isa     => 'CS::InputList',
    coerce  => 1,
);

has metrics => (
    isa     => 'CS::InputList',
    coerce  => 1,
);

has ppi => (
    isa     => 'PPI::Document',
    lazy    => 1,
    default => sub {
        PPI::Document->new( $_[0]->path );
    },
);

has progress => ( isa => 'CodeRef' );


sub analyze {
    my ( $self ) = @_;

    $self->_process_target_class( $_ ) for @{ $self->targets };
    $self->_format_file_path;
    $self->progress->();

    return $self;
}

sub _format_file_path {
    my ( $self ) = @_;
    my $path = file( $self->path );

    $path = $path->relative if $self->relative_paths;
    $path = $path->absolute if !$self->relative_paths;

    $path = $path->as_foreign( $self->foreign_paths ) if $self->foreign_paths;

    $self->{path} = $path->stringify;
    return $self;
}

sub _process_target_class {
    my ( $self, $target_type ) = @_;

    my @supported_metrics = grep $self->_are_compatible( $target_type, $_ ), @{ $self->metrics };
    return if !@supported_metrics;

    my $targets = "Code::Statistics::Target::$target_type"->find_targets( $self );
    return if !$targets;

    my @measurements = map _measure_target( $_, @supported_metrics ), @{$targets};
    $self->{measurements}{$target_type} = \@measurements;

    return $self;
}

sub _are_compatible {
    my ( $self, $target, $metric ) = @_;
    return 1 if "Code::Statistics::Target::$target"->force_support( $metric );
    return 1 if "Code::Statistics::Metric::$metric"->force_support( $target );
    return 0 if "Code::Statistics::Target::$target"->incompatible_with( $metric );
    return 0 if "Code::Statistics::Metric::$metric"->incompatible_with( $target );
    return 1;
}

sub _measure_target {
    my ( $target, @metrics ) = @_;

    my %measurement;
    $measurement{$_} = "Code::Statistics::Metric::$_"->measure( $target ) for @metrics;

    return \%measurement;
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::File - loads a file, searches for targets in it and measures their metrics

=head1 VERSION

version 1.112980

=head2 analyze
    Finds targets in the given file and collects the metrics on those.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

