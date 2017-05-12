package Acme::No;

use 5.00503;

use Carp qw(croak);
use UNIVERSAL ();

use strict;

use Filter::Util::Call;

$Acme::No::VERSION = '0.03';

sub import {

  filter_add(sub {

    my $status = 0; 

    if (($status = filter_read) > 0) {

      my (undef, $no, $module, $version) = m/(^|;)\s*(no)\s+([\w\-:]*)\s*(\d+[.]?(\d+[._]?)*)/;

      if ($no && $module && $version) {
        # no mod_perl 2.0;
                        
        if ($module eq 'v') {
          # fall through to Perl part if we caught 'no v5.6.0'
        }
        else {

          eval "require $module" or die $@;

          my $modversion = UNIVERSAL::VERSION($module);

          croak "$module version $modversion too high--version less than $version required"
            unless $modversion < $version;

          undef $no;  # we're done
        }
      }

      if ($no && $version) {
        # no 6.0;

        # perl version foo (ugh)
        my ($rev, $ver, $subver) = split '[._]', $version;

        if ($ver > 1000) {              # 5.006001
          $subver = ($ver % 1000);
          $ver = int($ver / 1000);
        }
        elsif ($ver > 100) {            # 5.00503
          $subver = ($ver % 100) * 10;
          $ver = int($ver / 100);
        }
        else {                          # silence undef warnings
          $subver ||= 0;
        }

        $version = $rev + ($ver/1000) + ($subver/1000000);

        croak "Perl v$] too high--version less than v$version required"
          unless $] < $version;
      }

      # wipe away user code so the real perl doesn't
      # barf on our implementation
      s/(no)\s+([\w\-:]*)\s*(\d+[.]?(\d+[._]?)*)//;
    }

    return $status;
  });
}

1;

__END__

=head1 NAME 

Acme::No - makes no() work the way I want it to

=head1 SYNOPSIS

 use 5.6;            # I use our(), so 5.6 is required
 no  6.0;            # but this was coded for perl 5, not perl 6
                     # and the perl 6 compat layer isn't really 5.6
                     # so my code breaks under 6.0

 use mod_perl 1.27;  # we need at least version 1.27
 no mod_perl 2.0;    # but mod_perl 2.0 is entirely different than 1.0
                     # so keep my cpan email to a minimum
                  

=head1 DESCRIPTION

ok, first the appropriate pod:

$ perldoc C<-f> no 
  =item no Module VERSION LIST

  =item no Module VERSION

  =item no Module LIST

  =item no Module

  See the L</use> function, which C<no> is the opposite of.


now, one might think that, since 

 use mod_perl 1.27;

makes sure that mod_perl is at least version 1.27,

 no mod_perl 1.27;

should mean that 1.27 is too high - the manpage says use() and
no() are opposites, and that looks like opposite behavior to 
me.  however...

 $ perl -e 'use mod_perl 2.0'
 mod_perl version 2 required--this is only version 1.2701 at -e line 1.
 BEGIN failed--compilation aborted at -e line 1.

 $ perl -e 'no mod_perl 2.0'
 mod_perl version 2 required--this is only version 1.2701 at -e line 1.
 BEGIN failed--compilation aborted at -e line 1.

so, no() and use() do the exact same thing here - hmmm... looks like a 
bug in perl core...

enter Acme::No

Acme::No makes no() work the way I want it to.

  $ perl -MAcme::No -e'no v5.9.0; print "ok\n"'
  Perl v5.009 too high--version less than v5.009 required at -e line 0

  $ perl -MAcme::No -e'no v5.9.1; print "ok\n"'
  ok

  $ perl -MAcme::No -e'no mod_perl 1.27; print "ok\n"'
  mod_perl version 1.2701 too high--version less than 1.27 required at -e line 0

  $ perl -MAcme::No -e'no mod_perl 2.0; print "ok\n"'
  ok

=head1 FEATURES/BUGS

probably lots

=head1 SEE ALSO

Filter::Util::Call, perldoc C<-f> use, perldoc C<-f> no,
http://www.mail-archive.com/perl5-porters@perl.org/msg53742.html,
http://www.mail-archive.com/perl5-porters@perl.org/msg53752.html,

=head1 AUTHOR

Geoffrey Young <geoff@modperlcookbook.org>

=head1 COPYRIGHT

Copyright (c) 2002, Geoffrey Young
All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
