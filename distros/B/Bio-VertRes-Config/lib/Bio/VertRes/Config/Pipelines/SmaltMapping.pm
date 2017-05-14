package Bio::VertRes::Config::Pipelines::SmaltMapping;

# ABSTRACT: Base class for the smalt mapper


use Moose;
extends 'Bio::VertRes::Config::Pipelines::Mapping';

has 'slx_mapper'     => ( is => 'ro', isa => 'Str', default => 'smalt' );
has 'slx_mapper_exe' => ( is => 'ro', isa => 'Str', default => '/software/pathogen/external/apps/usr/local/smalt-0.7.4/smalt_x86_64' );

has 'additional_mapper_params' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'mapper_index_params'      => ( is => 'ro', isa => 'Maybe[Str]' );
has '_mapper_index_suffix'     => ( is => 'ro', isa => 'Maybe[Str]', lazy => 1, builder => '_build__mapper_index_suffix' );

sub _build__mapper_index_suffix {
    my ($self) = @_;
    if ( defined( $self->mapper_index_params ) ) {
        my $mapping_index_suffix = $self->mapper_index_params;
        $mapping_index_suffix =~ s![^\da-z]!!gi;
        return $mapping_index_suffix;
    }
    return undef;
}

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();

    $output_hash->{data}{additional_mapper_params} = $self->additional_mapper_params if ( defined( $self->additional_mapper_params ) );
    $output_hash->{data}{mapper_index_params}      = $self->mapper_index_params      if ( defined( $self->mapper_index_params ) );
    $output_hash->{data}{mapper_index_suffix}      = $self->_mapper_index_suffix     if ( defined( $self->_mapper_index_suffix ) );

    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::SmaltMapping - Base class for the smalt mapper

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

Base class for the smalt mapper. Can be used on its own as is, or more probably subclassed to provide a standard mapping method for a particular group.
   use Bio::VertRes::Config::Pipelines::SmaltMapping;

   my $pipeline = Bio::VertRes::Config::Pipelines::SmaltMapping->new(
     database => 'abc',
     reference => 'Staphylococcus_aureus_subsp_aureus_ABC_v1',
     limits => {
       project => ['ABC study'],
       species => ['EFG']
     },
     additional_mapper_params => '-x',
     mapper_index_params => '-s 5'
     );
   $pipeline->to_hash();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
