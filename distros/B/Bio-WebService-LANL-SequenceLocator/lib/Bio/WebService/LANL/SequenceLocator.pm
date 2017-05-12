use strictures 1;
use utf8;
use 5.018;

=head1 NAME

Bio::WebService::LANL::SequenceLocator - Locate sequences within HIV using LANL's web tool

=head1 SYNOPSIS

    use Bio::WebService::LANL::SequenceLocator;
    
    my $locator = Bio::WebService::LANL::SequenceLocator->new(
        agent_string => 'Your Organization - you@example.com',
    );
    my @sequences = $locator->find([
        "agcaatcagatggtcagccaaaattgccctatagtgcagaacatccaggggcaagtggtacatcaggccatatcacctagaactttaaatgca",
    ]);

See L</EXAMPLE RESULTS> below.

=head1 DESCRIPTION

This library provides simple programmatic access to
L<LANL's HIV sequence locator|http://www.hiv.lanl.gov/content/sequence/LOCATE/locate.html>
web tool and is also used to power
L<a simple, JSON-based web API|https://indra.mullins.microbiol.washington.edu/locate-sequence/>
for the same tool (via L<Bio::WebService::LANL::SequenceLocator::Server>).

Nearly all of the information output by LANL's sequence locator is parsed and
provided by this library, though the results do vary slightly depending on the
base type of the query sequence.  Multiple query sequences can be located at
the same time and results will be returned for all.

Results are extracted from both tab-delimited files provided by LANL as well as
the HTML itself.

=head1 EXAMPLE RESULTS

    # Using @sequences from the SYNOPSIS above
    use JSON;
    print encode_json(\@sequences);
    
    __END__
    [
       {
          "query" : "sequence_1",
          "query_sequence" : "AGCAATCAGATGGTCAGCCAAAATTGCCCTATAGTGCAGAACATCCAGGGGCAAGTGGTACATCAGGCCATATCACCTAGAACTTTAAATGCA",
          "base_type" : "nucleotide",
          "reverse_complement" : "0",
          "alignment" : "\n Query AGCAATCAGA TGGTCAGCCA AAATTGCCCT ATAGTGCAGA ACATCCAGGG  50\n       ::::::::    ::::::::: ::::: :::: :::::::::: :::::::::: \n  HXB2 AGCAATCA-- -GGTCAGCCA AAATTACCCT ATAGTGCAGA ACATCCAGGG  1208\n\n Query GCAAGTGGTA CATCAGGCCA TATCACCTAG AACTTTAAAT GCA  93\n       :::: ::::: :::::::::: :::::::::: :::::::::: ::: \n  HXB2 GCAAATGGTA CATCAGGCCA TATCACCTAG AACTTTAAAT GCA  1251\n\n  ",
          "hxb2_sequence" : "AGCAATCA---GGTCAGCCAAAATTACCCTATAGTGCAGAACATCCAGGGGCAAATGGTACATCAGGCCATATCACCTAGAACTTTAAATGCA",
          "similarity_to_hxb2" : "94.6",
          "start" : "373",
          "end" : "462",
          "genome_start" : "1162",
          "genome_end" : "1251",
          "polyprotein" : "Gag",
          "region_names" : [
             "Gag",
             "p17",
             "p24"
          ],
          "regions" : [
             {
                "cds" : "Gag",
                "aa_from_protein_start" : [ "125", "154" ],
                "na_from_cds_start" : [ "373", "462" ],
                "na_from_hxb2_start" : [ "1162", "1251" ],
                "na_from_query_start" : [ "1", "93" ],
                "protein_translation" : "SNQMVSQNCPIVQNIQGQVVHQAISPRTLNA"
             },
             {
                "cds" : "p17",
                "aa_from_protein_start" : [ "125", "132" ],
                "na_from_cds_start" : [ "373", "396" ],
                "na_from_hxb2_start" : [ "1162", "1185" ],
                "na_from_query_start" : [ "1", "27" ],
                "protein_translation" : "SNQMVSQNC"
             },
             {
                "cds" : "p24",
                "aa_from_protein_start" : [ "1", "22" ],
                "na_from_cds_start" : [ "1", "66" ],
                "na_from_hxb2_start" : [ "1186", "1251" ],
                "na_from_query_start" : [ "28", "93" ],
                "protein_translation" : "PIVQNIQGQVVHQAISPRTLNA"
             }
          ]
       }
    ]

