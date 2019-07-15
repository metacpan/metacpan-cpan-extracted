package Bio::MUST::Drivers::Blast::Database;
# ABSTRACT: Internal class for BLAST driver
$Bio::MUST::Drivers::Blast::Database::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;

extends 'Bio::FastParsers::Base';

# TODO: warn user that we need to build db with -parse_seqids

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    writer   => '_set_type',
);

has 'remote' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

with 'Bio::MUST::Drivers::Roles::Blastable';

# TODO: complete this with list of NCBI databases
# http://ncbiinsights.ncbi.nlm.nih.gov/2013/03/19/\
# blastdbinfo-api-access-to-a-database-of-blast-databases/
my %type_for = (            # cannot be made constant to allow undefined keys
    nt => 'nucl',
    nr => 'prot',
);

sub BUILD {
    my $self = shift;

    my $basename = $self->filename;

    # check for existence of BLAST database and set its type (nucl or prot)
    if ($self->remote) {
        $self->_set_type( $type_for{$basename} );
    }
    elsif (-e "$basename.psq" || -e "$basename.pal") {
        $self->_set_type('prot');
    }
    elsif (-e "$basename.nsq" || -e "$basename.nal") {
        $self->_set_type('nucl');
    }
    else {
        croak "[BMD] Error: BLAST database not found at $basename; aborting!";
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Blast::Database - Internal class for BLAST driver

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
