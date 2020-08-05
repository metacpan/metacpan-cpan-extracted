package Bio::MUST::Apps::Debrief42::TaxReport;
# ABSTRACT: Front-end class for tabular tax-report parser
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Apps::Debrief42::TaxReport::VERSION = '0.202160';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use List::AllUtils qw(mesh);

extends 'Bio::FastParsers::Base';

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use Bio::FastParsers::Constants qw(:files);
use aliased 'Bio::MUST::Apps::Debrief42::TaxReport::NewSeq';

use Smart::Comments;

# public attributes (inherited)


# private attributes

has '_line_iterator' => (
    traits   => ['Code'],
    is       => 'ro',
    isa      => 'CodeRef',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_line_iterator',
    handles  => {
        _next_line => 'execute',
    },
);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_line_iterator {
    my $self = shift;

    open my $fh, '<', $self->file;      # autodie
    return sub { <$fh> };               # return closure
}

## use critic



my @attrs = ( NewSeq->heads, 'outfile' );

sub next_seq {
    my $self = shift;

    LINE:
    while (my $line = $self->_next_line) {

        # skip header/comments and empty lines
        chomp $line;
        next LINE if $line =~ $COMMENT_LINE
                  || $line =~ $EMPTY_LINE;

        # process TaxReport line
        my $outfile = change_suffix( $self->filename, '.ali' );
        my @fields = ( split(/\t/xms, $line), $outfile );

        # Fields for tax-report file:
        #   0.  seq_id
        #   1.  contam_org
        #   2.  top_score
        #   3.  rel_n
        #   4.  mean_len
        #   5.  mean_ident
        #   6.  lca
        #   7.  lineage
        #   8.  acc
        #   9.  start
        #  10.  end
        #  11.  strand
        #  12.  seq
        #  13.  outfile

        # coerce numeric fields to numbers...
        @fields[2..5,9..11] = map { 0 + ($_ || 0) } @fields[2..5,9..11];

        # build NewSeq object
        my $new_seq = NewSeq->new( { mesh @attrs, @fields } );

        # return NewSeq object
        return $new_seq;
    }

    return;                         # no more line to read
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Apps::Debrief42::TaxReport - Front-end class for tabular tax-report parser

=head1 VERSION

version 0.202160

=head1 SYNOPSIS

    use aliased 'Bio::MUST::Apps::Debrief42::TaxReport';

    # open and parse FortyTwo tax-report in tabular format
    my $infile = 'test/uL4.tax-report';
    my $report = TaxReport->new( file => $infile );

    # loop through lines
    while (my $new_seq = $report->next_line) {
        my ($seq_id, $contam) = ($new_seq->hit_id, $new_seq->contam_org);
        # ...
    }

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to FortyTwo tax-report file in tabular format to be parsed

=head1 METHODS

=head2 next_seq

Shifts the first line of the report off and returns it, shortening the report
by 1 and moving everything down. If there are no more lines in the report,
returns C<undef>.

    # $report is a Bio::MUST::Apps::Debrief42::TaxReport
    while (my $new_seq = $report->next_seq) {
        # process $new_seq
        # ...
    }

This method does not accept any arguments.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Mick VAN VLIERBERGHE

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
