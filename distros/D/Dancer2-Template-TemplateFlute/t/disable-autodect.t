use strict;
use warnings;

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'disable-autodect';
}

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{
    package My::Namespace;

    sub new {
        my ( $class, %args ) = @_;
        bless \%args, $class;
    }
}

{
    package My::Namespace::Class;
    use base 'My::Namespace';
}

{
    package Other::Namespace;

    sub new {
        my ( $class, %args ) = @_;
        bless \%args, $class;
    }
}

{
    package Other::Namespace::Class;
    use base 'Other::Namespace';
}

{
    package Good::Namespace::Class;

    sub new {
        my ( $class, %args ) = @_;
        bless \%args, $class;
    }

    sub salute {
        return "I'm a good class!";
    }
}

{
    package TestApp;
    use Dancer2;

    get '/' => sub {
        session salute => "Hello session";
        my %values = (
            first  => My::Namespace::Class->new( salute    => "Object 1" ),
            second => Other::Namespace::Class->new( salute => "Object 2" ),
            third  => Good::Namespace::Class->new(),
        );
        template objects => \%values;
    };
}

my $test = Plack::Test->create( TestApp->to_app );
my $trap = TestApp->dancer_app->logger_engine->trapper;

my $res = $test->request( GET '/' );
ok $res->is_success, "GET / successful" or diag explain $trap->read;

my $expected = <<'HTML';
<body>
<span class="firstobj">Object 1</span>
<span class="secondobj">Object 2</span>
<span class="thirdobj">I'm a good class!</span>
<span class="sessionobj">Hello session</span><
/body>
HTML

$expected =~ s/\n//sg;

like $res->content, qr{\Q$expected\E}, "GET / content is good";

is_deeply $trap->read, [], "Empty logs, all good";

done_testing;
