

# 70hasa_file.t,v 1.4 2005/02/20 18:05:00 sherzodr Exp

use strict;
use File::Spec;
use Class::PObject::Test::HAS_A;

my $t = new Class::PObject::Test::HAS_A('file', File::Spec->catfile('data', 'has_a', 'file'));
$t->run();



