use warnings;
use strict;

use App::CopyrightImage;
use Hook::Output::Tiny;
use Test::More;
use lib 't/';
use Testing;

my $t = Testing->new;
my $o = Hook::Output::Tiny->new;

{ # no image
    eval { imgcopyright(); };
    like $@, qr/'image' argument/, "dies with no 'image' arg";
}

{ # no name
    eval { imgcopyright(src => $t->base); };
    like $@, qr/'name' argument/, "dies with no 'name' arg";
}
{ # check w/ no name
    $o->flush;
    $o->hook;
    eval { imgcopyright(src => $t->base, check => 1); };
    $o->unhook;
    is $@, '', "doesn't die with no name with check";
}

{ # check single no-copy
    $o->flush;
    $o->hook;
    imgcopyright(src => $t->base, name => 'steve', check => 1);
    $o->unhook;

    is $o->stderr, 0, "no error output on check with no exif"; 

    my @out = $o->stdout;
    is $o->stdout, 1, "proper warning for single img w/no exif";
    like $out[0], qr/Copyright/, "single w/no exif Copyright ok";
    like $out[0], qr/Creator/, "single w/no exif Creator ok";
}
{ # check copy and no-copy
    $o->flush;
    $o->hook;
    imgcopyright(src => $t->build, name => 'steve', check => 1);
    $o->unhook;

    is $o->stderr, 0, "no error output on check with no exif"; 

    my @out = $o->stdout;
    is @out, 1, "proper warning for single img w/no exif";
    like $out[0], qr/Copyright/, "good/bad w/no exif Copyright ok";
    like $out[0], qr/Creator/, "good/bad w/no exif Creator ok";
}

done_testing();
