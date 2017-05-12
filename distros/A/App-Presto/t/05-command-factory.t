use strict;
use warnings;
use Test::More;

use App::Presto::CommandFactory;
use Test::MockObject;
our @commands;
{
    no warnings 'redefine';
    sub App::Presto::CommandFactory::commands {
        return @commands;
    }
}
my $ctx = Test::MockObject->new;
$ctx->set_isa('App::Presto');
isa_ok $ctx, 'App::Presto';

my $f = App::Presto::CommandFactory->new;

isa_ok $f, 'App::Presto::CommandFactory';

is_deeply [$f->commands], [], 'no commands returned from mock';
{
    local @commands = 'MyCommand';
    is_deeply [$f->commands], \@commands, 'has command';

    my $called = 0;

    {
        no warnings 'redefine';
        local *MyCommand::install = sub { $called++; ok shift->context, 'context initialized' };
        $f->install_commands($ctx);
    }

    ok $called, 'install called';
    $called = 0;

    {
        no warnings 'redefine';
        local *MyCommand::help_categories = sub { $called++; return {foo => 'bar'} };
        my $categories = $f->help_categories;
        is_deeply $categories, { MyCommand => { foo => 'bar' } }, 'constructs appropriate help_categories';
        ok $called, 'help_categories called';
    }
}

{
    local @commands = 'MyOtherCommand';
    is_deeply $f->help_categories, {}, 'no help categories';
}



done_testing;

BEGIN {

    package MyCommand;
    use Moo;
    use Test::More;

    with 'App::Presto::InstallableCommand','App::Presto::CommandHasHelp';

    sub install { }
    sub help_categories { }

    package MyOtherCommand;
    use Moo;
    use Test::More;

    with 'App::Presto::InstallableCommand';

    sub install { }

}
