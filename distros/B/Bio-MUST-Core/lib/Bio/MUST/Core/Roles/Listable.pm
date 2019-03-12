package Bio::MUST::Core::Roles::Listable;
# ABSTRACT: Listable Moose role for objects with implied id lists
$Bio::MUST::Core::Roles::Listable::VERSION = '0.190690';
use Moose::Role;

use autodie;
use feature qw(say);

use Carp;
use Const::Fast;
use Date::Format;
use List::AllUtils;
use POSIX qw(ceil floor);

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:seqids);

requires 'all_seq_ids';


# IdList factory methods


# alias for std_list emphasizing its use as a lookup
sub new_lookup {
    return shift->_list_from_seq_ids(0);
}


sub std_list {
    return shift->_list_from_seq_ids(0);
}


sub alphabetical_list {
    return shift->_list_from_seq_ids(1);
}

sub _list_from_seq_ids {
    my $self = shift;
    my $sort = shift;

    my @ids = map { $_->full_id } $self->all_seq_ids;
    @ids = sort @ids if $sort;          # optionally sort list
    return Bio::MUST::Core::IdList->new( ids => \@ids );
}

around qw(complete_seq_list len_mapper) => sub {
    my $method = shift;
    my $self   = shift;

    # ensure that seqs are available (e.g., the object is an Ali)
    unless ( $self->can('all_seqs') ) {
        carp 'Warning: cannot proceed without seqs; returning undef!';
        return;
    }

    return $self->$method(@_);
};


sub complete_seq_list {
    my $self    = shift;
    my $min_res = shift;

    # get (non-missing char) lengths of all seqs and record max_len
    my @lengths = map { $_->nomiss_seq_len } $self->all_seqs;
    my $max_len = List::AllUtils::max @lengths;

    # convert fractional min_res to conservative integer (if needed)
    $min_res = ceil($min_res * $max_len)
        if 0 < $min_res && $min_res < 1;

    # filter out seqs with less than min_res non-missing chars
    my @ids = map { $_->full_id } $self->all_seq_ids;
    my @indices = grep { $lengths[$_] >= $min_res } 0..$#ids;

    return Bio::MUST::Core::IdList->new( ids => [ @ids[@indices] ] );
}


# IdMapper factory methods


sub std_mapper {
    my $self   = shift;
    my $prefix = shift // 'seq';

    my @seq_ids = $self->all_seq_ids;
    return Bio::MUST::Core::IdMapper->new(
        long_ids => [ map { $_->full_id  }    @seq_ids ],   #   list context
        abbr_ids => [ map { $prefix . $_ } 1..@seq_ids ],   # scalar context
    );
}


sub acc_mapper {
    my $self   = shift;
    my $prefix = shift // q{};

    # Note: this mapper could fail with non-GenBank Seqs
    my @seq_ids = $self->all_seq_ids;
    return Bio::MUST::Core::IdMapper->new(
        long_ids => [ map {           $_->full_id   } @seq_ids ],
        abbr_ids => [ map { $prefix . $_->accession } @seq_ids ],
    );
}


sub len_mapper {
    my $self = shift;

    my @seq_ids = $self->all_seq_ids;
    my @lengths = map { $_->nomiss_seq_len } $self->all_seqs;
    return Bio::MUST::Core::IdMapper->new(
        long_ids => [ map { $_->full_id . '@' . shift @lengths } @seq_ids ],
        abbr_ids => [ map { $_->full_id                        } @seq_ids ],
    );
}


sub regex_mapper {
    my $self   = shift;
    my $prefix = shift // q{};
    my $regex  = shift // $DEF_ID;

    my @long_ids = map { $_->full_id } $self->all_seq_ids;

    # extract unique id component and substitute forbidden chars
    # Note: this implementation was definitely too smart...
    # my @abbr_ids = map { $prefix . $_                 }
    #                map { $_ =~ s{$NOID_CHARS}{_}g; $_ }
    #                map { $_ =~ $regex; $1             } @long_ids;

    my @abbr_ids;
    for my $long_id (@long_ids) {
        my ($id) = $long_id =~ $regex;      # capture original id
        $id =~ s{$NOID_CHARS}{_}xmsg;       # substitute forbidden chars
        push @abbr_ids, $prefix . $id;
    }

    return Bio::MUST::Core::IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids
    );
}


sub org_mapper_from_long_ids {
    my $self   = shift;
    my $mapper = shift;             # mapper long_org => abbr_org

    my @long_ids;
    my @abbr_ids;

    ID:
    for my $seq_id ( $self->all_seq_ids ) {
        next ID if $seq_id->is_foreign;

        push @long_ids, $seq_id->full_id;
        push @abbr_ids, $mapper->abbr_id_for( $seq_id->full_org )
                . '|' . $seq_id->accession;
    }

    return Bio::MUST::Core::IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids
    );
}


sub org_mapper_from_abbr_ids {
    my $self   = shift;
    my $mapper = shift;             # mapper long_org => abbr_org

    my @long_ids;
    my @abbr_ids;

    ID:
    for my $seq_id ( $self->all_seq_ids ) {
        my $abbr_id = $seq_id->full_id;
        my ($abbr_org, $accession) = split /\|/xms, $abbr_id, 2;
        next ID unless $abbr_org;

        push @long_ids, $mapper->long_id_for($abbr_org) . '@' . $accession;
        push @abbr_ids, $abbr_id;
    }

    return Bio::MUST::Core::IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids
    );
}


const my $NBS_ID_LEN => 79;

sub store_nbs {
    my $self    = shift;
    my $outfile = shift;

    # #Sequences extracted from c111_78.ali of the 5 May 2009 at 11 hours 40
    # #File c111_78.nbs created on Tuesday 5 May 2009 at 11 hours 40
    # #184 positions remain on the 184 aligned positions
    # #life.col,life.nom
    # #Here is the list of the 78 species used:
    # Aciduliprofundum_boonei_T469___________________________________________________  Aeropyrum_pernix_K1____________________________________________________________
    # Archaeoglobus_fulgidus_DSM_4304________________________________________________  Archaeoglobus_profundus_Av18__DSM_5631_________________________________________
    # ...

    my @ids = $self->all_seq_ids;

    open my $out, '>', $outfile;

    # print minimum header
    print {$out} "#File $outfile created on " . ctime(time);
    say   {$out} '#Here is the list of the ' . scalar @ids . ' species used:';

    # print padded ids on two columns
    for my $i (0..$#ids) {
        my $id = $ids[$i]->foreign_id;
        my $pad_id = $id . '_' x ($NBS_ID_LEN - length $id);
        my $term = $i % 2 ? "\n" : q{  };
        print {$out} $pad_id . $term;
    }
    say {$out} q{};

    return;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Roles::Listable - Listable Moose role for objects with implied id lists

=head1 VERSION

version 0.190690

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 new_lookup

=head2 std_list

=head2 alphabetical_list

=head2 complete_seq_list

=head2 std_mapper

=head2 acc_mapper

=head2 len_mapper

=head2 regex_mapper

=head2 org_mapper_from_long_ids

=head2 org_mapper_from_abbr_ids

=head2 store_nbs

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
