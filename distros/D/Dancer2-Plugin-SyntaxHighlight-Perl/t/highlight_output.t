use strict; use warnings;
use FindBin qw/ $RealBin /;
use Test::More;
use Path::Tiny;
use Dancer2;
use Dancer2::Plugin::SyntaxHighlight::Perl;

my $filename = "$RealBin/perl.code.output";
chomp( my $wanted = do { local $/; <DATA> } );

{
    note 'Testing with ref to scalar';

    my $perl = path( $filename )->slurp;
    ok my $html = highlight_output( \$perl ),            'Got output from plugin';
    is $html, $wanted,                                   'Output is correct';
}

{
    note 'Testing with file';

    ok my $html = highlight_output( $filename ),         'Got output from plugin';
    is $html, $wanted,                                   'Output is correct';
}

done_testing;

__DATA__
<span class="prompt">$ perl inc/fork-01.pl </span>
<span class="output">25470 0</span>
<span class="output">25470 1</span>
<span class="output">25470 2</span>
<span class="output">25470 3</span>
<span class="output">25470 4</span>
<span class="output">25470 5</span>
<span class="output">25470 a</span>
<span class="output">25470 b</span>
<span class="output">25470 c</span>
<span class="output">25470 d</span>
<span class="output">25470 e</span>
<span class="output">25470 done in 7.003s</span>
