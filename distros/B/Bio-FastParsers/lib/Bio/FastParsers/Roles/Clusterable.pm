package Bio::FastParsers::Roles::Clusterable;
# ABSTRACT: Attrs and methods common to CD-HIT and UCLUST drivers
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::FastParsers::Roles::Clusterable::VERSION = '0.180330';
use Moose::Role;

use autodie;
use feature qw(say);

use Sort::Naturally;


# private attributes

has '_members_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Str]]',
    init_arg => undef,
    writer   => '_set_members_for',
    handles  => {
        all_representatives => 'keys',
            members_for     => 'get',
    },
);


sub all_representatives_by_cluster_size {
    my $self = shift;

    # sort first on descending cluster size then on representative id
    # using natural sort and the Schwartzian transform
    my @list = map {                                       $_->[1]  }
              sort {  $b->[0] <=> $a->[0] || ncmp($a->[1], $b->[1]) }
               map { [ scalar @{ $self->members_for($_) }, $_    ]  }
        $self->all_representatives
    ;

    return @list;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Roles::Clusterable - Attrs and methods common to CD-HIT and UCLUST drivers

=head1 VERSION

version 0.180330

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Amandine BERTRAND

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
