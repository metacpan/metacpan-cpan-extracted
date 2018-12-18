#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

#use Test::More;
use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use utf8;
use Colon::Config;

{
    note "utf8";
    my $input = <<'EOS';
hèllö:wørld
plain:text
õther:value
key:chårs
mõther:chårs
EOS
    is Colon::Config::read_as_hash($input), {
        qw/
          hèllö wørld
          plain text
          õther value
          key chårs
          mõther chårs
          /
      },
      'mix of utf8 and non utf8 chars';

}

done_testing;

__END__
