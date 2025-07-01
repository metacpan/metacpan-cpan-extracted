package Bio::MUST::Core::IdMapper;
# ABSTRACT: Id mapper for translating sequence ids
$Bio::MUST::Core::IdMapper::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Carp;
use List::AllUtils qw(mesh uniq each_array);

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:files);
use aliased 'Bio::MUST::Core::SeqId';
with 'Bio::MUST::Core::Roles::Commentable';


# long_ids and abbr_ids public arrays
has $_ . '_ids' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::full_ids',
    default  => sub { [] },
    coerce   => 1,
    writer   => '_set_' . $_ . '_ids',
    handles  => {
        'count_' . $_ . '_ids' => 'count',
          'all_' . $_ . '_ids' => 'elements',
    },
) for qw(long abbr);


# _long_id_for and _abbr_id_for private hashes for faster mapping
has '_' . $_ . '_id_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_' . $_ . '_id_for',
    handles  => {
        $_ . '_id_for' => 'get',
    },
) for qw(long abbr);


# Note: mesh, uniq and co do not work with the 'elements' native trait,
# hence the option to coerce the public array refs in all the following subs

# Note: private hashes are not updated once (lazily) built

## no critic (ProhibitUnusedPrivateSubroutines)

# same note as in IdList.pm about SeqId objects

sub _build_long_id_for {
    my $self = shift;

    my @abbr_ids = map { $_->full_id } $self->all_abbr_seq_ids;
    my @long_ids = map { $_->full_id } $self->all_long_seq_ids;

    return { mesh @abbr_ids, @long_ids };
}

sub _build_abbr_id_for {
    my $self = shift;

    my @abbr_ids = map { $_->full_id } $self->all_abbr_seq_ids;
    my @long_ids = map { $_->full_id } $self->all_long_seq_ids;

    return { mesh @long_ids, @abbr_ids };
}

## use critic


sub BUILD {
    my $self = shift;

    # TODO: check that is has any effect at all!
    carp '[BMC] Warning: long and abbreviated id list sizes differ!'
        unless $self->count_long_ids == $self->count_abbr_ids;
    carp '[BMC] Warning: non unique long ids!'
        unless $self->count_long_ids == uniq @{ $self->long_ids };
    carp '[BMC] Warning: non unique abbreviated ids!'
        unless $self->count_abbr_ids == uniq @{ $self->abbr_ids };

    return;
}


# TODO: add an alias 'all_seq_ids' to one of the two following methods?


sub all_long_seq_ids {
    my $self = shift;
    return map { SeqId->new( full_id => $_ ) } $self->all_long_ids;
}



sub all_abbr_seq_ids {
    my $self = shift;
    return map { SeqId->new( full_id => $_ ) } $self->all_abbr_ids;
}


# I/O methods


sub load {
    my $class  = shift;
    my $infile = shift;
    my $args   = shift // {};           # HashRef (should not be empty...)

    # TODO: strip whitespace? also in ColorScheme? and IdList?
    my $sep = $args->{sep} // qr{\t}xms;

    open my $in, '<', $infile;

    my $mapper = $class->new();

    # Note: we now use temporary arrays because Moose coercions add a lot of
    # overhead if pushing directly (through delegation) on the attributes

    my @long_ids;
    my @abbr_ids;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $mapper->is_comment($line);

        # extract long and abbreviated ids
        my ($long_id, $abbr_id) = split $sep, $line;
        push @long_ids, $long_id;
        push @abbr_ids, $abbr_id;
    }

    $mapper->_set_long_ids( \@long_ids );
    $mapper->_set_abbr_ids( \@abbr_ids );

    return $mapper;
}



sub store {
    my $self    = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $sep    = $args->{sep}    // "\t";       # default to tab-separated
    my $header = $args->{header} // 1;          # default to MUST header

    open my $out, '>', $outfile;

    # note the use of a twin array iterator
    print {$out} $self->header if $header;
    my $ea = each_array @{ $self->long_ids }, @{ $self->abbr_ids };
    while (my ($long_id, $abbr_id) = $ea->() ) {
        say {$out} join $sep, $long_id, $abbr_id;
    }

    close $out;

    return;
}

# TODO: handle .nbs files from set_names_in_phylip_tree
# TODO: add a possible starting value of 1 for very old nbs files

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::IdMapper - Id mapper for translating sequence ids

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 all_long_seq_ids

=head2 all_abbr_seq_ids

=head2 load

=head2 store

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
