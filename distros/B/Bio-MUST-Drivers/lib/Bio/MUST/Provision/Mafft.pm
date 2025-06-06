package Bio::MUST::Provision::Mafft;
# ABSTRACT: Internal class for app provisioning system
$Bio::MUST::Provision::Mafft::VERSION = '0.251060';
# AUTOGENERATED CODE! DO NOT MODIFY THIS FILE!

use Modern::Perl '2011';
use Carp;

use parent qw(App::Provision::Tiny);


sub deps { return qw(brew) }

sub condition {
    my $self = shift;

    my $condition = qx{which mafft} =~ m/mafft$/xms;
    carp '[BMD] Note: MAFFT executable not found; I can try brewing it.'
        unless $condition;

    return $condition ? 1 : 0;
}

sub meet {
    my $self = shift;

    return $self->recipe(
        ['brew tap brewsci/bio'],
        ['brew install mafft'],
    );
}

1;

__END__

=pod

=head1 NAME

Bio::MUST::Provision::Mafft - Internal class for app provisioning system

=head1 VERSION

version 0.251060

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
