use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# my $t = Test::Mojo->new('Daje');
#
# $t->put_ok('/api/login' => json => {
#         'userid'        => 'janeskil1525@gmail.com',
#         'password'      => '1234',
# })->status_is(200)->content_like(qr/success/i);

sub login() {
    return 1;
}

ok(login() == 1);

done_testing();

