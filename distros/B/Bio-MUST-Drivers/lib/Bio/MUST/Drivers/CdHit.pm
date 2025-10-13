package Bio::MUST::Drivers::CdHit;
# ABSTRACT: Bio::MUST driver for running the CD-HIT program
# CONTRIBUTOR: Amandine BERTRAND <amandine.bertrand@doct.uliege.be>
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>
$Bio::MUST::Drivers::CdHit::VERSION = '0.252830';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Array::Utils qw(:all);
use Carp;
use IPC::System::Simple qw(system);
use List::AllUtils qw(sort_by);
use Module::Runtime qw(use_module);
use Path::Class qw(file);
use Tie::IxHash;

use Bio::MUST::Core;
extends 'Bio::MUST::Core::Ali::Temporary';

use Bio::MUST::Drivers::Utils qw(stringify_args);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::FastParsers::CdHit';


has 'cdhit_args' => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { {} },
);

has '_cluster_seq_ids' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Bio::MUST::Core::SeqId]]',
    init_arg => undef,
    writer   => '_set_cluster_seq_ids',
    handles  => {
        all_cluster_names   => 'keys',
        all_cluster_seq_ids => 'values',
        seq_ids_for         => 'get',
    },
);

has '_representatives' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    init_arg => undef,
    writer   => '_set_representatives',
    handles  => {
          all_representatives        =>   'all_seqs',
        count_representatives        => 'count_seqs',
          get_representative_with_id =>   'get_seq_with_id',    # useless?
    },
);

has '_representative_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bio::MUST::Core::Seq]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_representative_for',
    handles  => {
        all_member_names   => 'keys',
        representative_for => 'get',
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_representative_for {
    my $self = shift;

    my %representative_for;
    for my $repr ( $self->all_cluster_names ) {
        for my $id ( @{ $self->seq_ids_for($repr) } ) {
            $representative_for{ $id->full_id }
                = $self->get_representative_with_id($repr);
        }
    }

    return \%representative_for;
}

## use critic

sub BUILD {
    my $self = shift;

    # provision executable
    my $app = use_module('Bio::MUST::Provision::CdHit')->new;
       $app->meet();

    # setup output files
    my $infile   = $self->filename;
    my $basename = $infile . '.cdhit';
    my $outfile  = $basename . '.out';
    my $outfile_clstr  = $basename . '.out.clstr';

    # format cd-hit (optional) arguments
    my $args = $self->cdhit_args;
    my $args_str = stringify_args($args);

    # create cd-hit (or cd-hit-est) command
    my $pgm = $self->type eq 'prot' ? 'cd-hit' : 'cd-hit-est';
    my $cmd = "$pgm -i $infile -o $outfile $args_str > /dev/null 2> /dev/null";
    #### $cmd

    # try to robustly execute cd-hit
    my $ret_code = system( [ 0, 127 ], $cmd);
    if ($ret_code == 127) {
        carp "[BMD] Warning: cannot execute $pgm command;"
            . ' returning without contigs!';
        return;
    }
    # TODO: try to bypass shell (need for absolute path to executable then)

    # parse output file
    my $parser = CdHit->new(file => $outfile_clstr);
    my $mapper = $self->mapper;

    # restore original ids for cluster members...
    tie my %cluster_seq_ids, 'Tie::IxHash';
    for my $abbr_id ( $parser->all_representatives ) {
        my @member_ids = map {
            SeqId->new( full_id => $mapper->long_id_for($_) )
        } @{ $parser->members_for($abbr_id) // [] };
        $cluster_seq_ids{ $mapper->long_id_for($abbr_id) } = \@member_ids;
    }

    # ... and store cluster members
    $self->_set_cluster_seq_ids(\%cluster_seq_ids);

    # read and store representative seqs...
    my $representatives = Ali->load($outfile);
    $representatives->dont_guess;
    $representatives->restore_ids($mapper);     # ... restoring original ids
    $self->_set_representatives($representatives);

    # unlink temp files
    file($_)->remove for $outfile, $outfile_clstr;

    return;
}

# TODO: test this
sub filter_clusters {
    my $self = shift;
    my $list = shift;
    my $key  = shift // 'classic';

    my $cluster = 1;
    my %new_cluster_for;

    CLUSTER:
    for my $repr ( $self->all_cluster_names ) {

        my @members = map { $_->full_id } @{ $self->seq_ids_for($repr) };

        # start to fill in the hash if no members
        if ( scalar @members == 0 ) {
            $new_cluster_for{$cluster} = {
                representatives => [$repr   ],
                members         => [@members]
            };

            $cluster++;
            next CLUSTER;
        }

        # ... otherwise select a repr. seq. included in list
        else {
            # merge repr and members
            push @members, $repr;
            # and sort by sequence length
            my @sorted_ids = map { $_->full_id } sort_by { length($_->seq) }
                map { $self->seqs->get_seq_with_id($_) } @members;

            my @new_reprs
                =   intersect( @$list, @sorted_ids ) && $key eq 'classic'
                ? ( intersect( @$list, @sorted_ids ) )[0]   # @sorted_ids order
                :   intersect( @$list, @sorted_ids ) && $key eq 'all'
                ?   intersect( @$list, @sorted_ids )
                :                      $sorted_ids[0]
            ;

            my @new_members
                = $key eq 'classic' ? grep { $_ ne $new_reprs[0] } @sorted_ids
                : $key eq 'all'     ? array_minus(@sorted_ids, @new_reprs)
                : ()
            ;

            $new_cluster_for{$cluster} = {
                representatives => [@new_reprs  ],
                members         => [@new_members]
            };

            $cluster++;
            next CLUSTER;    # useless
        }
    }

    return \%new_cluster_for;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Drivers::CdHit - Bio::MUST driver for running the CD-HIT program

=head1 VERSION

version 0.252830

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Amandine BERTRAND Valerian LUPO

=over 4

=item *

Amandine BERTRAND <amandine.bertrand@doct.uliege.be>

=item *

Valerian LUPO <valerian.lupo@uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
