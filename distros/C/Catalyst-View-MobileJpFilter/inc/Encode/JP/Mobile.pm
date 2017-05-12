#line 1
package Encode::JP::Mobile;
use strict;
our $VERSION = "0.25";

use Carp;
use Encode;
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use base qw( Exporter );
our @EXPORT_OK = qw( InDoCoMoPictograms InKDDIPictograms InSoftBankPictograms InAirEdgePictograms InMobileJPPictograms InKDDISoftBankConflicts InKDDICP932Pictograms InKDDIAutoPictograms);
our %EXPORT_TAGS = ( props => [@EXPORT_OK] );

use Encode::Alias;

# sjis-raw
define_alias( 'x-sjis-imode-raw'         => 'x-sjis-docomo-raw' );
define_alias( 'x-sjis-airedge-raw'       => 'x-sjis-airh-raw' );
define_alias( 'x-sjis-vodafone-auto-raw' => 'x-sjis-softbank-auto-raw' );

define_alias( 'x-sjis-kddi'              => 'x-sjis-kddi-cp932-raw' );
define_alias( 'x-sjis-ezweb'             => 'x-sjis-kddi-cp932-raw' );
define_alias( 'x-sjis-ezweb-cp932-raw'   => 'x-sjis-kddi-cp932-raw' );
define_alias( 'x-sjis-ezweb-auto-raw'    => 'x-sjis-kddi-auto-raw' );

# backward compatiblity
define_alias('shift_jis-kddi'       => 'x-sjis-kddi-cp932-raw');

# utf8
define_alias( 'x-utf8-imode'    => 'x-utf8-docomo' );
define_alias( 'x-utf8-ezweb'    => 'x-utf8-kddi' );
define_alias( 'x-utf8-vodafone' => 'x-utf8-softbank' );

use Encode::JP::Mobile::Vodafone;
use Encode::JP::Mobile::KDDIJIS;
use Encode::JP::Mobile::AirHJIS;
use Encode::JP::Mobile::ConvertPictogramSJIS;

use Encode::JP::Mobile::MIME::DoCoMo;
use Encode::JP::Mobile::MIME::KDDI;
use Encode::JP::Mobile::MIME::SoftBank;
use Encode::JP::Mobile::MIME::AirH;

require Encode::JP::Mobile::Fallback;
require Encode::JP::Mobile::Character;

use Encode::MIME::Name;

for (Encode->encodings('JP::Mobile')) {
    next if defined $Encode::MIME::Name::MIME_NAME_OF{$_};
    my $mime_name = $_ =~ /utf8/i ? 'UTF-8'
                  : $_ =~ /sjis/i ? 'Shift_JIS'
                  : $_ =~ /2022/i ? 'ISO-2022-JP'
                  : undef;
    $Encode::MIME::Name::MIME_NAME_OF{$_} = $mime_name if $mime_name;
}

sub InDoCoMoPictograms {
    return <<END;
E63E\tE6A5
E6AC\tE6AE
E6B1\tE6B3
E6B7\tE6BA
E6CE\tE757
END
}

sub InKDDICP932Pictograms {
    return <<END;
E468\tE5DF
EA80\tEB88
END
}

sub InKDDIAutoPictograms {
    return <<END;
EC40\tEC7E
EC80\tECFC
ED40\tED7E
ED80\tED8D
EF40\tEF7E
EF80\tEFFC
F040\tF07E
F080\tF0FC
END
}

sub InKDDIPictograms {
    return join "\n", InKDDICP932Pictograms(), InKDDIAutoPictograms();
}

sub InSoftBankPictograms {
    return <<END;
E001\tE05A
E101\tE15A
E201\tE253
E255\tE257
E301\tE34D
E401\tE44C
E501\tE537
END
}

sub InAirEdgePictograms {
    return <<END;
E000\tE096
E098
E09A
E09F
E0A2
E0A6
E0A8
E0AF
E0BB
E0C4
E0C9
END
}

sub InMobileJPPictograms {
    # +utf8::InDoCoMoPictograms etc. don't work here
    return join "\n", InDoCoMoPictograms, InKDDIPictograms, InSoftBankPictograms, InAirEdgePictograms;
}

sub InKDDISoftBankConflicts {
    return <<END;
E501\tE537
END
}

1;
__END__

=encoding utf-8

#line 350
