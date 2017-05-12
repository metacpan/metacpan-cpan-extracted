use Test::More;
use Capture::Tiny;

use App::Kit;

BEGIN {
    eval 'use App::Kit::Util::RunCom';
    plan skip_all => 'Running::Commentary required for testing runcom()' if $@;
}

diag("Testing ex->runcom() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

{
    my @runcom;
    no warnings 'redefine';
    local *App::Kit::Obj::Ex::run = sub { push @runcom, \@_ };

    my $out = Capture::Tiny::capture_stdout(
        sub {
            $app->ex->runcom(
                'Starting test',
                [ 'step 1' => 'echo foo' ],
                [ 'step 2' => 'echo bar' ],
            );
        }
    );

    is( $out, "-- Starting test --\n", 'runcom() works when use App::Kit::Util::RunCom; has been done - prints expected headings' );

    is_deeply(
        \@runcom,
        [
            [ 'step 1' => 'echo foo' ],
            [ 'step 2' => 'echo bar' ],
        ],
        'runcom() works when use App::Kit::Util::RunCom; has been done - passes expected data to run()'
    );
}

# TODO: more behaviorial tests runcom()

done_testing;
