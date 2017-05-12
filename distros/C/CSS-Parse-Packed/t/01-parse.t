use strict;
use warnings;

use Test::More;
use CSS;

sub _parse {
    my $css = CSS->new({ parser => 'CSS::Parse::Packed' });
    $css->parse_string(@_);
    return $css->output;
}

subtest 'merge element simple' => sub {
    my $css = _parse(<<CSS);
body { background-color:#FFFFFF; }
body { padding:6px; }
CSS

    ok $css =~ /background-color:/ && $css =~ /padding:/;
};

subtest 'merge id simple' => sub {
    my $css = _parse(<<'CSS');
#content { background-color:#FFFFFF; }
#content { padding:6px; }
CSS

    ok $css =~ /background-color:/ && $css =~ /padding:/;
};

subtest 'merge same property' => sub {
    my $css = _parse(<<'CSS');
.body { background-color:#FFFFFF; font-size: 1em; }
.body { padding:6px; font-size: 1.5em; }
CSS

    ok $css =~ /background-color:/ && $css =~ /padding:/;
};

subtest 'ignore charset && import' => sub {
    my $css = _parse(<<'CSS');
@charset "utf-8";
@import url("http://example.com/styles.css");
body { color: #333333; }
CSS

    like $css, qr/^body \{ color: \#333333 \}\s*$/;
};

subtest 'ignore invalid styles' => sub {
    my $css = _parse(<<'CSS');
body { #333333 }
body { padding: 6px; }
CSS

    like $css, qr/^body \{ padding: 6px \}\s*$/;
};

done_testing;
