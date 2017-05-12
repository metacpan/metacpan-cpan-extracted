package DNA;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

my $i = 0;
my @Acids = qw(A T C G);
my %Acids = map { $_ => $i++ } @Acids;
open HOST, "$0" or die "Genetic resequencing failed: $!";

my($code, $pod, $shebang) = ('', '', '');
my($inpod) = 0;
my $line;
while(defined($line = <HOST>)) {
    if( $. == 1 and $line =~ /^\#!/ ) {
        $shebang = $line;
    }
    elsif( $line =~ /^=cut/ ) {
        $inpod = 0;
    }
    elsif( $line =~ /^=\w+/ ) {
        $pod .= $line;
        $inpod = 1;
    }
    else {
        if( $inpod ) {
            $pod .= $line;
        } else {
            $code .= $line;
        }
    }
}

close HOST;

sub mutate {
    my $na = shift;
    $na = join '', map $Acids[rand @Acids], 1..4 unless int rand 1000;
    return $na;
}

sub ascii_to_na {
    my $ascii = ord shift;
    my $na = '';

    for (1..4) {
        $na .= $Acids[$ascii % 4];
        $ascii = $ascii >> 2;
    }

    $na = mutate($na);

    return $na;
}

sub na_to_ascii {
    my $na = mutate(shift);
    my $ascii = 0;
    for my $chr (0..3) {
        $ascii += $Acids{ substr($na, $chr, 1) } * (4 ** $chr);
    }

    return chr $ascii;
}

my $Acids = join '', @Acids;
$Acids = "[$Acids]";
sub devolve {
    my $code = shift;
    my $idx = 0;
    my $perl = '';
    while( $code =~ /($Acids{4})/g ) {
        my $segment = $idx++ % 96;
        next if $segment >= 16;
        $perl .= na_to_ascii($1);
    }

    return $perl;
}

sub evolutionary_junk {
    my $junk = join ' ', map { ascii_to_na(int rand 256) } 0..(75/5);
}

sub evolve {
    my $code = shift;
    my $idx = 0;
    my $chromosome = '';
    for my $idx (0..length($code) - 1) {
        my $chr = substr($code, $idx, 1);
        $chromosome .= ascii_to_na($chr). " ";
        unless( ($idx + 1) % (80 / 5) ) { 
            chop $chromosome;
            $chromosome .= "\n";
            for(1..5) {
                $chromosome .= evolutionary_junk()."\n";
            }
        }
    }
    
    open HOST, ">$0" or
      die "Cannot complete genetic encoding!  ".
          "Alert the Human Genome Project!\n";

    print HOST "$shebang\n" if length $shebang;
    print HOST "use DNA;\n\n";
    print HOST $chromosome, "\n\n";
    print HOST $pod;
    close HOST;
}

if( $code =~ s/^use DNA;\n\n(?=[ATCG]{4})//sm ) {
    $code =~ s/($Acids{4})/mutate($1)/ge;
    my $perl = devolve($code);
    evolve($perl);
    eval $perl;
}
elsif( $code =~ s/(use|require)\s+DNA\s*;\n//sm ) {
    evolve($code);
    eval $code;
}

exit;


=head1 NAME

DNA - Encodes your Perl program into an Nucleic Acid sequence

=head1 SYNOPSIS

use DNA;

CCAA CCAA AAGT CAGT TCCT CGCT ATGT AACA CACA TCTT GGCT TTGT AACA GTGT TCCT AGCT
CAGA TAGA ACGA TAGA TAGA CAGA TAGA CAGA CAGA CAGA TAGA CAGA CAGA CAGA TAGA ATGA
TAGA TAGA GTGA CAGA TAGA CTGA CAGA TAGA CAGA CAGA CAGA TAGA TTGA CAGA TAGA CTGA
TAGA CAGA CTGA TAGA TCGA CTGA ATGA TAGA TAGA TAGA CAGA TAGA ACGA TAGA ACGA TAGA
TAGA TAGA TAGA TAGA TAGA TAGA CTGA CAGA CAGA TTGA TAGA CAGA ATGA CAGA TAGA TAGA
GAGA TAGA GTGA CAGA CAGA GTGA TAGA TAGA TTGA TAGA CAGA TAGA CAGA TCGA TTGA CAGA
AGCT AACA TACT AGCT AGCT AACA TTGT GAGT TTCT AACA GTTT TCCT CGCT ATCT GGCT GTGT
CAGA CAGA TAGA TAGA GAGA TAGA TAGA GAGA TAGA CAGA TAGA GTGA GTGA TAGA GTGA GAGA
ATGA TAGA TAGA CAGA TAGA TAGA CAGA TAGA TAGA CAGA TAGA CAGA TAGA CAGA TAGA TAGA
TAGA CAGA CTGA GAGA CAGA TCGA GTGA TAGA ATGA TAGA TAGA CAGA ATGA TAGA TTGA TAGA
CAGA TAGA TAGA TAGA CAGA CAGA TAGA TAGA ATGA CTGA TAGA ATGA TAGA ATGA ATGA TAGA
TAGA TAGA TAGA TAGA CAGA TAGA CAGA TAGA TAGA CAGA TAGA ACGA ACGA TAGA CAGA TAGA
GAGT TACA AGTT CGCT CACA GCGA CCAA CCAA 


=head1 DESCRIPTION

So you say you're a rabid Perl programmer?  You've got a Camel
tattooed on your arm.  You took your wife to TPC for your second
honeymoon.  But you're worried about your children, they might not be
such devoted Perl addicts.  How do you guarantee the continuation of
the line?  Until now, there was no solution (what, do you think they
teach Perl in school?!)

Through the magic of Gene Splicing, now you can encode your very genes
with the essense of Perl!  Simply take your best one-liner, encode it
with this nifty DNA module and head on down to your local sperm bank
and have them inject that sucker in.


As the encoding of programs on bacterial DNA will soon revolutionize
the data storage industry, I'm downloading the necessary forms from
the US patent office as I write.  Imagine, all of CPAN on an airborne
bacteria.  You can breathe Perl code!


When you use the DNA module on your code, the first time through it
will convert your code into a series of DNA sequences.  Of course,
most of the DNA is simply junk.  We're not sure why... someone spilled
coffee on the documentation.

There's also a slight chance on each use that a mutation will
occur... or maybe its a bug in perl, we're not sure.  Of course, this
means your code may suddenly fall over dead... but you made a few
million copies, right?

POD will, of course, be preserved.  God made the mistake of not
writing docs, and look at all the trouble we've had to go through to
figure out his code!


=head1 NOTES

The tests are encoded in DNA!  But it sometimes introduces bugs... oh
dear.

As Steve Lane pointed out, it would be better to group them into
groups of three rather than four, as this makes a codon.  However,
that means I can only get 6 bits on one group, and God didn't have to
work with high ASCII.


=head1 BUGS

There were only a few flipper babies.


=head1 SEE ALSO

L<Sex>, L<Morse>, L<Bleach>, L<Buffy>, a good psychiatrist.


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>

=cut

1;
