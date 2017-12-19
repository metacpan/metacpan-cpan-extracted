package Bio::MUST::Core::Ali::Temporary;
# ABSTRACT: Thin wrapper for a temporary ungapped mapped Ali written on disk
$Bio::MUST::Core::Ali::Temporary::VERSION = '0.173500';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::MUST::Core::Types;

# Note: tried to implement it as a subclass of Bio::MUST::Core::Ali but this
# led to issues: (1) coercions became a nightmare and (2) the temp_fasta was
# written as soon as the Ali was created and thus was empty

# TODO: decide on which Ali/Listable methods should be available
# TODO: allows to specify the directory for the temp file (File::Temp tmpdir)

has 'seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
    handles  => [
        qw(count_comments all_comments get_comment
            all_seq_ids has_uniq_ids is_protein gapmiss_regex
            get_seq all_seqs count_seqs filter_seqs)
    ],
);


has 'file' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::File',
    init_arg => undef,
    coerce   => 1,
    writer   => '_set_file',
    handles  => {
        remove   => 'remove',
        filename => 'stringify',
    },
);


has 'mapper' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdMapper',
    init_arg => undef,
    writer   => '_set_mapper',
    handles  => [ qw(all_long_ids all_abbr_ids long_id_for abbr_id_for) ],
);


sub BUILD {
    my $self = shift;

    # write temp degapped FASTA file
    my $ali = $self->seqs;
    my ($filename, $mapper) = $ali->temp_fasta( { clean => 1, degap => 1 } );
    $self->_set_file($filename);
    $self->_set_mapper($mapper);

    return;
}


sub DEMOLISH {
    my $self = shift;

    # TODO: allow for more control on this
    $self->remove;

    # Note: I know I could use UNLINK => 1 in File::Temp constuctor
    # but this would need to be done in Ali::temp_fasta and would prevent
    # keeping around a temp file for debugging purposes

    return;
}


# TODO: check whether another place would be more suitable

sub type {
    my $self = shift;
    return $self->is_protein ? 'prot' : 'nucl';
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Ali::Temporary - Thin wrapper for a temporary ungapped mapped Ali written on disk

=head1 VERSION

version 0.173500

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
