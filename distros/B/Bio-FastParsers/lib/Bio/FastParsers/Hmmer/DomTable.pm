package Bio::FastParsers::Hmmer::DomTable;
# ABSTRACT: Front-end class for tabular HMMER domain parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::DomTable::VERSION = '0.221230';
use Moose;
use namespace::autoclean;

use autodie;

use List::AllUtils qw(mesh);

extends 'Bio::FastParsers::Base';

use Bio::FastParsers::Constants qw(:files);
use aliased 'Bio::FastParsers::Hmmer::DomTable::Hit';


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

my @attrs = qw(
    target_name target_accession tlen
     query_name  query_accession qlen
    evalue score bias rank of
    c_evalue i_evalue dom_score dom_bias
    hmm_from hmm_to ali_from ali_to env_from env_to
    acc target_description
);      # DID try to use MOP to get Hit attrs but order was not preserved


sub next_hit {
    my $self = shift;

    LINE:
    while (my $line = $self->_next_line) {

        # skip header/comments and empty lines
        chomp $line;
        next LINE if $line =~ $COMMENT_LINE
                  || $line =~ $EMPTY_LINE;

        # process Hit line
        my @fields = split(/\s+/xms, $line, 23);

        # Fields
        #   0.  target name
        #   1.  target accession
        #   2.  tlen
        #   3.  query name
        #   4.  accession
        #   5.  qlen
        #   6.  E-value
        #   7.  score
        #   8.  bias
        #   9.  rank
        #  10.  of
        #  11.  c-Evalue
        #  12.  i-Evalue
        #  13.  dom_score
        #  14.  dom_bias
        #  15.  from (hmm coord)
        #  16.  to (hmm coord)
        #  17.  from (ali coord)
        #  18.  to (ali coord)
        #  19.  from (env coord)
        #  20.  to (env coord)
        #  21.  acc
        #  22.  description of target

        # coerce numeric fields to numbers
        @fields[5..21] = map { 0 + $_ } @fields[5..21];

        # set missing field values to undef
        @fields[1,4,22] = map { $_ eq '-' ? undef : $_ } @fields[1,4,22];

        # return Hit object
        return Hit->new( { mesh @attrs, @fields } );
    }

    return;                         # no more line to read
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer::DomTable - Front-end class for tabular HMMER domain parser

=head1 VERSION

version 0.221230

=head1 SYNOPSIS

    use aliased 'Bio::FastParsers::Hmmer::DomTable';

    # open and parse HMMER domain report in tabular format
    my $infile = 'test/hmmer.domtblout';
    my $report = DomTable->new( file => $infile );

    # loop through hits
    while (my $hit = $hit->next_hit) {
        my ($target_name, $evalue) = ($hit->target_name, $hit->evalue);
        # ...
    }

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to HMMER domain report file in tabular format (--domtblout) to be parsed

=head1 METHODS

=head2 next_hit

Shifts the first Hit of the report off and returns it, shortening the report
by 1 and moving everything down. If there are no more Hits in the report,
returns C<undef>.

    # $report is a Bio::FastParsers::Hmmer::Table
    while (my $hit = $report->next_hit) {
        # process $hit
        # ...
    }

This method does not accept any arguments.

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
