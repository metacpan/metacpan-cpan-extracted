######################################################################
#
# 1028_mb3.t
#
# Copyright (c) 2019, 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use CP932X::R2;
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        /\A"\\c\)" is more clearly written simply as "i" at /   ? return :
        /\A"\\c\)" is more clearly written simply as "i" in /   ? return :
        /\A"\\c\}" is more clearly written simply as "\\=" at / ? return :
        /\A"\\c\}" is more clearly written simply as "\\=" in / ? return :
        /\AIllegal hex digit ignored at /                       ? return :
        /\AUnrecognized escape \\H passed through at /          ? return :
        /\AUnrecognized escape \\R passed through at /          ? return :
        /\AUnrecognized escape \\V passed through at /          ? return :
        /\AUnrecognized escape \\h passed through at /          ? return :
        /\AUnrecognized escape \\v passed through at /          ? return :
        /\A\\C is deprecated in regex; marked by <-- HERE in /  ? return :
        warn $_[0];
    };
}

@test = (
# 1
    sub {                         "x\c)"    =~ $mb{qr/(.)\c)/}                },
    sub {                         "x\c)"    =~ $mb{qr/(.)\c)?/}               },
    sub {                         "x\c)"    =~ $mb{qr/(.)\c)+/}               },
    sub {                         "x\c)"    =~ $mb{qr/(.)\c)*/}               },
    sub {                         "x\c)"    =~ $mb{qr/(.)\c){1}/}             },
    sub {                         "x\c)"    =~ $mb{qr/(.)\c){1,}/}            },
    sub {                         "x\c)"    =~ $mb{qr/(.)\c){1,2}/}           },
    sub {                         "x\c}"    =~ $mb{qr/(.)\c}/}                },
    sub { ($] < 5.014) or eval q< "x\c}"    =~ $mb{qr/(.)\c}+/}              >},
    sub {                         "x\c]"    =~ $mb{qr/(.)\c]/}                },
# 11
    sub {                         "x\c]"    =~ $mb{qr/(.)\c]?/}               },
    sub {                         "x\c]"    =~ $mb{qr/(.)\c]+/}               },
    sub {                         "x\c]"    =~ $mb{qr/(.)\c]*/}               },
    sub {                         "x\c]"    =~ $mb{qr/(.)\c]{1}/}             },
    sub {                         "x\c]"    =~ $mb{qr/(.)\c]{1,}/}            },
    sub {                         "x\c]"    =~ $mb{qr/(.)\c]{1,2}/}           },
    sub {                         "x\cX"    =~ $mb{qr/(.)\cX/}                },
    sub {                         "x\cX"    =~ $mb{qr/(.)\cX?/}               },
    sub {                         "x\cX"    =~ $mb{qr/(.)\cX+/}               },
    sub {                         "x\cX"    =~ $mb{qr/(.)\cX*/}               },
# 21
    sub {                         "x\cX"    =~ $mb{qr/(.)\cX{1}/}             },
    sub {                         "x\cX"    =~ $mb{qr/(.)\cX{1,}/}            },
    sub {                         "x\cX"    =~ $mb{qr/(.)\cX{1,2}/}           },
    sub {                         "x\)"     =~ $mb{qr/(.)\)/}                 },
    sub {                         "x\)"     =~ $mb{qr/(.)\)?/}                },
    sub {                         "x\)"     =~ $mb{qr/(.)\)+/}                },
    sub {                         "x\)"     =~ $mb{qr/(.)\)*/}                },
    sub {                         "x\)"     =~ $mb{qr/(.)\){1}/}              },
    sub {                         "x\)"     =~ $mb{qr/(.)\){1,}/}             },
    sub {                         "x\)"     =~ $mb{qr/(.)\){1,2}/}            },
