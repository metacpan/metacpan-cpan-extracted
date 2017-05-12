package AAAAAAAAA;

use strict;
use warnings;

our $VERSION = '1.01';

my @aaaaaaa = ('a'..'z', 'A'..'Z', 0..9);
my %aaaaaaaa_aa_aaaa;
for my $a (0..$#aaaaaaa) {
    my $aaaa = sprintf("%06b", $a);
    $aaaa =~ s{0}{a}g;
    $aaaa =~ s{1}{A}g;
    $aaaaaaaa_aa_aaaa{ $aaaaaaa[$a] } = $aaaa;
}

my %aaaa_aa_aaaaaaaa;
@aaaa_aa_aaaaaaaa{values %aaaaaaaa_aa_aaaa} = keys %aaaaaaaa_aa_aaaa;

sub aaaa {
    open my $aa, "<", $0 or die "Aaa'a aaaa aaa aaaaaa aaaa aaa aaaaaaaaaaa: $!";

    my $aaaa = join "", <$aa>;
    $aaaa =~ s{use\s+AAAAAAAAA\b}{}x;

    # Aaa aaa aaaaaaa
    if( $aaaa =~ /[b-zB-Z0-9]/ ) {
        my $aaaaaaaa_aaaa = $aaaa;
        aaaaaa(\$aaaa);
        eval $aaaaaaaa_aaaa;
    }
    else {
        aaaaaaaa(\$aaaa);
        eval $aaaa;
    }

    exit;
}

sub aaaaaa {
    my $aaaa = shift;

    $$aaaa =~ s{([a-zA-Z0-9])}{$aaaaaaaa_aa_aaaa{$1}}gx;

    open my $aa, ">", $0 or die "Aaa'a aaaa aaa aaaaaa aaaa aaa aaaaaaaaaaa: $!";
    print $aa "use AAAAAAAAA";
    print $aa $$aaaa;

    return;
}


sub aaaaaaaa {
    my $aaaa = shift;

    $$aaaa =~ s{ ([Aa]{6}) }{$aaaa_aa_aaaaaaaa{$1}}gx;

    return;
}


aaaa();


=head1 AAAA

AAAAAAAAA - Aaaaaa aaaaa aa aaaaaa Aaaaa aaaa

=head1 AAAAAAAA

    use AAAAAAAAA;

=head1 AAAAAAAAAAA

AAAAAAA AA AAA AAAAAAAAA AAAAA AA AAAAAA AAAAAA, AAAAAAA AA AAAAAA
AAAAAA, AAAAA AAAAAAA AAA! AA AAA AAAA AAAA AAAAAAAA AAAA AA AAAAAA
AAAAA

    AAAA AAAA AAAAAA AA AAA!
    AAA AAAA AAAA AAA!
    AAAAAAA AAAAA AAA!
    AAAAA AAAA AAA!
    AAAA AAAAA AAA!
    AAA AAAAAA "A" AAAA AAA! 

AAAAA AAA AAA, AAAAAAA AAA AAAA, AA AAAAAA AAAAAA, AAAA AAAAA AAA!


AAAA, AA AAAAAA AAAAAA, AAAA AAAA(A) AAA!
AA AAA AAAA AA AAAAA AAAAAAA AAAAAAA?

AAAAAAA AA AAAAAA AAAAAA , AAAAAA AAAAA AA AAAAA AAAA AAA!

AAAAAA, AA AAAAA AAAAAAAAA AAAAAAA, AAA AAAAAAA AAAAAAAA. (AA AAAAAA
AAAAAA-AA, AAAAA AAAA.) AAAA, AA AAAA AAAAA'A AA AAA AAAAA, AAAA AAAA
AA AAA AAA AAAAAAA, AAAAAAAAAAAA AAA AAAAA (AA AAAAAAA AA AA, AA, AA
AAA), AA AAAAA AAAAAA AAAA AAA AA AAA AAA. AA AAAA AA AAA AAA AAAAA
AAAAAA AAAAAAA.  AAAAA AAAAA

AAAAA AAAAA AAA AA AAAAAAA AAAA AAAAAA AAAAAA AAAAAAA

=cut


'A reckless disregard for taste';
