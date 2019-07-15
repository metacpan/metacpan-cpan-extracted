package Bio::MUST::Drivers::Exonerate::Sugar;
# ABSTRACT: Internal class for exonerate driver
$Bio::MUST::Drivers::Exonerate::Sugar::VERSION = '0.191910';
use Moose;
use namespace::autoclean;


has $_ => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
) for qw(
    query_id target_id
);

has $_ => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
) for qw(
     query_start  query_end  query_strand
    target_start target_end target_strand
    score
);

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Exonerate::Sugar - Internal class for exonerate driver

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