=cut

package Bio::WebService::LANL::SequenceLocator;

use Moo;
use Data::Dumper;
use HTML::LinkExtor;
use HTML::TableExtract;
use HTML::TokeParser;
use HTTP::Request::Common;
use List::AllUtils qw< pairwise part min max >;

our $VERSION = 20170324;

=head1 METHODS

=head2 new

Returns a new instance of this class.  An optional parameter C<agent_string>
should be provided to identify yourself to LANL out of politeness.  See the
L</SYNOPSIS> for an example.

=cut

has agent_string => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { '' },
);

has agent => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        require LWP::UserAgent;
        my $self  = shift;
        my $agent = LWP::UserAgent->new(
            agent => join(" ", __PACKAGE__ . "/$VERSION", $self->agent_string),
        );
        $agent->env_proxy;
        return $agent;
    },
);

has lanl_base => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { 'https://www.hiv.lanl.gov' },
);

has lanl_endpoint => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { shift->lanl_base . '/cgi-bin/LOCATE/locate.cgi' },
);

has _bogus_slug => (
    is      => 'ro',
    default => sub { 'BOGUS_SEQ_SO_TABULAR_FILES_ARE_LINKED_IN_OUTPUT' },
);

sub _request {
    my $self = shift;
    my $req  = shift;
    my $response = $self->agent->request($req);

    if (not $response->is_success) {
        warn sprintf "Request failed: %s %s -> %s\n",
            $req->method, $req->uri, $response->status_line;
        return;
    }

    return $response->decoded_content;
}

=head2 find

Takes an array ref of sequence strings.  Sequences may be in amino acids or
nucleotides and mixed freely.  Sequences should not be in FASTA format.

If sequence bases are not clearly nucleotides or clearly amino acids, LANL
seems to default to nucleotides.  This can be an issue for some sequences since
the full alphabet for nucleotides overlaps with the alphabet for amino acids.
To overcome this problem, you may specify C<< base => 'nucleotide' >>
or C<< base => 'amino acid' >> after the array ref of sequences.  This forces
every sequence to be interpreted as nucleotides or amino acids, so you cannot
mix base types in your sequences if you use this option.  C<n>, C<nuc>, and
C<nucleotides> are accepted aliases for C<nucleotide>.  C<a>, C<aa>, C<amino>,
and C<amino acids> are accepted aliases for C<amino acid>.

Returns a list of hashrefs when called in list context, otherwise returns an
arrayref of hashrefs.

See L</EXAMPLE RESULTS> for the structure of the data returned.

=cut

sub find {
    my ($self, $sequences, %args) = @_;

    my $content = $self->submit_sequences($sequences, %args)
        or return;

    return $self->parse_html($content);
}

sub submit_sequences {
    my ($self, $sequences, %args) = @_;

    if (defined $args{base}) {
        my $base = lc $args{base};
        if ($base =~ /^n(uc(leotides?)?)?$/i) {
            $args{base} = 1;
        } elsif ($base =~ /^(a(mino( acids?)?)?|aa)$/i) {
            $args{base} = 0;
        } else {
            warn "Unknown base type <$args{base}>, ignoring";
            delete $args{base};
        }
    }

    # Submit multiple sequences at once using FASTA
    my $fasta = join "\n", map {
        ("> sequence_$_", $sequences->[$_ - 1])
    } 1 .. @$sequences;

    # LANL only presents the parseable table.txt we want if there's more
    # than a single sequence.  We always add it so we can reliably skip it.
    $fasta .= "\n> " . $self->_bogus_slug . "\n";

    return $self->_request(
        POST $self->lanl_endpoint,
        Content_Type => 'form-data',
        Content      => [
            organism            => 'HIV',
            DoReverseComplement => 0,
            seq_input           => $fasta,
            (defined $args{base}
                ? ( base => $args{base} )
                : ()),
        ],
    );
}

