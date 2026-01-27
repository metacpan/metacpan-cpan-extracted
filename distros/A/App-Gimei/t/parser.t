use v5.40;

use App::Gimei::Parser;
use Test2::Bundle::More;

# test
{
    my @args       = ('name:kanji');
    my $parser     = App::Gimei::Parser->new( args => \@args );
    my $generators = $parser->parse();
}

ok 1;

done_testing();
