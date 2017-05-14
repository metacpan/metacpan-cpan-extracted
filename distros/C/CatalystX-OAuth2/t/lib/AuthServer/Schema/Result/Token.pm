package AuthServer::Schema::Result::Token;
use base 'CatalystX::OAuth2::Schema::Result::Token';

__PACKAGE__->table('token');

# testing that subclassing works
__PACKAGE__->add_columns(foo => {is_nullable => 1});

1;
