use strict;
use Test::More 0.98;

use App::CPANfile2OPML;

my $app = App::CPANfile2OPML->new;
isa_ok $app, 'App::CPANfile2OPML';

subtest 'outline' => sub {
    my $result = $app->convert_file('cpanfile');
    like $result, qr{<outline htmlUrl="https://metacpan.org/pod/XML::Simple" title="XML::Simple" xmlUrl="https://metacpan.org/feed/distribution/XML-Simple" />};
};

subtest 'phase' => sub {
    my $result = $app->convert_file('cpanfile', ['test']);
    unlike $result, qr{<outline htmlUrl="https://metacpan.org/pod/XML::Simple" title="XML::Simple" xmlUrl="https://metacpan.org/feed/distribution/XML-Simple" />};
    like $result, qr{<outline htmlUrl="https://metacpan.org/pod/Test::More" title="Test::More" xmlUrl="https://metacpan.org/feed/distribution/Test-More" />};
};

done_testing;

