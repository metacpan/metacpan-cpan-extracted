package CatalystX::Crudite::Test;
use strict;
use warnings;
use DBICx::TestDatabase;
use Test::WWW::Mechanize::Catalyst ();
our ($app_name, $schema_name);

sub get_schema {
    our $schema //= DBICx::TestDatabase->new($schema_name);
}

sub import {
    my $self = shift;
    $app_name = shift;
    Test::WWW::Mechanize::Catalyst->import($app_name);
    $schema_name = "${app_name}::Schema";
    $app_name->model('DB')->schema(get_schema());
}
1;
__END__

Setup everything for mechanize tests and create a temporary in-memory DB for
every separate test file so you can run tests in parallel without worrying
about interference.

See
http://modernperlbooks.com/mt/2012/08/testing-catalyst-and-dbic-with-an-in-memory-database.html
