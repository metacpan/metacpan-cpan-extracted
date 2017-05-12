package Class::Indexed::Words;

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(%stopwords &get_words);

###########
# stopwords
our %stopwords;
@stopwords{(qw(a i at be to do or of is in not near no the that they the then these them who are there where can why))} = qw(a i at be to do or of in is not near no the that they the then these them who are there where can why);

sub get_words {
    my $text = shift;
    warn "get_swords : $text \n";
    my @words = split(/[^a-z0-9\xc0-\xff\+\_\-]+/, lc $text);
    warn "words : ", @words, "\n";
    @words = grep { s/[^a-z0-9\xc0-\xff\+\_\-]+//; $_ } grep { length > 1 } grep { /[a-z0-9]/ } @words;
    warn "words : ", @words, "\n";
    return @words;
}

