use strict; use warnings;
use Test::More;
use Dancer2;
use Plack::Test;
use HTTP::Request::Common;

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::SyntaxHighlight::Perl;
    use FindBin qw/ $RealBin /;
    my $code_filename = "$RealBin/perl.code";
    set plugins => { 'SyntaxHighlight::Perl' => { line_numbers => 1 } };
    get '/' => sub {
        return highlight_perl( $code_filename );
    };
}

my $testapp = TestApp->to_app;

chomp( my $wanted = do { local $/; <DATA> } );

test_psgi $testapp, sub {
    my $cb = shift;
    my $res  = $cb->( GET '/' );
    ok( $res->is_success,                           'request to / was successful' );
    is( $res->content, $wanted,                     'page content is as expected' );
};


done_testing;

__DATA__
<span class="line_number"> 1: </span><span class="keyword">use</span> <span class="pragma">strict</span><span class="structure">;</span> <span class="keyword">use</span> <span class="pragma">warnings</span><span class="structure">;</span>
<span class="line_number"> 2: </span><span class="keyword">use</span> <span class="pragma">feature</span> <span class="words">qw/ say /</span><span class="structure">;</span>
<span class="line_number"> 3: </span>
<span class="line_number"> 4: </span><span class="keyword">use</span> <span class="word">Time::HiRes</span> <span class="words">qw/ time usleep /</span><span class="structure">;</span>
<span class="line_number"> 5: </span>
<span class="line_number"> 6: </span><span class="keyword">sub</span> <span class="word">say_numbers</span> <span class="structure">{</span> <span class="word">usleep</span><span class="structure">(</span><span class="number">750000</span><span class="structure">)</span> <span class="operator">and</span> <span class="word">say</span> <span class="double">&quot;$_[0] $_&quot;</span> <span class="word">for</span> <span class="number">0</span> <span class="operator">..</span> <span class="number">5</span> <span class="structure">}</span>
<span class="line_number"> 7: </span><span class="keyword">sub</span> <span class="word">say_letters</span> <span class="structure">{</span> <span class="word">usleep</span><span class="structure">(</span><span class="number">500000</span><span class="structure">)</span> <span class="operator">and</span> <span class="word">say</span> <span class="double">&quot;$_[0] $_&quot;</span> <span class="word">for</span> <span class="single">'a'</span> <span class="operator">..</span> <span class="single">'e'</span> <span class="structure">}</span>
<span class="line_number"> 8: </span>
<span class="line_number"> 9: </span><span class="keyword">my</span> <span class="symbol">$start</span> <span class="operator">=</span> <span class="word">time</span><span class="structure">;</span>
<span class="line_number">10: </span>
<span class="line_number">11: </span><span class="word">say_numbers</span><span class="structure">(</span><span class="magic">$$</span><span class="structure">);</span>
<span class="line_number">12: </span><span class="word">say_letters</span><span class="structure">(</span><span class="magic">$$</span><span class="structure">);</span>
<span class="line_number">13: </span>
<span class="line_number">14: </span><span class="keyword">my</span> <span class="symbol">$elapsed</span> <span class="operator">=</span> <span class="word">time</span> <span class="operator">-</span> <span class="symbol">$start</span><span class="structure">;</span>
<span class="line_number">15: </span>
<span class="line_number">16: </span><span class="word">say</span> <span class="word">sprintf</span> <span class="single">'%s done in %.3fs'</span><span class="operator">,</span> <span class="magic">$$</span><span class="operator">,</span> <span class="symbol">$elapsed</span><span class="structure">;</span>
<span class="line_number">17: </span>
<span class="line_number">18: </span><span class="separator">__END__</span>
<span class="line_number">19: </span>
