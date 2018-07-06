use warnings;
use strict;
use Test::More;

use File::Find qw( find );

find {
  wanted => sub {
    return unless -f $_ and $_ =~ /.pm$/;

    my $path = $_; $path =~ s|^lib/||;
    require_ok($path);
    warn $@ if $@;
  },
  no_chdir => 1,
}, 'lib';
  
done_testing;
