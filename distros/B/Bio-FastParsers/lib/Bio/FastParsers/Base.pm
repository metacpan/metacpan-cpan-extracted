package Bio::FastParsers::Base;
# ABSTRACT: internal (base) class for all FastParsers
$Bio::FastParsers::Base::VERSION = '0.173510';
use Moose;
use namespace::autoclean;

use Bio::FastParsers::Types;


# public attributes


has 'file' => (
    is       => 'ro',                   
    isa      => 'Bio::FastParsers::Types::File',
    required => 1,
    coerce   => 1,
    handles  => {
        remove   => 'remove',
        filename => 'stringify',
    },
);

# TODO: document and test delegated methods (now done in Bio-MUST-Drivers)

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Base - internal (base) class for all FastParsers

=head1 VERSION

version 0.173510

=head1 SYNOPSIS

    # TODO    

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to report file to be parsed

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
