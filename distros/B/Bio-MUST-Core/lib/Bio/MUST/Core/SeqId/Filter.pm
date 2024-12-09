package Bio::MUST::Core::SeqId::Filter;
# ABSTRACT: Helper class for filtering seqs according to SeqId components
$Bio::MUST::Core::SeqId::Filter::VERSION = '0.243430';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use Bio::MUST::Core::Types;
with 'Bio::MUST::Core::Roles::Filterable';


sub is_allowed {
    my $self   = shift;
    my $seq_id = shift;

    my $family = $seq_id->family;
    return undef unless $family;    ## no critic (ProhibitExplicitReturnUndef)

    return 0 unless $self->is_wanted(  $family);
    return 0     if $self->is_unwanted($family);
    return 1;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::SeqId::Filter - Helper class for filtering seqs according to SeqId components

=head1 VERSION

version 0.243430

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 is_allowed

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
