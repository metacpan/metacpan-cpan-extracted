use strict;
use warnings;

use Test::Pod tests => 1;

pod_file_ok('lib/Dancer2/Plugin/FormValidator/Extension/DBIC.pm', 'Not Valid POD file');
