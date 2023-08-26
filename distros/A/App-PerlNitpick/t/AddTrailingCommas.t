use Test2::V0;
use PPI::Document;
use App::PerlNitpick::Rule::AddTrailingCommas;

subtest 'add trailing commas' => sub {
    my @tests = (
        [
            q{
               my $x = (
                   'foo',
                   'bar',
                   'baz'
               );
            },
            q{
               my $x = (
                   'foo',
                   'bar',
                   'baz',
               );
            },
         ],
    );

    for my $t (@tests) {
        my ($code_before, $code_after) = @$t;
        my $doc = PPI::Document->new(\$code_before);
        my $o = App::PerlNitpick::Rule::AddTrailingCommas->new();
        my $doc2 = $o->rewrite($doc);
        my $code2 = "$doc2";
        is $code2, $code_after, $code_before;
    }
};



done_testing;
