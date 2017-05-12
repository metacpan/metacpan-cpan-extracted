package DBIx::Class::Schema::Config::Plugin;

use strict;
use warnings;

use base 'DBIx::Class::Schema::Config';

__PACKAGE__->config_paths( [ ( 't/etc/config' ) ] );

sub filter_loaded_credentials {
    my ( $class, $new, $orig ) = @_;
    if ( $new->{dsn} =~ /\%s/ ) {
        $new->{dsn} = sprintf($new->{dsn}, $orig->{dbname});
    }
    return $new;
}

__PACKAGE__->load_classes;
1;
