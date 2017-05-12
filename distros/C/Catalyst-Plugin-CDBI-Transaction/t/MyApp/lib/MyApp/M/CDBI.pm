package MyApp::M::CDBI;

use strict;
use base 'Catalyst::Model::CDBI';

my $dsn = MyApp->config->{dsn};
my $home = MyApp->config->{home};
$dsn =~ s{__HOME__}{$home/../..};
    
__PACKAGE__->config(
    dsn           => $dsn,
    user          => '',
    password      => '',
    options       => {},
    relationships => 0,
);

1;

