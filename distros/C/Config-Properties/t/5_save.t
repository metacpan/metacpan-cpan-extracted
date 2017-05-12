# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 26;
use Config::Properties;
use File::Temp qw(tempfile);

my $cfg=Config::Properties->new();
$cfg->load(\*DATA);

my ($fh, $fn)=tempfile()
    or die "unable to create temporal file to save properties";

# print STDERR "saving properties to '$fn'\n";

$cfg->store($fh, "test header");
close ($fh)
    or die "unable to close temporal file with properties saved";

open(R, '<', $fn)
    or die "unable to open temporal file with properties saved";

my $cfg2=Config::Properties->new();
$cfg2->load(\*R);

close R
    or die "unable to read temporal file with properties saved";

# use Assert::Quote ':short';

foreach my $k ($cfg->propertyNames, $cfg2->propertyNames) {
    is ($cfg->getProperty($k), $cfg2->getProperty($k), "same key/value")

#    $cfg->getProperty($k) eq $cfg2->getProperty($k)
#     or D($cfg->getProperty($k), $cfg2->getProperty($k))
#       or print STDERR S($k), "\n1:", A, "\n2:", B, "\n\n";
	
}

unlink $fn;

__DATA__
# hello
foo=one
    Bar : maybe one\none\tone\r
eq\=ua\:l jamon\njamon\njamon\nmas\tjamon

\ spaces\  = \ at the begining and at the end \
in the key and in the\nvalue

more : another \
    configuration \
    line
less= who said:\tless ??? 

cra\n\=\:\ \\z'y' jump

long\ line = Text::Wrap::wrap()" has a number of variables that control its behav- \
       ior.  Because other modules might be using "Text::Wrap::wrap()" it is \
       suggested that you leave these variables alone!  If you can't do that, \
       then use "local($Text::Wrap::VARIABLE) = YOURVALUE" when you change the \
       values so that the original value is restored.  This "local()" trick \
       will not work if you import the variable into your own namespace.
wrap-me: \ \ \ \ \ \  \ \\  \\\\\ \\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ hello!

cmd3=/usr/share/Artemis/bin/loki -vip 10.51.100.120 -file f3058 -it 10 -repeat 100000000 -proc read -vdir /vol1 -useGateway 172.16.254.254 %ETH%

too\ many\ spaces:\                                                                                                        hello again!

# comment = hello
\# comment = bye

! comment2 = good
\! comment2 = bye
