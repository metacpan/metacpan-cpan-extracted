package Bio::VertRes::Config::Pipelines::SpadesAssembly;

# ABSTRACT: A base class for generating an Assembly pipeline config file using spades



use Moose;
extends 'Bio::VertRes::Config::Pipelines::Assembly';

has '_assembler'           => ( is => 'ro', isa => 'Str',  default => 'spades' );
has '_assembler_exec'      => ( is => 'ro', isa => 'Str',  default => '/software/pathogen/external/apps/usr/bin/spades.py' );
has '_optimiser_exec'      => ( is => 'ro', isa => 'Str',  default => '/software/pathogen/external/apps/usr/bin/spades.py' );
has '_max_threads'         => ( is => 'ro', isa => 'Int',  default => 2 );
has '_single_cell'         => ( is => 'ro', isa => 'Bool',  default => 0 );

override 'to_hash' => sub {
    my ($self) = @_;
    my $output_hash = super();

    $output_hash->{data}{single_cell} = $self->_single_cell;

    return $output_hash;
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Bio::VertRes::Config::Pipelines::SpadesAssembly - A base class for generating an Assembly pipeline config file using spades

=head1 VERSION

version 1.133090

=head1 SYNOPSIS

A class for generating the Assembly pipeline config file using the velvet assembler
   use Bio::VertRes::Config::Pipelines::SpadesAssembly;

   my $pipeline = Bio::VertRes::Config::Pipelines::SpadesAssembly->new(database    => 'abc'
                                                                       config_base => '/path/to/config/base',
                                                                       limits      => { project => ['project name']);
   $pipeline->to_hash();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