sub parse_html {
    my ($self, $content) = @_;

    # Fetch and parse the two tables provided as links which removes the need
    # to parse all of the HTML.
    my @results = $self->parse_tsv($content);

    # Now parse the table data from the HTML
    my @tables = $self->parse_tables($content);

    # Extract the alignments, parsing the HTML a third time!
    my @alignments = $self->parse_alignments($content);

    unless (@results and @tables and @alignments) {
        warn "Didn't find all three of TSV, tables, and alignments!\n";
        warn "TSV:             ", scalar @results, "\n";
        warn "HTML tables:     ", scalar @tables, "\n";
        warn "HTML alignments: ", scalar @alignments, "\n";
        warn "Content:\n$content\n", "=" x 80, "\n";
        return;
    }

    unless (@results == @tables and @results == @alignments) {
        warn "Tab-delimited results count doesn't match parsed HTML result count.  Bug!\n";
        warn "TSV:             ", scalar @results, "\n";
        warn "HTML tables:     ", scalar @tables, "\n";
        warn "HTML alignments: ", scalar @alignments, "\n";
        warn "Content:\n$content\n", "=" x 80, "\n";
        return;
    }

    @results = pairwise {
        my $new = {
            %$a,
            base_type       => $b->{base_type},
            regions         => $b->{rows},
            region_names    => [ map { $_->{cds} } @{$b->{rows}} ],
        };
        delete $new->{$_} for qw(protein protein_start protein_end);
        $new;
    } @results, @tables;

    @results = pairwise { +{ %$b, %$a } } @results, @alignments;

    # Fill in genome start/end for amino acid sequences
    for my $r (@results) {
        next unless $r->{base_type} eq 'amino acid';

        if ($r->{genome_start} or $r->{genome_end}) {
            warn "Amino acid sequence with genome start/end already?!",
                 " query <$r->{query_sequence}>";
            next;
        }

        $r->{genome_start} = min map { $_->{na_from_hxb2_start}[0] } @{$r->{regions}};
        $r->{genome_end}   = max map { $_->{na_from_hxb2_start}[1] } @{$r->{regions}};
    }

    return wantarray ? @results : \@results;
}

sub parse_tsv {
    my ($self, $content) = @_;
    my @results;
    my %urls;

    my $extract = HTML::LinkExtor->new(
        sub {
            my ($tag, %attr) = @_;
            return unless $tag eq 'a' and $attr{href};
            return unless $attr{href} =~ m{/(table|simple_results)\.txt$};
            $urls{$1} = $attr{href};
        },
        $self->lanl_base,
    );
    $extract->parse($content);

    for my $table_name (qw(table simple_results)) {
        next unless $urls{$table_name};
        my $table = $self->_request(GET $urls{$table_name})
            or next;

        my (@these_results, %seen);
        my @lines  = split "\n", $table;
        my @fields = map {
            s/^SeqName$/query/;         # standard key
            s/(?<=[a-z])(?=[A-Z])/_/g;  # undo CamelCase
            s/ +/_/g;                   # no spaces
            y/A-Z/a-z/;                 # normalize to lowercase
            # Account for the same field twice in the same data table
            if ($seen{$_}++) {
                $_ = /^(start|end)$/
                    ? "protein_$_"
                    : join "_", $_, $seen{$_};
            }
            $_;
        } split "\t", shift @lines;

        for (@lines) {
            my @values = split "\t";
            my %data;
            @data{@fields} = @values;

            next if $data{query} eq $self->_bogus_slug;

            $data{query_sequence} =~ s/\s+//g
                if $data{query_sequence};
            push @these_results, \%data;
        }

        # Merge with existing results, if any
        @results = @results
                 ? pairwise { +{ %$a, %$b } } @results, @these_results
                 : @these_results;
    }

    return @results;
}

