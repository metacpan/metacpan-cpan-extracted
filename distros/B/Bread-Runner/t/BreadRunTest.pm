package BreadRunTest;
use Bread::Board;

my $c = container 'BreadRunTest' => as {
    container 'App' => as {
        service 'api.psgi' => (
            class        => 'BreadRunTest::Psgi',
            lifecycle => "Singleton",
            dependencies=>{
                foo=>'/Model/Foo',
            }
        );
        service 'some_script' => (
            class => 'BreadRunTest::Commandline',
            lifecycle => "Singleton",
            parameters => {
                string   => { isa => 'Str', required => 1 },
                flag     => { isa => 'Bool', required => 1 },
                int => { isa => 'Int', optional => 1 },
                array => { isa => 'ArrayRef', optional => 1 },
            },
        );
        service 'will_die' => (
            class        => 'BreadRunTest::Die',
        );
    };
    container 'Model' => as {
        service 'Foo' => (
            class        => 'BreadRunTest::Foo',
        )
    }
};

sub init {
    return $c;
}

1;
