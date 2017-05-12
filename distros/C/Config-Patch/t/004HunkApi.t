######################################################################
# Test suite for Config::Patch
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More tests => 13;
use Config::Patch;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $TDIR = ".";
$TDIR = "t" if -d "t";
my $TESTFILE = "$TDIR/testfile";

END { unlink $TESTFILE; }

BEGIN { use_ok('Config::Patch') };

my $TESTDATA; 

####################################################
# 'Replace' in a Makefile
####################################################
$TESTDATA = qq{all:
\tdo-this-and-that

};

Config::Patch->blurt($TESTDATA, $TESTFILE);

my $patcher = Config::Patch->new(
                  file => $TESTFILE);

my $hunk = Config::Patch::Hunk->new(
   key  => "myapp",
   mode => "replace",
   regex => qr(^all:.*?\n\n)sm,
   text => "all:\n\techo 'all is gone!'\n",
);

$patcher->apply( $hunk );

my $data = $patcher->data();
$data =~ s/^\s*#.*\n//mg;
like $data, qr/^all:\s+echo/s, "replace mode";

$patcher->eject( "myapp" );
is $patcher->data(), $TESTDATA, "replace mode ejected with key";

$patcher->apply( $hunk );
like $data, qr/^all:\s+echo/s, "replace mode";

$patcher->eject( $hunk );
is $patcher->data(), $TESTDATA, "replace mode ejected with hunk";


####################################################
# 'insert-after'
####################################################

$TESTDATA = qq{[section]
blah blah
};

$patcher->data( $TESTDATA );

my $patch = Config::Patch::Hunk->new(
    key   => "myapp",
    mode  => "insert-after",
    regex => qr(^\[section\])m,
    text  => "foo=bar"
);

$patcher->apply( $patch );
like $patcher->data(), qr/\[section\].*foo=bar.*blah blah/s, 
     "insert-after";

$patcher->eject( "myapp" );

is $patcher->data(), $TESTDATA, "insert-after patch ejected";

####################################################
# 'insert-before'
####################################################

$TESTDATA = qq{[section]
blah blah
};

$patcher->data( $TESTDATA );

$patch = Config::Patch::Hunk->new(
    key   => "myapp",
    mode  => "insert-before",
    regex => qr(^\[section\])m,
    text  => "[newsection]\nfoo=bar\n\n"
);

$patcher->apply( $patch );

like $patcher->data(),
     qr{\[newsection\].*foo=bar.*\[section\].*blah blah}s,
     "insert-before hunk";

$patcher->eject( "myapp" );
is $patcher->data(), $TESTDATA, "insert-before patch ejected";

####################################################
# update
####################################################
$TESTDATA = qq{
[section]
blah blah
};

$patcher->data( $TESTDATA );

$hunk = Config::Patch::Hunk->new(
    key   => "myapp",
    mode  => "insert-before",
    regex => qr(^\[section\])m,
    text  => "[newsection]\nfoo=bar\n\n"
);

$patcher->apply( $hunk );

$hunk = Config::Patch::Hunk->new(
    key   => "myapp",
    mode  => "update",
    text  => "xxx"
);

$patcher->apply( $hunk );

$data = $patcher->data();
$data =~ s/^\s*#.*\n//mg;

like $data, qr/^xxx.*\[section\]/s, "update";

####################################################
# 'patches_only'
####################################################

$TESTDATA = qq{[section]
blah blah
};

$patcher->data( $TESTDATA );

$patch = Config::Patch::Hunk->new(
    key   => "myapp",
    mode  => "insert-before",
    regex => qr(^\[section\])m,
    text  => "[newsection]\nfoo=bar\n\n"
);

$patcher->apply( $patch );
$patcher->patches_only();
$patcher->eject( "myapp" );

is $patcher->data(), "", "patches-only";

####################################################
# multiple 'insert-before'
####################################################

$TESTDATA = qq{
[section]
blah blah

[section]
woof woof
};

$patcher->data( $TESTDATA );

$patch = Config::Patch::Hunk->new(
    key   => "myapp",
    mode  => "insert-before",
    regex => qr(^\[section\])m,
    text  => "[newsection]\nfoo=bar\n\n"
);

$patcher->apply( $patch );

like $patcher->data(), 
     qr/
      \[newsection\].*foo=bar.*
      \[section\].*blah\sblah.*
      \[newsection\].*foo=bar.*
      \[section\].*woof\swoof
     /xs, "multiple insert-befores";

####################################################
# multiple 'update'
####################################################

$hunk = Config::Patch::Hunk->new(
    key   => "myapp",
    mode  => "update",
    text  => "xxx"
);

$patcher->apply( $hunk );

like $patcher->data, qr/xxx.*\[section\].*xxx.*\[section\]/s, "multi update";
