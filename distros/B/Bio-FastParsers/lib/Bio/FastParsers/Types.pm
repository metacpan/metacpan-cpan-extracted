package Bio::FastParsers::Types;
# ABSTRACT: Distribution-wide Moose types for Bio::FastParsers
$Bio::FastParsers::Types::VERSION = '0.173450';
use Moose::Util::TypeConstraints;

use autodie;
use feature qw(say);

use Path::Class qw(file);


# subtype for 'file' attributes
subtype 'Bio::FastParsers::Types::File'
    => as 'Path::Class::File'
;

# avoid the need for 'isa' unions such as 'Str|Path::Class::File'...
# ... and allow delegating to Path::Class::File methods (e.g., remove)
coerce 'Bio::FastParsers::Types::File'
    => from 'Str'
    => via { file($_) }
;


no Moose::Util::TypeConstraints;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Types - Distribution-wide Moose types for Bio::FastParsers

=head1 VERSION

version 0.173450

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
