package Bio::FastParsers::Roles::Clusterable;
# ABSTRACT: Attributes and methods common to CD-HIT and UCLUST drivers
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::FastParsers::Roles::Clusterable::VERSION = '0.213510';
use Moose::Role;

use autodie;
use feature qw(say);

use Carp;
use Sort::Naturally;
use Try::Tiny;


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


sub clust_mapper {
    my $self = shift;
    my $sep  = shift // q{/};

    # do not force Bio::FastParsers to depend on Bio::MUST::Core
    my $bmc = try   { require Bio::MUST::Core }
              catch { return }
    ;
    unless ($bmc) {
        carp 'Warning: Bio::MUST::Core not installed; returning nothing!';
        return;
    }

    my @abbr_ids;
    my @long_ids;

    for my $repr ( $self->all_representatives_by_cluster_size ) {
    	push @abbr_ids, $repr;
    	push @long_ids, join $sep,
    	    nsort ( @{ $self->members_for($repr) }, $repr )
    	;
    }

    return Bio::MUST::Core::IdMapper->new(
        abbr_ids => \@abbr_ids,
        long_ids => \@long_ids,
    );
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Roles::Clusterable - Attributes and methods common to CD-HIT and UCLUST drivers

=head1 VERSION

version 0.213510

=head1 DESCRIPTION

This role implements the attributes and methods that are common to CD-HIT and
UCLUST parsers. Those are documented in their respective modules:
L<Bio::FastParsers::CdHit> and L<Bio::FastParsers::Uclust>.

Available methods are: C<all_representatives>,
C<all_representatives_by_cluster_size>, C<members_for> and C<clust_mapper>.

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
