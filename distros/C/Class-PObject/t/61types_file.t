

# 61types_file.t,v 1.4 2005/02/20 18:05:00 sherzodr Exp

use strict;
use File::Spec;
use Class::PObject::Test::Types;

my $t = new Class::PObject::Test::Types('file', File::Spec->catfile('data', 'types', 'file'));
$t->run();

