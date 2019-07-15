package Bio::MUST::Drivers::Hmmer::Model::Database;
# ABSTRACT: Internal class for HMMER3 driver
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>
$Bio::MUST::Drivers::Hmmer::Model::Database::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use List::AllUtils;

extends 'Bio::FastParsers::Base';

with 'Bio::MUST::Drivers::Roles::Hmmerable' => {
    -excludes => [ qw(search emit) ]
};


sub BUILD {
    my $self = shift;

    # check for existence of HMMER database
    my $basename = $self->filename;
    unless ( List::AllUtils::all { -e "$basename.h3$_" } qw(f i m p) ) {
        croak "[BMD] Error: HMMER database not found at $basename; aborting!";
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Hmmer::Model::Database - Internal class for HMMER3 driver

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Loic MEUNIER

Loic MEUNIER <loic.meunier@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
