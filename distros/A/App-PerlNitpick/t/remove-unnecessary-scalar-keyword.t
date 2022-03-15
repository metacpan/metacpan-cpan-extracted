#!perl
use Test2::V0;

use App::PerlNitpick::Rule::RemoveUnnecessaryScalarKeyword;

subtest 'Remove only the imported subroutine' => sub {

    my $code_in = 'my $n = scalar @items;';
    my $code_out = 'my $n = @items;';

    my $doc = PPI::Document->new(\$code_in);
    my $o = App::PerlNitpick::Rule::RemoveUnnecessaryScalarKeyword->new();
    my $doc2 = $o->rewrite($doc);
    is "$doc2", $code_out;
};

done_testing;
