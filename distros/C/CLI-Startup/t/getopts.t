# Test various sorts of command-line options

use Test::More;
use Test::Trap;

eval "use CLI::Startup 'startup'";
plan skip_all => "Can't load CLI::Startup" if $@;

no warnings 'qw';

# Test list-y options
{
    local @ARGV = qw/ --x=a,b --x=c --x="d,1" --x "e,2","f,3",g /;
    my $options = startup({ 'x=s@' => 'listy x option' });
    is_deeply $options->{x},
        [qw/a b c d,1 e,2 f,3 g/],
        "Listy options";
}

# Invalid list-y options should fail
{
    local @ARGV = ( "--x=b,\0", "--x=a" );
    trap { startup({ 'x=s@' => 'listy x option' }) };
    like $trap->stderr, qr/FATAL.*Can't parse/, "Parse dies on invalid CSV";
    ok $trap->stdout eq '', "Nothing printed to stdout";
    ok $trap->exit == 1, "Correct exit status";
}

# Test hash-y options
{
    local @ARGV = qw/ --x=a=1 --x b=2 --x c=3=2+1 /;
    my $options = startup({ 'x=s%' => 'hashy x option' });
    is_deeply $options->{x},
        { a => 1, b => 2, c => '3=2+1' },
        "Hashy options";
}

# Test incremental options
{
    local @ARGV = ('--x')x10;
    my $options = startup({ 'x+' => 'incremental x option' });
    ok $options->{x} == 10, "Incremental options";
}

# Negatable options
{
    local @ARGV = ( '--no-x' );
    my $options = startup({ 'x!' => 'negatable x option' });
    ok $options->{x} == 0, "Negatable options";
}

# Option with an alias
{
    local @ARGV = ( map { "--x$_" } 0..9 );
    my $optspec = join("|", map {"x$_"} 0..9 ) . "+";
    my $options = startup({ $optspec => 'Option with aliases' });
    ok $options->{x0} == 10, "Option with aliases";
}

done_testing();
