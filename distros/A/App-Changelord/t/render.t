use Test2::V0;

use v5.36.0;

package TestMe {
    use Moo;
    with  'App::Changelord::Role::Render';
    with 'App::Changelord::Role::ChangeTypes';

    has changelog => (
        is => 'ro',
        default => sub {{
             project => { ticket_url => undef }
        }}
    );

    sub set_url($self, $url) {
        $self->changelog->{project}{ticket_url} = $url;
    }

}

my $test = TestMe->new();

is $test->render_change( { desc => 'blah', ticket => 'GT123' } ),
<<'END', "no ticket_url";
  * blah [GT123]
END

$test->set_url( 's!GT!https://github.com/yanick/App-Changelord/issue/!' );

is $test->render_change( { desc => 'blah', ticket => 'GT123' } ),
<<'END', 'with a ticket_url';
  * blah [GT123]

  [GT123]: https://github.com/yanick/App-Changelord/issue/123
END

$test->set_url( '$_ = undef' );

is $test->render_change( { desc => 'blah', ticket => 'GT123' } ),
<<'END', 'with a ticket_url, but returns nothing';
  * blah [GT123]
END

subtest 'all links go at the bottom' => sub {
    $test->set_url( 's!^!link://!' );

    is $test->render_release({
        changes => [
            { desc => 'this', ticket => 1 },
            { desc => 'that', ticket => 2 },
            { desc => 'else' },
        ]
    }), <<'END';
## NEXT

  * this [1]
  * that [2]
  * else

  [1]: link://1
  [2]: link://2
END


};

done_testing;
