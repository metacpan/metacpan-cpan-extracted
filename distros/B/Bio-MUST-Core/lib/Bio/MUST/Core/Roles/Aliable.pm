package Bio::MUST::Core::Roles::Aliable;
# ABSTRACT: Aliable Moose role (pure interface) for Ali-like objects
$Bio::MUST::Core::Roles::Aliable::VERSION = '0.251810';
use Moose::Role;

use autodie;
use feature qw(say);

use Bio::MUST::Core::Types;


requires qw(
    count_comments all_comments get_comment
    guessing all_seq_ids has_uniq_ids is_protein is_aligned
    get_seq get_seq_with_id first_seq all_seqs filter_seqs count_seqs
    gapmiss_regex
);

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Roles::Aliable - Aliable Moose role (pure interface) for Ali-like objects

=head1 VERSION

version 0.251810

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
