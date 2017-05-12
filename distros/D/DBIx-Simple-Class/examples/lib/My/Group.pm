package    #hide
  My::Group;
use base qw(My);
use strict;
use warnings;
use utf8;
use base qw(My);

use constant TABLE   => 'groups';
use constant COLUMNS => [qw(id group_name foo-bar data)];
use constant WHERE   => {};

#See Params::Check
use constant CHECKS => {};

1;
