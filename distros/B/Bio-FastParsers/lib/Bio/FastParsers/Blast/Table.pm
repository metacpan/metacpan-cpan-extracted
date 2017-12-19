package Bio::FastParsers::Blast::Table;
# ABSTRACT: front-end class for tabular BLAST parser
$Bio::FastParsers::Blast::Table::VERSION = '0.173510';
use Moose;
use namespace::autoclean;

use autodie;

use List::AllUtils qw(mesh);

extends 'Bio::FastParsers::Base';

use Bio::FastParsers::Constants qw(:files);
use aliased 'Bio::FastParsers::Blast::Table::Hsp';

# TODO: recreate Table classes and internal classes through Templating
# TODO: check API consistency with Hmmer::Table and DomTable through synonyms
# TODO: document Hsp/Hit methods

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

has '_last_' . $_ => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => q{},
    writer   => '_set_last_' . $_,
) for qw(query hit);


## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_line_iterator {
    my $self = shift;

    open my $fh, '<', $self->file;      # autodie
    return sub { <$fh> };               # return closure
}

## use critic

my @attrs = qw(
    query_id hit_id
    percent_identity hsp_length mismatches gaps
    query_from  query_to
      hit_from    hit_to
    evalue bit_score
    query_strand
      hit_strand
    query_start query_end
      hit_start   hit_end
);      # DID try to use MOP to get HSP attrs but order was not preserved


sub next_hsp {
    my $self = shift;

    LINE:
    while (my $line = $self->_next_line) {

        # skip header/comments and empty lines
        chomp $line;
        next LINE if $line =~ $COMMENT_LINE
                  || $line =~ $EMPTY_LINE;

        # process HSP line
        my @fields = ( split(/\t/xms, $line), 1, 1 );

        # Fields for m8/m9 (now 6/7) format:
        #   0.  query id
        #   1.  subject id
        #   2.  % identity
        #   3.  alignment length
        #   4.  mismatches
        #   5.  gap opens
        #   6.  q. start  => query_from
        #   7.  q. end    => query_to
        #   8.  s. start  => hit_from
        #   9.  s. end    => hit_to
        #  10.  evalue
        #  11.  bit score
        # [12.] query_strand
        # [13.] hit_strand
        # [14.] query_start
        # [15.] query_end
        # [16.] hit_start
        # [17.] hit_end

        # coerce numeric fields to numbers...
        # ... and handle missing bitscores and evalues from USEARCH reports
        @fields[2..9]   = map {             0 + $_         } @fields[2..9];
        @fields[10..11] = map { $_ ne '*' ? 0 + $_ : undef } @fields[10..11];

        # add default strands and coordinates
        push @fields, @fields[6..9];

        # fix query strand and coordinates based on query orientation
        if ($fields[14] > $fields[15]) {
            @fields[14,15] = @fields[15,14];
            $fields[12] = -1;
        }

        # fix hit strand and coordinates based on hit orientation
        if ($fields[16] > $fields[17]) {
            @fields[16,17] = @fields[17,16];
            $fields[13] = -1;
        }

        # build HSP object
        my $hsp = Hsp->new( { mesh @attrs, @fields } );

        # update last query and last hit
        # Note: this allows mixing calls to next_hsp / next_hit / next_query
        $self->_set_last_query($hsp->query_id);
        $self->_set_last_hit(  $hsp->hit_id  );

        # return HSP object
        return $hsp;
    }

    return;                         # no more line to read
}



sub next_hit {
    my $self = shift;

    # start from wherever we were
    my $curr_query = $self->_last_query;
    my $curr_hit   = $self->_last_hit;

    # consume HSPs as long as no new hit (or query)
    while (my $hsp = $self->next_hsp) {
        return $hsp
            if $hsp->query_id ne $curr_query || $hsp->hit_id ne $curr_hit;
    }

    return;
}



sub next_query {
    my $self = shift;

    # start from wherever we were
    my $curr_query = $self->_last_query;

    # consume HSPs as long as no new query
    while (my $hsp = $self->next_hsp) {
        return $hsp
            if $hsp->query_id ne $curr_query;
    }

    return;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Blast::Table - front-end class for tabular BLAST parser

=head1 VERSION

version 0.173510

=head1 SYNOPSIS

    use aliased 'Bio::FastParsers::Blast::Table';

    # open and parse BLAST report in tabular format
    my $infile = 'test/blastp.m9';
    my $report = Table->new( file => $infile );

    # loop through hsps
    while (my $hsp = $hit->next_hsp) {
        my ($hit_id, $evalue) = ($hsp->hit_id, $hsp->evalue);
        # ...
    }

    # ...

    my $infile = 'test/multiquery-blastp.m9';
    my $report = Table->new( file => $infile );

    # loop through first hits for each query
    while (my $first_hit = $hit->next_query) {
        my ($hit_id, $evalue) = ($hsp->hit_id, $hsp->evalue);
        # ...
    }

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to BLAST report file in tabular format (m8/m9 or now 6/7) to be parsed

=head1 METHODS

=head2 next_hsp

Shifts the first HSP of the report off and returns it, shortening the report
by 1 and moving everything down. If there are no more HSPs in the report,
returns C<undef>.

    # $report is a Bio::FastParsers::Blast::Table
    while (my $hsp = $report->next_hsp) {
        # process $hsp
        # ...
    }

This method does not accept any arguments.

=head2 next_hit

Directly returns the first HSP of the next hit, skipping any remaining HSPs
for the current hit in the process. If there are no more hits in the report,
returns C<undef>. Useful for processing only the first HSP of each hit.

    # $report is a Bio::FastParsers::Blast::Table
    while (my $first_hsp = $report->next_hit) {
        # process $first_hsp
        # ...
    }

This method does not accept any arguments.

=head2 next_query

Directly returns the first HSP of the next query, skipping any remaining
HSPs for the current query in the process. If there are no more queries in
the report, returns C<undef>. Useful for processing only the first hit of
each query.

    # $report is a Bio::FastParsers::Blast::Table
    while (my $first_hit = $report->next_query) {
        # process $first_hit
        # ...
    }

This method does not accept any arguments.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
