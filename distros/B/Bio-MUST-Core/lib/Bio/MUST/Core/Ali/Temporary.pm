package Bio::MUST::Core::Ali::Temporary;
# ABSTRACT: Thin wrapper for a temporary mapped Ali written on disk
$Bio::MUST::Core::Ali::Temporary::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::MUST::Core::Types;

# Note: tried to implement it as a subclass of Bio::MUST::Core::Ali but this
# led to issues: (1) coercions became a nightmare and (2) the temp_fasta was
# written as soon as the Ali was created and thus was empty

# TODO: allows to specify the directory for the temp file (File::Temp tmpdir)
# TODO: allows to specify a template for the temp file name?

# ATTRIBUTES


has 'seqs' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Ali',
    required => 1,
    coerce   => 1,
    handles  => [
        qw(count_comments all_comments get_comment
            guessing all_seq_ids has_uniq_ids is_protein is_aligned
            get_seq get_seq_with_id first_seq all_seqs filter_seqs count_seqs
            gapmiss_regex
        )
    ],      # comment-related methods needed by IdList
);


has 'args' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_args',
);


has 'file' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::File',
    init_arg => undef,
    coerce   => 1,
    writer   => '_set_file',
    handles  => {
        remove   => 'remove',
        filename => 'stringify',
    },
);


has 'mapper' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::IdMapper',
    init_arg => undef,
    writer   => '_set_mapper',
    handles  => [ qw(all_long_ids all_abbr_ids long_id_for abbr_id_for) ],
);

with 'Bio::MUST::Core::Roles::Aliable';

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_args {
    return { clean => 1, degap => 1 };
}

## use critic

sub BUILD {
    my $self = shift;

    # remove persistent key (if any) from args before temp_fasta call
    # TODO: work out whether this is really needed
    my %args = %{ $self->args };
    delete $args{persistent};

    # create temporary FASTA file and setup associated IdMapper
    my $ali = $self->seqs;
    my ($filename, $mapper) = $ali->temp_fasta( \%args );
    $self->_set_file($filename);
    $self->_set_mapper($mapper);

    return;
}

sub DEMOLISH {
    my $self = shift;

    $self->remove
        unless $self->args->{persistent};

    return;
}

# ACCESSORS


# MISC METHODS


sub type {
    my $self = shift;
    return $self->is_protein ? 'prot' : 'nucl';
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Ali::Temporary - Thin wrapper for a temporary mapped Ali written on disk

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use Modern::Perl '2011';
    # same as:
    # use strict;
    # use warnings;
    # use feature qw(say);

    use Bio::MUST::Core;
    use aliased 'Bio::MUST::Core::Ali::Temporary';

    # build Ali::Temporary object from existing ALI file
    my $temp_db = Temporary->new( seqs => 'database.ali' );

    # get properties
    my $db = $temp_db->filename;
    my $dbtype = $temp_db->type;

    # pass it to external program
    system("makeblastdb -in $db -dbtype $dbtype");

    # alternative constructor call
    # build Ali::Temporary object from existing Ali object
    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('queries.ali');
    my $temp_qu = Temporary->new( seqs => $ali );

    # pass it to external program
    use File::Temp;
    my $query = $temp_qu->filename;
    my $out = File::Temp->new( UNLINK => 0, SUFFIX => '.blastp' );
    system("blastp -query $query -db $db -out $out");
    say "report: $out";

    # later... when parsing the BLAST report
    # let's say $id is a BLAST hit in database.ali
    my $id = 'seq2';
    my $long_id = $temp_db->long_id_for($id);
    say "hit id: $long_id";
    # ...

    # more alternative constructor calls
    # build Ali::Temporary object from list of Seq objects
    my @seqs = $ali->filter_seqs( sub { $_->seq_len >= 500 } );
    my $temp_ls = Temporary->new( seqs => \@seqs );

    # build Ali::Temporary object preserving gaps in Seq objects
    # (and persistent associated FASTA file)
    my $temp_gp = Temporary->new(
        seqs => \@seqs,
        args => { degap => 0, persistent => 1 }
    );
    my $filename = $temp_gp->filename;
    # later...
    unlink $filename;

=head1 DESCRIPTION

This module implements a class representing a temporary FASTA file where
sequence ids are automatically abbreviated (C<seq1>, C<seq2>...) for maximum
compatibility with external programs. To this end, it combines an internal
L<Bio::MUST::Core::Ali> object and a L<Bio::MUST::Core::IdMapper> object.

An C<Ali::Temporary> can be built from an existing ALI (or FASTA) file or
on-the-fly from a list (ArrayRef) of L<Bio::MUST::Core::Seq> objects (see the
SYNOPSIS for examples).

Its sequences can be aligned or not but by default sequences are degapped
before writing the associated temporary FASTA file. If gaps are to be
preserved, this behavior can be altered via the optional C<args> attribute.

=head1 ATTRIBUTES

=head2 seqs

L<Bio::MUST::Core::Ali> object (required)

This required attribute contains the L<Bio::MUST::Core::Seq> objects that are
written in the associated temporary FASTA file. It can be specified either as
a path to an ALI/FASTA file or as an C<Ali> object or as an ArrayRef of C<Seq>
objects (see the SYNOPSIS for examples).

For now, it provides the following methods: C<count_comments>,
C<all_comments>, C<get_comment>, C<guessing>, C<all_seq_ids>, C<has_uniq_ids>,
C<is_protein>, C<is_aligned>, C<get_seq>, C<get_seq_with_id>, C<first_seq>,
C<all_seqs>, C<filter_seqs> and C<count_seqs> (see L<Bio::MUST::Core::Ali>).

=head2 args

HashRef (optional)

When specified this optional attribute is passed to the C<temp_fasta> method
of the internal C<Ali> object. Its purpose is to allow the fine-tuning of the
format of the associated temporary FASTA file.

By default, its contents is C<<clean => 1>> and C<<degap => 1>>, so as to
generate a FASTA file of degapped sequences where ambiguous and missing states
are replaced by C<X>.

Additionally, if you want to keep your temporary files around for debugging
purposes, you can pass the option C<<persistent => 1>>. This will disable the
autoremoval of the file on object destruction.

=head2 file

L<Path::Class::File> object (auto)

This attribute is automatically initialized with the path of the associated
temporary FASTA file. Thus, it cannot be user-specified.

It provides the following methods: C<remove> and C<filename> (see below).

=head2 mapper

L<Bio::MUST::Core::IdMapper> object (auto)

This attribute is automatically initialized with the mapper associating the
long ids of the internal C<Ali> object to the abbreviated ids used in the
associated temporary FASTA file. Thus, it cannot be user-specified.

It provides the following methods: C<all_long_ids>, C<all_abbr_ids>,
C<long_id_for> and C<abbr_id_for> (see L<Bio::MUST::Core::IdMapper>).

=head1 ACCESSORS

=head2 filename

Returns the stringified filename of the associated temporary FASTA file.

This method does not accept any arguments.

=head2 type

Returns the type of the sequences in the internal C<Ali> object using BLAST
denomination (C<prot> or C<nucl>). See L<Bio::MUST::Core::Seq::is_protein> for
the exact test performed.

This method does not accept any arguments.

=head1 MISC METHODS

=head2 remove

Remove (unlink) the associated temporary FASTA file.

Since this method is in principle automatically invoked on object destruction,
users should not need it. Note that C<persistent> temporary files (see object
constructor) have to be removed manually, which requires to get and store
their C<filename> before object destruction.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
