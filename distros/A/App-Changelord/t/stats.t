use Test2::V0;

use v5.36.0;

package TestMe {
    use Moo;

    has changelog => (
        is => 'ro',
        default => sub {{
             project => { ticket_url => undef },
             releases => [
                 {  },
             ]
        }}
    );

    with  'App::Changelord::Role::Stats';
    with 'App::Changelord::Role::ChangeTypes';

}

my $test = TestMe->new;

like $test->stats => qr/code churn: /;

done_testing;
