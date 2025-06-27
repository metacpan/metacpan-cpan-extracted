package Bio::MUST::Apps::OmpaPa::Types;
# ABSTRACT: Distribution-wide Moose types for Bio::MUST::Apps::OmpaPa
$Bio::MUST::Apps::OmpaPa::Types::VERSION = '0.251770';
use Moose::Util::TypeConstraints;

use autodie;
use feature qw(say);

use Path::Class qw(dir file);

# declare types without loading corresponding classes
class_type('Bio::MUST::Apps::OmpaPa::Parameters');

coerce 'Bio::MUST::Apps::OmpaPa::Parameters'
    => from 'Path::Class::File'
    => via { Bio::MUST::Apps::OmpaPa::Parameters->load( $_->stringify ) }

    => from 'Str'
    => via { Bio::MUST::Apps::OmpaPa::Parameters->load( $_ ) }
;

no Moose::Util::TypeConstraints;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::OmpaPa::Types - Distribution-wide Moose types for Bio::MUST::Apps::OmpaPa

=head1 VERSION

version 0.251770

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
