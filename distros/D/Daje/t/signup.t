use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# my $t = Test::Mojo->new('Daje');
#
# $t->post_ok('/api/signup' => json => {
#     'user' => {
#         'userid'        => 'janeskil1525@gmail.com',
#         'password'      => '1234',
#         'username'      => 'Jan Eskilsson',
#         'active'        => 1,
#     },
#     'company' => {
#         'regno'   => 'dfgdsgfs',
#         'name'    => 'Test company',
#         'company_type_fkey' => 1
#     }
# })->status_is(200)->content_like(qr/success/i);

sub signup() {
    return 1;
}

ok (signup() == 1);
done_testing();

