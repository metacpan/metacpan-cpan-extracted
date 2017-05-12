use strict;
use Data::FormValidator::Constraints::Japanese qw(:all);

{
    basic => {
        optional => [ qw(hiragana katakana) ],
        constraint_methods => {
            hiragana => hiragana(),
            katakana => katakana(),
        },
    },
    mobile_jp => {
        optional => [ qw(mobile_jp imode ezweb vodafone) ],
        constraint_methods => {
            mobile_jp => jp_mobile_email(),
            imode     => jp_imode_email(),
            ezweb     => jp_ezweb_email(),
            vodafone  => jp_vodafone_email(),
        },
    },
    zip => {
        required => [ qw(zip) ],
        constraint_methods => {
            zip => jp_zip(),
        }
    },
    length => {
        required => [ qw(text) ],
        constraint_methods => {
            text => jp_length(4, 7)
        }
    }
};