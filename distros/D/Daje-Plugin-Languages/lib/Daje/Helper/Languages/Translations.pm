package Daje::Helper::Languages::Translations;
use Mojo::Base -base, -signatures, -async_await;
use v5.42;

use Data::Dumper;

has 'db';


async sub load_translations_p($self, $users_pkey) {
    my $stmt = qq{
        SELECT * from v_languages_with_keys_list
            WHERE languages_lan_pkey = (SELECT languages_lan_fkey FROM users_users WHERE users_users_pkey = ?)
    };
    my $result = $self->db->query($stmt, ($users_pkey));

    my $hashes;
    $hashes = $result->hashes if $result and $result->rows > 0;

    return $hashes;
}
1;