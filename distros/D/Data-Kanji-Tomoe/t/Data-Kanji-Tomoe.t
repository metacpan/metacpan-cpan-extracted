use warnings;
use strict;
use Test::More;
BEGIN { use_ok('Data::Kanji::Tomoe') };
use Data::Kanji::Tomoe;
use FindBin;
use utf8;

my %data;
my $tomoe = Data::Kanji::Tomoe->new (
    tomoe_data_file => "$FindBin::Bin/handwriting-zh_CN.xml",
    character_callback => \& callback,
    data => \%data,
);
$data{count} = 0;
$tomoe->parse ();
done_testing ();
exit;

sub callback
{
    my ($tomoe, $c) = @_;
    my $count = $tomoe->{data}->{count};
    $count++;
    if ($count == 1) {
        is ($c->{utf8}, chr (0x4e00));
        is_deeply ($c->{strokes}, [[[75, 464],[923,468]]]);
    }
    elsif ($count == 2) {
        is ($c->{utf8}, chr (0x4e01));
        is_deeply ($c->{strokes}, [[[93, 198],[913,205]],
                                   [[495,203],[470,847],[405,784]]]);
    }
    elsif ($count == 3) {
        is ($c->{utf8}, chr (0x4e03));
        is_deeply ($c->{strokes}, [[[85, 508],[895,338]],
                                   [[465,120],[483,802],[860,800],[905,667]]]);
    }
    $tomoe->{data}->{count} = $count;
}

# Local variables:
# mode: perl
# End:
