package Bio::FastParsers::Hmmer::Standard::Domain;
# ABSTRACT: Internal class for standard HMMER parser
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::FastParsers::Hmmer::Standard::Domain::VERSION = '0.221230';
use Moose;
use namespace::autoclean;

use List::AllUtils qw(mesh);


# public attributes

has $_ => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
) for qw(seq scoreseq profile probabilities);

with 'Bio::FastParsers::Roles::Domainable';

around BUILDARGS => sub {
    my ($orig, $class, $inargs) = @_;

    my @raw = @{ $inargs->{raw} };
    my $summary = $inargs->{summary};

    my %outargs;

    # parse header
    my @header_vals = $raw[0] =~ m/([\d\.]+)/xmsg;
    $outargs{'rank'}      = $header_vals[0];
    $outargs{'dom_score'} = $header_vals[1];
    $outargs{'c_evalue'}
        = @header_vals == 3 ? $header_vals[2] : join 'e-', @header_vals[2,3]
    ;

    # coerce numeric fields to numbers
    %outargs = map { $_ => 0 + $outargs{$_} } keys %outargs;

    # parse domain alignment

    # Alignment is made of 4 lines: best match to profile, scoring
    # correspondance, sequence alignment and posterior predictive. Each line
    # is shifted to the right by the same amount of characters, which is
    # different for each target. To get the size of the shift, I insert
    # special characters on the seqline and split on hit. Each part gives the
    # right length to extract correctly the information.

    my $profileline = $raw[1];
    my $scoreline = $raw[2];
    my $probline = $raw[4];
    ( my $seqline = $raw[3] )
        =~ s{(^\s+.*\s+\d+\s+)(\S+)\s\d+\s*$}{$1\|\|\|$2}xms;
    chomp $seqline;
    my ($skip, $tmpseq) = split /\|{3}/xms, $seqline;
    my $scoreseq = substr $scoreline, length $skip, length $tmpseq;
    my $profileseq = substr $profileline, length $skip, length $tmpseq;
    my $probabilities = substr $probline, length $skip, length $tmpseq;
    $outargs{'seq'} = $tmpseq;
    $outargs{'scoreseq'} = $scoreseq;
    $outargs{'profile'} = $profileseq;
    $outargs{'probabilities'} = $probabilities;

    # attributes from summary domtbl
    my @summary_attrs = qw(
        dom_bias i_evalue
        hmm_from hmm_to
        ali_from ali_to
        env_from env_to
        acc
    );
    my @summary_slots = qw(4 6 7 8 10 11 13 14 16);

    # parse summary
    # and coerce numeric fields to numbers
    my @fields = split /\s+/xms, $summary;
    my @summary_vals = map { 0 + $fields[$_] } @summary_slots;
    my %summary_hash = mesh @summary_attrs, @summary_vals;

    # return expected constructor hash
    return $class->$orig( %outargs, %summary_hash );
};

# TODO: check if this could not be avoided
#       as this looks like code duplication with Bio::MUST::Core
#       This one too ?

sub get_degap_scoreseq {
    my $self   = shift;
    my $tmpseq = $self->seq;
    my $score  = $self->scoreseq;

    # Need brackets or else pos == 1
    while ( (my $pos = index($tmpseq, '-') ) != -1 ) {
        substr $tmpseq, $pos, 1, q{};
        substr $score,  $pos, 1, q{};
    }

    return $score;
}


# aliases

sub expect {
    return shift->c_evalue;
}

sub score {
    return shift->dom_score;
}

sub num {
    return shift->number;
}

sub idx {
    return shift->number-1;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::FastParsers::Hmmer::Standard::Domain - Internal class for standard HMMER parser

=head1 VERSION

version 0.221230

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

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
