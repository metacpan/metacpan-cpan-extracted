package Bio::FastParsers::Hmmer::Table;
# ABSTRACT: front-end class for tabular HMMER parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::Table::VERSION = '0.173510';
use Moose;
use namespace::autoclean;

use autodie;

use List::AllUtils qw(mesh);

extends 'Bio::FastParsers::Base';

use Bio::FastParsers::Constants qw(:files);
use aliased 'Bio::FastParsers::Hmmer::Table::Hit';


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
    target_name target_accession
     query_name  query_accession
             evalue          score          bias
    best_dom_evalue best_dom_score best_dom_bias
    exp reg clu ov env dom rep inc
    target_description
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
        my @fields = split(/\s+/xms, $line, 19);

        # Fields
        #   0.  target name
        #   1.  accession
        #   2.  query name
        #   3.  accession
        #   4.  E-value
        #   5.  score
        #   6.  bias
        #   7.  E-value
        #   8.  score
        #   9.  bias
        #  10.  exp
        #  11.  reg
        #  12.  clu
        #  13.  ov
        #  14.  env
        #  15.  dom
        #  16.  rep
        #  17.  inc
        #  18.  description of target

        # coerce numeric fields to numbers
        @fields[4..17] = map { 0 + $_ } @fields[4..17];

        # set missing field values to undef
        @fields[1,3,18] = map { $_ eq '-' ? undef : $_ } @fields[1,3,18];

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

Bio::FastParsers::Hmmer::Table - front-end class for tabular HMMER parser

=head1 VERSION

version 0.173510

=head1 SYNOPSIS

    use aliased 'Bio::FastParsers::Hmmer::Table';

    # open and parse HMMER report in tabular format
    my $infile = 'test/hmmer.tblout';
    my $report = Table->new( file => $infile );

    # loop through hits
    while (my $hit = $hit->next_hit) {
        my ($target_name, $evalue) = ($hit->target_name, $hit->evalue);
        # ...
    }

=head1 DESCRIPTION

    # TODO

=head1 ATTRIBUTES

=head2 file

Path to HMMER report file in tabular format (--tblout) to be parsed

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
