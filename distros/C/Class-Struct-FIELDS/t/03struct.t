# Emacs, this is -*-perl-*- code.

BEGIN { use Test; plan tests => 22 }

require 5.005_64;
use strict;
use warnings;

use Test;

# Struct tests.

use Class::Struct::FIELDS;

# Tests 1-2:
$::ps = struct 'Fred';
ok ($::ps eq 'Fred');
package Fred; # get rid of compile-time warning
package main;
ok ($::po = Fred::->new);

# Tests 3-4:
$::ps = struct Barney => [qw(Fred)];
ok ($::ps eq 'Barney');
package Barney; # get rid of compile-time warning
package main;
ok ($::po = Barney::->new);

# Tests 5-6:
$::ps = struct Wilma => { aa => '$' };
ok ($::ps eq 'Wilma');
package Wilma; # get rid of compile-time warning
package main;
ok ($::po = Wilma::->new);

# Tests 7-8:
$::ps = struct Betty => [qw(Fred)], { aa => '$' };
ok ($::ps eq 'Betty');
package Betty; # get rid of compile-time warning
package main;
ok ($::po = Betty::->new);

# Tests 9-10:
$::ps = struct 'Pebbles', aa => '$';
ok ($::ps eq 'Pebbles');
package Pebbles; # get rid of compile-time warning
package main;
ok ($::po = Pebbles::->new);

# Tests 11-12:
$::ps = struct BammBamm => [qw(Fred)], aa => '$';
ok ($::ps eq 'BammBamm');
package BammBamm; # get rid of compile-time warning
package main;
ok ($::po = BammBamm::->new);

# Tests 13-14:
package Dino;
use Class::Struct::FIELDS;
$::ps = struct;
package main;
ok ($::ps eq 'Dino');
ok ($::po = Dino::->new);

# Tests 15-16:
package Hoppy;
use Class::Struct::FIELDS;
$::ps = struct [qw(Fred)];
package main;
ok ($::ps eq 'Hoppy');
ok ($::po = Hoppy::->new);

# Tests 17-18:
package BabyPuss;
use Class::Struct::FIELDS;
$::ps = struct { aa => '$' };
package main;
ok ($::ps eq 'BabyPuss');
ok ($::po = BabyPuss::->new);

# Tests 19-20:
package MrSlate;
use Class::Struct::FIELDS;
$::ps = struct [qw(Fred)], { aa => '$' };
package main;
ok ($::ps eq 'MrSlate');
ok ($::po = MrSlate::->new);

# Tests 21-22:
package MrsSlate;
use Class::Struct::FIELDS;
$::ps = struct [qw(Fred)], aa => '$';
package main;
ok ($::ps eq 'MrsSlate');
ok ($::po = MrsSlate::->new);
