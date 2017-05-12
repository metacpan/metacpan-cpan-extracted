# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 14 }

require 5.005_64;
use strict;
use warnings;

use Test;

# Use tests.

use Class::Struct::FIELDS;

# Test 1:
use Class::Struct::FIELDS qw(Akron);
ok ($::po = Akron::->new);

# Test 2:
use Class::Struct::FIELDS Baltimore => [];
ok ($::po = Baltimore::->new);

# Test 3:
use Class::Struct::FIELDS Cleveland => {};
ok ($::po = Cleveland::->new);

# Tests 4:
use Class::Struct::FIELDS Dayton => [], {};
ok ($::po = Dayton::->new);

# Test 5:
package Anise;
use Class::Struct::FIELDS [qw(Akron)];
package main;
ok ($::po = Anise::->new);

# Test 6:
package Banana;
use Class::Struct::FIELDS { aa => '$' };
package main;
ok ($::po = Banana::->new);

# Test 7:
package Cranberry;
use Class::Struct::FIELDS [qw(Akron)], { aa => '$' };
package main;
ok ($::po = Cranberry::->new);

# Test 8:
package Dillweed;
use Class::Struct::FIELDS [qw(Akron)], aa => '$';
package main;
ok ($::po = Dillweed::->new);

# Test 9:
use Class::Struct::FIELDS qw(Eggplant);
ok ($::po = Eggplant::->new);

# Test 10:
use Class::Struct::FIELDS Fruit => [qw(Akron)];
ok ($::po = Fruit::->new);

# Test 11:
use Class::Struct::FIELDS Ginger => { aa => '$' };
ok ($::po = Ginger::->new);

# Test 12:
use Class::Struct::FIELDS Horseradish => [qw(Akron)], { aa => '$' };
ok ($::po = Horseradish::->new);

# Test 13:
use Class::Struct::FIELDS Ice => [qw(Akron)], aa => '$';
ok ($::po = Ice::->new);

# Test 14:
use Class::Struct::FIELDS qw(Jello), aa => '$';
ok ($::po = Jello::->new);
