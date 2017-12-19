package Bio::FastParsers::CdHit;
# ABSTRACT: front-end class for CD-HIT parser
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
$Bio::FastParsers::CdHit::VERSION = '0.173510';
use Moose;
use namespace::autoclean;

use autodie;

use Tie::IxHash;

extends 'Bio::FastParsers::Base';


# public attributes (inherited)



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


sub BUILD {
    my $self = shift;

    my $cluster_like = qr{\>Cluster \s (\d+)}xms;
    my $repr_id_like = qr{\d+ \t \d+\w{2}\, \s \>([\w\|\.]+) .{4} \*      }xms;
    my $memb_id_like = qr{\d+ \t \d+\w{2}\, \s \>([\w\|\.]+) .{4} at .* \%}xms;

    my $infile = $self->filename;
    open my $in, '<', $infile;

    tie my %members_for, 'Tie::IxHash';

    my $repr_id;
    my @members;

    while (my $line = <$in>) {
        chomp $line;

        if ($line =~ $cluster_like){
            #### cluster: $line
            push @{ $members_for{$repr_id} }, @members
                if $repr_id;
            $repr_id = q{};
            @members = ();
            #### $repr_id
            #### @members
            #### %members_for
        }

        elsif ($line =~ $repr_id_like) {
            #### reference sequence: $line
            $repr_id = $1;
            #### $repr_id
        }

        # find other seq (array)
        elsif ($line =~ $memb_id_like){
            #### member sequence: $line
            my $memb_id = $1;
            push @members, $memb_id;
            #### @members
        }
    }

    push @{ $members_for{$repr_id} }, @members
        if $repr_id;
    #### %members_for

    # store representative and member sequence ids
    $self->_set_members_for(\%members_for);

    return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::CdHit - front-end class for CD-HIT parser

=head1 VERSION

version 0.173510

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to CD-HIT report file to be parsed

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
