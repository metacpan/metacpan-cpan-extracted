use Test2::V0;

use Dancer2::Plugin::JsonApi::Registry;

use experimental qw/ signatures /;

my $registry = Dancer2::Plugin::JsonApi::Registry->new;

$registry->add_type(
    people => {
        id    => 'id',
        links => {
            self => sub ( $data, @ ) {
                no warnings qw/ uninitialized /;
                return "/peoples/$data->{id}";
            }
        }
    }
);

isa_ok $registry->type('people') => 'Dancer2::Plugin::JsonApi::Schema';

like(
    $registry->serialize( people => {} ),
    { jsonapi => { version => '1.0' } }
);

done_testing();
