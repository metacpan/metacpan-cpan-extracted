use strict;
use warnings;
use Test::More;
use Test::Output;

use App::Term2HTML;

{
    open my $IN, '<', \"\e[31mfoo\033[1;32mbar\033[0m";
    local *STDIN = *$IN;
    stdout_like {
        App::Term2HTML->run;
    } qr|<style>[^<]+</style>\n<pre><span class="red">foo</span><span class="bold green">bar</span></pre>|;
    close $IN;
}

{
    open my $IN, '<', \"\e[31mfoo\033[1;32mbar\033[0m";
    local *STDIN = *$IN;
    stdout_is {
        App::Term2HTML->run('--inline-style');
    } qq|<pre><span style="color: #f33;">foo</span><span style="font-weight: bold; color: #2c2;">bar</span></pre>\n|;
    close $IN;
}

done_testing;
