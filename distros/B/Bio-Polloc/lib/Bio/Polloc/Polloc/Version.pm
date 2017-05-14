=head1 NAME

Bio::Polloc::Polloc::Version - Provides central package-wide version

=head1 AUTHOR - Luis M. Rodriguez-R

Email lrr at cpan dot org

=cut

package Bio::Polloc::Polloc::Version;

use strict;
our $VERSION = 1.0503;

sub import {
   no strict 'refs';
   my $c = -1;
   while(defined caller(++$c)){
      my $v = caller($c) . "::VERSION";
      ${$v} = $VERSION if $v =~ /^Bio::Polloc::/ and not defined ${$v};
   }
}

1;
