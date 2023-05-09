use v5.16;
use warnings;

use Test::More;
use lib "t/lib";
use Util;

use App::ChangeShebang;

plan skip_all => "doesn't support windows!" if $^O eq 'MSWin32';

subtest basic1 => sub {
    my $tempdir = tempdir;
    spew "$tempdir/hoge$_.pl", "#!/path/to/perl\n" for 1..3;

    App::ChangeShebang->new
        ->parse_options("-f", "-q", map "$tempdir/hoge$_.pl", 1..3)
        ->run;
    is slurp("$tempdir/hoge$_.pl"), <<'...' for 1..3;
#!/bin/sh
exec "$(dirname "$0")"/perl -x "$0" "$@"
#!perl
...
};

subtest basic2 => sub {
    my $tempdir = tempdir;
    spew "$tempdir/hoge.pl", "#!/usr/bin/env perl\n";
    spew "$tempdir/hoge.rb", "#!/usr/bin/ruby\n";

    App::ChangeShebang->new
        ->parse_options("-f", "-q", "$tempdir/hoge.pl", "$tempdir/hoge.rb")
        ->run;
    is slurp("$tempdir/hoge.pl"), <<'...';
#!/bin/sh
exec "$(dirname "$0")"/perl -x "$0" "$@"
#!perl
...
    is slurp("$tempdir/hoge.rb"), "#!/usr/bin/ruby\n";
};

subtest permission => sub {
    my $tempdir = tempdir;
    spew "$tempdir/hoge$_.pl", "#!/path/to/perl\n" for 1..3;
    chmod 0755, "$tempdir/hoge1.pl";
    chmod 0555, "$tempdir/hoge2.pl";
    chmod 0500, "$tempdir/hoge3.pl";

    App::ChangeShebang->new
        ->parse_options("-f", "-q", map "$tempdir/hoge$_.pl", 1..3)
        ->run;
    is slurp("$tempdir/hoge$_.pl"), <<'...' for 1..3;
#!/bin/sh
exec "$(dirname "$0")"/perl -x "$0" "$@"
#!perl
...
    is( (stat "$tempdir/hoge1.pl")[2] & 07777, 0755 );
    is( (stat "$tempdir/hoge2.pl")[2] & 07777, 0555 );
    is( (stat "$tempdir/hoge3.pl")[2] & 07777, 0500 );
};

subtest 'remove "not running under some shell"' => sub {
    my $tempdir = tempdir;
    spew "$tempdir/hoge1.pl", <<'...';
#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
use strict;
...
    spew "$tempdir/hoge2.pl", <<'...';
#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
...
spew "$tempdir/hoge3.pl", <<'...';
#!/usr/bin/perl
    eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
    if $running_under_some_shell;
#!/usr/bin/perl
use strict;
...
spew "$tempdir/hoge4.pl", <<'...';
#!/usr/bin/perl

eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
    if 0; # not running under some shell
    eval 'exec perl -S $0 "$@"'
        if 0;

#!/usr/local/bin/perl
use strict;
...

    App::ChangeShebang->new
        ->parse_options("-f", "-q", map "$tempdir/hoge$_.pl", 1..4)
        ->run;
    my $expect = <<'...';
#!/bin/sh
exec "$(dirname "$0")"/perl -x "$0" "$@"
#!perl
...

    is slurp("$tempdir/hoge1.pl"), $expect . "use strict;\n";
    is slurp("$tempdir/hoge2.pl"), $expect . "\nuse strict;\n";
    is slurp("$tempdir/hoge3.pl"), $expect . "use strict;\n";
    is slurp("$tempdir/hoge4.pl"), $expect . "use strict;\n";
};

done_testing;
