use warnings;
use strict;
use Test::More;

use File::Find qw( find );

find {
  wanted => sub {
    return unless -f $_ and $_ =~ /.pm$/;
    require_ok($_ =~ s|^lib/||r);
    warn $@ if $@;
  },
  no_chdir => 1,
}, 'lib';
  
done_testing;
