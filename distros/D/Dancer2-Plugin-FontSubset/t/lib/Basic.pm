package Basic;

use Dancer2;

BEGIN {
    set public_dir => './t/lib',
    set plugins => { FontSubset => { fonts_dir => 'fonts' } };
}

use Dancer2::Plugin::FontSubset;


1;
