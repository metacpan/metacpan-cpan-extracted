package Bio::MUST::Drivers::Hmmer::Model;
# ABSTRACT: Internal class for HMMER3 driver
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::MUST::Drivers::Hmmer::Model::VERSION = '0.191910';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;

extends 'Bio::FastParsers::Hmmer::Model';
with 'Bio::MUST::Drivers::Roles::Hmmerable' => {
    -excludes => [ qw(scan) ]
};


sub model {
    return shift;       # for consistency with Model::Temporary
}

sub remove {            # overload Bio::FastParsers method
    carp '[BMD] Warning: ' . shift->meta->name . ' forbids model file removal;'
        . ' ignoring request!';
    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::Hmmer::Model - Internal class for HMMER3 driver

=head1 VERSION

version 0.191910

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Arnaud DI FRANCO

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
