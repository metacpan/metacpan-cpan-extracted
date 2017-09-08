#!/usr/bin/env perl
use warnings;
use strict;
use List::MoreUtils qw/uniq/;

use lib ('/home/jwb/perl5/lib/perl5','/home/jwb/perl5/lib/perl5/x86_64-linux-thread-multi');
my @path = grep { $_ } uniq(split(/:/, $ENV{PATH}), '/home/jwb/perl5/bin','/home/jwb/bin','/usr/bin','/bin','/usr/sbin','/sbin','/usr/local/bin','/home/jwb/.molecules','/home/jwb/.gem/ruby/2.0.0/bin','/usr/local/sbin','/opt/android-sdk/platform-tools','/opt/android-sdk/tools','/opt/cuda/bin','/usr/lib/jvm/default/bin','/usr/bin/site_perl','/usr/bin/vendor_perl','/usr/bin/core_perl','/home/jwb/.fzf/bin');
$ENV{PATH} = join(":", @path);
my $cmd = shift;
unless ( my $return = do $cmd ) {
  warn "could not parse $cmd\n$@\n\n$!" if $@;
  warn "couldn't execute $cmd\n$!" unless defined $return;
  warn "couldn't run $cmd" unless $return;
}
exit;
