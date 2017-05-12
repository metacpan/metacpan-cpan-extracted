use Test;
BEGIN{plan test => 8 };
use Algorithm::LCSS qw( LCSS CSS CSS_Sorted );;
ok(1);

my $seq1 = 'abcdefghijklmnopqrstuvwxyz';
my $seq2 = 'flubberabcdubberdofghijklm';
my @seq1 = split //, $seq1;
my @seq2 = split //, $seq2;
my $css = CSS_Sorted( $seq1, $seq2 );
ok( @$css, 3 );
ok( "@$css", 'fghijklm abcd e' );
$css = CSS_Sorted( \@seq1, \@seq2 );
ok( @$css, 3 );
ok( @{$css->[0]}, 8 );
ok( "@{$css->[1]}", 'a b c d' );
my $lcss = LCSS($seq1, $seq2);
ok( $lcss, 'fghijklm' );
$lcss = LCSS( \@seq1, \@seq2 );
ok( "@$lcss", 'f g h i j k l m' );