# 31
    sub {                         "x\}"     =~ $mb{qr/(.)\}/}                 },
    sub { ($] < 5.014) or eval q< "x\}"     =~ $mb{qr/(.)\}+/}               >},
    sub {                         "x\]"     =~ $mb{qr/(.)\]/}                 },
    sub {                         "x\]"     =~ $mb{qr/(.)\]?/}                },
    sub {                         "x\]"     =~ $mb{qr/(.)\]+/}                },
    sub {                         "x\]"     =~ $mb{qr/(.)\]*/}                },
    sub {                         "x\]"     =~ $mb{qr/(.)\]{1}/}              },
    sub {                         "x\]"     =~ $mb{qr/(.)\]{1,}/}             },
    sub {                         "x\]"     =~ $mb{qr/(.)\]{1,2}/}            },
    sub {                         "x\""     =~ $mb{qr/(.)\"/}                 },
# 41
    sub {                         "x\""     =~ $mb{qr/(.)\"?/}                },
    sub {                         "x\""     =~ $mb{qr/(.)\"+/}                },
    sub {                         "x\""     =~ $mb{qr/(.)\"*/}                },
    sub {                         "x\""     =~ $mb{qr/(.)\"{1}/}              },
    sub {                         "x\""     =~ $mb{qr/(.)\"{1,}/}             },
    sub {                         "x\""     =~ $mb{qr/(.)\"{1,2}/}            },
    sub {                         "x\0"     =~ $mb{qr/(.)\0/}                 },
    sub {                         "x\0"     =~ $mb{qr/(.)\0?/}                },
    sub {                         "x\0"     =~ $mb{qr/(.)\0+/}                },
    sub {                         "x\0"     =~ $mb{qr/(.)\0*/}                },
# 51
    sub {                         "x\0"     =~ $mb{qr/(.)\0{1}/}              },
    sub {                         "x\0"     =~ $mb{qr/(.)\0{1,}/}             },
    sub {                         "x\0"     =~ $mb{qr/(.)\0{1,2}/}            },
    sub {                         "xx"      =~ $mb{qr/(.)\1/}                 },
    sub {                         "xx"      =~ $mb{qr/(.)\1?/}                },
    sub {                         "xx"      =~ $mb{qr/(.)\1+/}                },
    sub {                         "xx"      =~ $mb{qr/(.)\1*/}                },
    sub {                         "xx"      =~ $mb{qr/(.)\1{1}/}              },
    sub {                         "xx"      =~ $mb{qr/(.)\1{1,}/}             },
    sub {                         "xx"      =~ $mb{qr/(.)\1{1,2}/}            },
# 61
    sub {                         "x\\"     =~ $mb{qr/(.)\\/}                 },
    sub {                         "x\\"     =~ $mb{qr/(.)\\?/}                },
    sub {                         "x\\"     =~ $mb{qr/(.)\\+/}                },
    sub {                         "x\\"     =~ $mb{qr/(.)\\*/}                },
    sub {                         "x\\"     =~ $mb{qr/(.)\\{1}/}              },
    sub {                         "x\\"     =~ $mb{qr/(.)\\{1,}/}             },
    sub {                         "x\\"     =~ $mb{qr/(.)\\{1,2}/}            },
    sub {                         "x\n"     =~ $mb{qr/(.)\n/}                 },
    sub {                         "x\n"     =~ $mb{qr/(.)\n?/}                },
    sub {                         "x\n"     =~ $mb{qr/(.)\n+/}                },
# 71
    sub {                         "x\n"     =~ $mb{qr/(.)\n*/}                },
    sub {                         "x\n"     =~ $mb{qr/(.)\n{1}/}              },
    sub {                         "x\n"     =~ $mb{qr/(.)\n{1,}/}             },
    sub {                         "x\n"     =~ $mb{qr/(.)\n{1,2}/}            },
    sub {                         "x\r"     =~ $mb{qr/(.)\r/}                 },
    sub {                         "x\r"     =~ $mb{qr/(.)\r?/}                },
    sub {                         "x\r"     =~ $mb{qr/(.)\r+/}                },
    sub {                         "x\r"     =~ $mb{qr/(.)\r*/}                },
    sub {                         "x\r"     =~ $mb{qr/(.)\r{1}/}              },
    sub {                         "x\r"     =~ $mb{qr/(.)\r{1,}/}             },
# 81
    sub {                         "x\r"     =~ $mb{qr/(.)\r{1,2}/}            },
    sub {                         "x\t"     =~ $mb{qr/(.)\t/}                 },
    sub {                         "x\t"     =~ $mb{qr/(.)\t?/}                },
    sub {                         "x\t"     =~ $mb{qr/(.)\t+/}                },
    sub {                         "x\t"     =~ $mb{qr/(.)\t*/}                },
    sub {                         "x\t"     =~ $mb{qr/(.)\t{1}/}              },
    sub {                         "x\t"     =~ $mb{qr/(.)\t{1,}/}             },
    sub {                         "x\t"     =~ $mb{qr/(.)\t{1,2}/}            },
    sub {                         "x(a)"    =~ $mb{qr/(.)(a)/}                },
    sub {                         "x(a)"    =~ $mb{qr/(.)(a)?/}               },
# 91
    sub {                         "x(a)"    =~ $mb{qr/(.)(a)+/}               },
    sub {                         "x(a)"    =~ $mb{qr/(.)(a)*/}               },
    sub {                         "x(a)"    =~ $mb{qr/(.)(a){1}/}             },
    sub {                         "x(a)"    =~ $mb{qr/(.)(a){1,}/}            },
    sub {                         "x(a)"    =~ $mb{qr/(.)(a){1,2}/}           },
    sub {                         "xa{1}"   =~ $mb{qr/(.)a{1}/}               },
    sub {1},
    sub {                         "x[a]"    =~ $mb{qr/(.)[a]/}                },
    sub {                         "x[a]"    =~ $mb{qr/(.)[a]?/}               },
    sub {                         "x[a]"    =~ $mb{qr/(.)[a]+/}               },
# 101
    sub {                         "x[a]"    =~ $mb{qr/(.)[a]*/}               },
    sub {                         "x[a]"    =~ $mb{qr/(.)[a]{1}/}             },
    sub {                         "x[a]"    =~ $mb{qr/(.)[a]{1,}/}            },
    sub {                         "x[a]"    =~ $mb{qr/(.)[a]{1,2}/}           },
    sub {                         "xa"      =~ $mb{qr/(.)a/}                  },
    sub {                         "xa"      =~ $mb{qr/(.)a?/}                 },
    sub {                         "xa"      =~ $mb{qr/(.)a+/}                 },
    sub {                         "xa"      =~ $mb{qr/(.)a*/}                 },
    sub {                         "xa"      =~ $mb{qr/(.)a{1}/}               },
    sub {                         "xa"      =~ $mb{qr/(.)a{1,}/}              },
# 111
    sub {                         "xa"      =~ $mb{qr/(.)a{1,2}/}             },
    sub {                         "x."      =~ $mb{qr/(.)./}                  },
    sub {                         "x."      =~ $mb{qr/(.).?/}                 },
    sub {                         "x."      =~ $mb{qr/(.).+/}                 },
    sub {                         "x."      =~ $mb{qr/(.).*/}                 },
    sub {                         "x."      =~ $mb{qr/(.).{1}/}               },
    sub {                         "x."      =~ $mb{qr/(.).{1,}/}              },
    sub {                         "x."      =~ $mb{qr/(.).{1,2}/}             },
    sub {                         "x\012"   =~ $mb{qr/(.)\012/}               },
    sub {                         "x\012"   =~ $mb{qr/(.)\012?/}              },
# 121
    sub {                         "x\012"   =~ $mb{qr/(.)\012+/}              },
    sub {                         "x\012"   =~ $mb{qr/(.)\012*/}              },
    sub {                         "x\012"   =~ $mb{qr/(.)\012{1}/}            },
    sub {                         "x\012"   =~ $mb{qr/(.)\012{1,}/}           },
    sub {                         "x\012"   =~ $mb{qr/(.)\012{1,2}/}          },
    sub {                         "x\x12"   =~ $mb{qr/(.)\x12/}               },
    sub {                         "x\x12"   =~ $mb{qr/(.)\x12?/}              },
    sub {                         "x\x12"   =~ $mb{qr/(.)\x12+/}              },
    sub {                         "x\x12"   =~ $mb{qr/(.)\x12*/}              },
    sub {                         "x\x12"   =~ $mb{qr/(.)\x12{1}/}            },
# 131
    sub {                         "x\x12"   =~ $mb{qr/(.)\x12{1,}/}           },
    sub {                         "x\x12"   =~ $mb{qr/(.)\x12{1,2}/}          },
    sub { ($] < 5.014) or eval q< "x\o{12}" =~ $mb{qr/(.)\o{12}/}            >},
    sub { ($] < 5.014) or eval q< "x\o{12}" =~ $mb{qr/(.)\o{12}+/}           >},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