sub parse_tables {
    my ($self, $content) = @_;
    my @tables;

    my %columns_for = (
        'amino acid'    => [
            "CDS"                                               => "cds",
            "AA position relative to protein start in HXB2"     => "aa_from_protein_start",
            "AA position relative to query sequence start"      => "aa_from_query_start",
            "AA position relative to polyprotein start in HXB2" => "aa_from_polyprotein_start",
            "NA position relative to CDS start in HXB2"         => "aa_from_cds_start",
            "NA position relative to HXB2 genome start"         => "na_from_hxb2_start",
        ],
        'nucleotide'    => [
            "CDS"                                                   => "cds",
            "Nucleotide position relative to CDS start in HXB2"     => "na_from_cds_start",
            "Nucleotide position relative to query sequence start"  => "na_from_query_start",
            "Nucleotide position relative to HXB2 genome start"     => "na_from_hxb2_start",
            "Amino Acid position relative to protein start in HXB2" => "aa_from_protein_start",
        ],
    );

    for my $base_type (sort keys %columns_for) {
        my ($their_cols, $our_cols) = part {
            state $i = 0;
            $i++ % 2
        } @{ $columns_for{$base_type} };

        my $extract = HTML::TableExtract->new( headers => $their_cols );
        $extract->parse($content);

        # Examine all matching tables
        for my $table ($extract->tables) {
            my %table = (
                coords      => [$table->coords],
                base_type   => $base_type,
                columns     => $our_cols,
                rows        => [],
            );
            for my $row ($table->rows) {
                @$row = map { defined $_ ? s/^\s+|\s*$//gr : $_ } @$row;

                # An empty row with only a sequence string in the first column.
                if (    $row->[0]
                    and $row->[0] =~ /^[A-Za-z]+$/
                    and not grep { defined and length } @$row[1 .. scalar @$row - 1])
                {
                    $table{rows}->[-1]{protein_translation} = $row->[0];
                    next;
                }

                # Not all rows are data, some are informational sentences.
                next if grep { not defined } @$row;

                my %row;
                @row{@$our_cols} =
                    map { ($_ and $_ eq "NA")       ? undef     : $_ }
                    map { ($_ and /(\d+) → (\d+)/)  ? [$1, $2]  : $_ }
                        @$row;

                push @{$table{rows}}, \%row;
            }
            push @tables, \%table
                if @{$table{rows}};
        }
    }

    # Sort by depth, then within each depth by count
    @tables = sort {
        $a->{coords}[0] <=> $b->{coords}[0]
     or $a->{coords}[1] <=> $b->{coords}[1]
    } @tables;

    if (@tables > 1) {
        unless (    $tables[-1]->{rows}[0]{na_from_query_start} eq "1 →"
                and $tables[-1]->{rows}[0]{protein_translation} eq "X") {
            warn "Last table appears to be real!?  It should be the bogus table of the bogus sequence.";
            warn "Table is ", Dumper($tables[-1]), "\n";
            return;
        } else {
            pop @tables;
        }
    }

    return @tables;
}

sub parse_alignments {
    my ($self, $content) = @_;
    my @alignments;

    my $doc = HTML::TokeParser->new(
        \$content,
        unbroken_text => 1,
    );

    my $expect_alignment = 0;

    while (my $tag = $doc->get_tag("b", "pre")) {
        my $name = lc $tag->[0];
        my $text = $doc->get_text;
        next unless defined $text;

        # <pre>s are preceeded by a bold header, which we use as an indicator
        if ($name eq 'b') {
            $expect_alignment = $text =~ /Alignment\s+of\s+the\s+query\s+sequence\s+to\s+HXB2/i;
        } elsif ($name eq 'pre') {
            if ($text =~ /^\s*Query\b/m and $text =~ /^\s*HXB2\b/m) {
                push @alignments, $text;
                warn "Not expecting alignment, but found one‽"
                    unless $expect_alignment;
            }
            elsif ($text =~ /^\s+$/ and $expect_alignment) {
                push @alignments, undef;    # We appear to have found an unaligned sequence.
            }
            $expect_alignment = 0;
        }
    }

    if (defined $alignments[-1]) {
        warn "Last alignment is non-null!  It should be the empty alignment of the bogus sequence.";
        warn "Alignment is <$alignments[-1]>\n";
        return;
    } else {
        pop @alignments;
    }

    my @results;
    for (@alignments) {
        my @hxb2;
        if (defined) {
            push @hxb2, $1 =~ s/\s+//gr
                while /^\s*HXB2\b\s+(.+?)(?:\s+\d+|\s*)$/gm;
        }
        push @results, {
            alignment       => $_,
            hxb2_sequence   => @hxb2 ? join("", @hxb2) : undef,
        };
    }

    return @results;
}

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

=head1 COPYRIGHT

Copyright 2014 by the Mullins Lab, Department of Microbiology, University of
Washington.

=head1 LICENSE

Licensed under the same terms as Perl 5 itself.

=cut

42;
