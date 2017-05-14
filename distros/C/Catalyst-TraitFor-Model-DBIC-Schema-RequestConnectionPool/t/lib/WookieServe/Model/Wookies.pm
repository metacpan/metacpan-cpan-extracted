package WookieServe::Model::Wookies;

use Moose;
use FindBin '$Bin';

extends 'Catalyst::Model::DBIC::Schema';
with 'Catalyst::TraitFor::Model::DBIC::Schema::RequestConnectionPool';

__PACKAGE__->config({
    schema_class    => 'WookieSchema',
    connect_info    => [ 'dbi:SQLite:default.db', '', '' ],
    });

sub build_connect_key {
    my ($self, $c) = @_;
    return $c->stash->{wanted};
    }

sub build_connect_info {
    my ($self, $c) = @_;
    my $db = "$Bin/lib/WookieServe/".$c->stash->{wanted};
    return "dbi:SQLite:$db.db", '', '';
    }

1;
