use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use List::MoreUtils qw/any all/;
use Module::Find;
setmoduledirs("$Bin/../lib", "$Bin/lib");

use Test::More tests => 3;
use Test::Exception;

my @modules = (
    'Catalyst::Plugin::RunAfterRequest',
    'Catalyst::Model::Role::RunAfterRequest',
);

use_ok $_ for (@modules);

ok ! any(sub { $_->can('new')}, @modules),
    'new methods in plugins which mix into an app class not cool';


