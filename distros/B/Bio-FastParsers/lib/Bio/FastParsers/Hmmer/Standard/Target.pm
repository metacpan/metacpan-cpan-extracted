package Bio::FastParsers::Hmmer::Standard::Target;
# ABSTRACT: Internal class for standard HMMER parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::Standard::Target::VERSION = '0.201110';
use Moose;
use namespace::autoclean;

use List::AllUtils qw(indexes);

use aliased 'Bio::FastParsers::Hmmer::Standard::Domain';


# public attributes

# TODO: check if this an empty ArrayRef would not make more sense than Maybe
# We dont want smth else than a Domain in this ArrayRef
# so it is more a matter of precision than sense
has 'domains' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Maybe[Bio::FastParsers::Hmmer::Standard::Domain]]',
    required => 1,
    handles  => {
         next_domain  => 'shift',
          get_domain  => 'get',
          all_domains => 'elements',
        count_domains => 'count',
    },
);

with 'Bio::FastParsers::Roles::Targetable';

# parse Target block (raw)...
# ... and retrieve attrs from the corresponding line of hit table (Hit)

around BUILDARGS => sub {
    my ($orig, $class, $inargs) = @_;

    # retrieve lines still to parse as @raw...
    my @raw = @{ $inargs->{raw} };

    # recycle the anonymous HashRef already containing old Hit information
    # as the foundation for the new Target object
    my %outargs = %{ $inargs->{hit} };

    # add Target name
    ( $outargs{target_name} = $raw[0] ) =~ s/[\>\s+]//xmsg;

    # split Domain blocks
    my @domain_indexes = indexes { m/^\s+==/xms } @raw;

    # set as empty ArrayRef as --domE option can report Target without domain
    $outargs{domains} = [];
    if (@domain_indexes) {
        my @summary = grep {
            $_ =~ m/^\s+\d/xms
        } @raw[ 1 .. $domain_indexes[0]-1 ];

        for (my $i = 0; $i < @domain_indexes; $i++) {
            my @block = defined $domain_indexes[$i+1]
                        ? @raw[ $domain_indexes[$i] .. $domain_indexes[$i+1] ]
                        : splice @raw, $domain_indexes[$i]
            ;
            push @{ $outargs{domains} },
                Domain->new( { raw => \@block, summary => $summary[$i] } );
        }
    }

    # return expected constructor hash
    return $class->$orig(%outargs);
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer::Standard::Target - Internal class for standard HMMER parser

=head1 VERSION

version 0.201110

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
