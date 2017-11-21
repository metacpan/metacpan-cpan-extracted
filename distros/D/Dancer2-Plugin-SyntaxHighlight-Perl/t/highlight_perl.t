use strict; use warnings;
use FindBin qw/ $RealBin /;
use Test::More;
use Path::Tiny;
use Dancer2;
use Dancer2::Plugin::SyntaxHighlight::Perl;

my $filename = "$RealBin/perl.code";
chomp( my $wanted = do { local $/; <DATA> } );

{
    note 'Testing with ref to scalar';

    my $perl = path( $filename )->slurp;
    ok my $html = highlight_perl( \$perl ),         'Got output from plugin';
    is $html, $wanted,                              'Output is correct';
}

{
    note 'Testing with file';

    ok my $html = highlight_perl( $filename ),      'Got output from plugin';
    is $html, $wanted,                              'Output is correct';
}

done_testing;

__DATA__
<span class="keyword">use</span> <span class="pragma">strict</span><span class="structure">;</span> <span class="keyword">use</span> <span class="pragma">warnings</span><span class="structure">;</span>
<span class="keyword">use</span> <span class="pragma">feature</span> <span class="words">qw/ say /</span><span class="structure">;</span>

<span class="keyword">use</span> <span class="word">Time::HiRes</span> <span class="words">qw/ time usleep /</span><span class="structure">;</span>

<span class="keyword">sub</span> <span class="word">say_numbers</span> <span class="structure">{</span> <span class="word">usleep</span><span class="structure">(</span><span class="number">750000</span><span class="structure">)</span> <span class="operator">and</span> <span class="word">say</span> <span class="double">&quot;$_[0] $_&quot;</span> <span class="word">for</span> <span class="number">0</span> <span class="operator">..</span> <span class="number">5</span> <span class="structure">}</span>
<span class="keyword">sub</span> <span class="word">say_letters</span> <span class="structure">{</span> <span class="word">usleep</span><span class="structure">(</span><span class="number">500000</span><span class="structure">)</span> <span class="operator">and</span> <span class="word">say</span> <span class="double">&quot;$_[0] $_&quot;</span> <span class="word">for</span> <span class="single">'a'</span> <span class="operator">..</span> <span class="single">'e'</span> <span class="structure">}</span>

<span class="keyword">my</span> <span class="symbol">$start</span> <span class="operator">=</span> <span class="word">time</span><span class="structure">;</span>

<span class="word">say_numbers</span><span class="structure">(</span><span class="magic">$$</span><span class="structure">);</span>
<span class="word">say_letters</span><span class="structure">(</span><span class="magic">$$</span><span class="structure">);</span>

<span class="keyword">my</span> <span class="symbol">$elapsed</span> <span class="operator">=</span> <span class="word">time</span> <span class="operator">-</span> <span class="symbol">$start</span><span class="structure">;</span>

<span class="word">say</span> <span class="word">sprintf</span> <span class="single">'%s done in %.3fs'</span><span class="operator">,</span> <span class="magic">$$</span><span class="operator">,</span> <span class="symbol">$elapsed</span><span class="structure">;</span>

<span class="separator">__END__</span>
