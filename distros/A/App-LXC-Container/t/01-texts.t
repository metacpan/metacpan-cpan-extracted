# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 01-texts.t".
#
# Without "Build" file it could be called with "perl -I../lib 01-texts.t"
# or "perl -Ilib t/01-texts.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 21;
use Test::Warn;

use App::LXC::Container::Texts;

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_msg_tail_texts = qr/ at .*\/App\/LXC\/Container\/Texts.pm line \d{2,}\.?$/;

#####################################
# language tests, lookup of texts, standard output functions
# (error/warning/info):

warning_like
{   App::LXC::Container::Texts::language('XX');   }
{   carped =>
	qr/^language XX is not supported, falling back to en$re_msg_tail/   },
    'unsupported language creates error';

warning_is
{   App::LXC::Container::Texts::language('de');   }
    undef,
    'change to supported language works';
$_ = txt('message__1_missing');
is($_, "text '%s' fehlt", 'found correct German text message');

warning_like
{   $_ = txt('zz_unit_test');   }
{   carped =>
	qr/^text 'zz_unit_test' fehlt, falle auf en zurück$re_msg_tail/   },
    'missing message creates warning';
is($_, 'unit test string', 'found correct fall-back text message');

warnings_like
{   $_ = txt('zz_not_existing');   }
    [ { carped =>
	qr/^text 'zz_not_existing' fehlt, falle auf en zurück$re_msg_tail/ },
      { carped =>
	qr/^text 'zz_not_existing' fehlt$re_msg_tail/ } ],
    'missing message creates warning + error';

warning_is
{   App::LXC::Container::Texts::language('en');   }
    undef,
    'changing back to English works';
$_ = txt('message__1_missing');
is($_, "message '%s' missing", 'found correct English test message');

warning_like
{   $_ = txt('zz_not_existing');   }
{   carped => qr/^message 'zz_not_existing' missing$re_msg_tail/   },
    "missing message in 'en' creates error";

warning_like
{   $_ = txt('zz_unit_test_empty');   }
{   carped => qr/^message 'zz_unit_test_empty' missing$re_msg_tail/   },
    "empty message in 'en' creates error";

warning_like
{   info('message__1_missing', 'something');   }
    qr/^message 'something' missing$re_msg_tail_texts/,
    'info is working correctly';

#####################################
# fatal message:
eval {   fatal('message__1_missing', 'something');   };
like($@, qr/^message 'something' missing$re_msg_tail/,
     'call to fatal aborts correctly');

#####################################
# tabify:

#     1234567890123456789012345678901234567890
$_ = '                  x     y     z z       !';
$_ = tabify($_);
is($_, "\t\t  x\ty     z z\t!", '1st tabify returns correct output');
#234567890123456789012345678901234567890
$_ = '
    a
        b
            c
                d
                    e
                        f
                            g';
$_ = tabify($_);
is($_, "\n    a\n\tb\n\t    c\n\t\td\n\t\t    e\n\t\t\tf\n\t\t\t    g",
   '2nd tabify returns correct output');

#####################################
# debugging levels and messages:

warning_like
{   debug('X');   }
{   carped =>
	qr/^bad debugging level 'X'$re_msg_tail/   },
    'bad debugging level causes error';
warning_like
{   debug(0, 'debug 0');   }
{   carped =>
	qr/^bad debugging level '0'$re_msg_tail/   },
    'wrong debugging level causes error';

warning_is
{   debug(1, 'debug 1');   }
    undef,
    'higher debugging level is suppressed (0 < 1)';
warning_is
{   debug(1);   }
    undef,
    'switching debugging level does not cause an error';
warning_is
{   debug(1, 'debug 1');   }
    "DEBUG\tdebug 1\n",
    'equal debugging level is recorded (1 <= 1)';

debug(2);

# manual test as Test::Warn does not support warnings with embedded newlines!
sub test_multiline_warning()
{
    my $warning = '';
    local $SIG{__WARN__} = sub {
	$warning = join('', @_);
    };
    debug(2, "debug 2\nwith extra line");
    is($warning, "DEBUG\t  debug 2\n\t  with extra line\n",
       'multiple debugging lines in higher level are correct');
}
test_multiline_warning();

debug(0);
warning_is
{   debug(1, 'debug 1');   }
    undef,
    'higher debugging level is suppressed again (0 < 1)';
