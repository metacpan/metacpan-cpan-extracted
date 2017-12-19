package Bio::MUST::Core::Ali::Stash;
# ABSTRACT: Thin wrapper for an indexed Ali read from disk
$Bio::MUST::Core::Ali::Stash::VERSION = '0.173500';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments;

use Carp;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:seqids);
use aliased 'Bio::MUST::Core::Ali';

# TODO: decide on which Ali/Listable methods should be available

has 'seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    handles  => [
        qw(count_comments all_comments get_comment
            all_seq_ids has_uniq_ids is_protein gapmiss_regex
            get_seq all_seqs count_seqs filter_seqs)
    ],
);


has 'lookup' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdList',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_lookup',
    handles  => [ qw(index_for) ],
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_lookup {
    return shift->seqs->new_lookup;
}

## use critic



sub get_seq_with_id {
    my $self = shift;
    my $id   = shift;

    # override Ali method with faster lookup-based alternative
    my $index = $self->index_for($id);
    return $self->get_seq($index)
        if defined $index;

    carp "Warning: cannot find seq with id: $id; returning undef!";
    return;
}


# I/O methods


sub load {
    my $class  = shift;
    my $infile = shift;
    my $args   = shift // {};           # HashRef (should not be empty...)

    ### Loading database <$infile>...
    ### Please be patient...
    my $seqs = Ali->load($infile);
       $seqs->dont_guess;
    ### Done!

    if ( $args->{truncate_ids} ) {
        ### Truncating ids on first whitespace...
        my $mapper = $seqs->regex_mapper( q{}, $DEF_ID );
        $seqs->shorten_ids($mapper);
    }

    return $class->new(seqs => $seqs);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Ali::Stash - Thin wrapper for an indexed Ali read from disk

=head1 VERSION

version 0.173500

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 load

=head1 ACCESSORS

=head2 get_seq_with_id

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
