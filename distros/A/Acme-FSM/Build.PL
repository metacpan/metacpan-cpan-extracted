# Copyright (C) 2008 DMA.
# $Id: Build.PL 561 2022-12-29 18:54:15Z whynot $
# Copyright 2012, 2022 Eric Pozharski <whynot@pozharski.name>
# GNU GPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

use strict;
use warnings;
use 5.010;

use version 0.77; our $VERSION = version->declare( v2.3.1 );

use Module::Build;

=head1 OVERVIEW

B<Acme::FSM> implements something resembling Finite State Machine.
If you're looking for rigor then look somewhere else.
If you're looking for feature set then keep looking.

What B<A::F> does is mechanics with zero awarness of inputs and/or outputs
(any or both might be missing).
Implementation is definetely crude.
That stems from historical burden -- it's a fork!

If you're not demotivated yet then L<B<Acme::FSM>> has more.

Test-suite scores 1083 units.

=cut

my $engine = Module::Build->new(
  dist_name         =>                            q|Acme-FSM|,
  dist_version_from =>                          q|lib/FSM.pm|,
  dist_abstract     =>         q|Pseudo Finite State Machine|,
  dist_author    => q|Eric Pozharski <whynot@pozharski.name>|,
  license           =>                         q|open_source|,
  meta_merge        => { resources =>
  { license => q|http://www.gnu.org/licenses/lgpl-3.0.txt| }},
  sign              =>                                      1,
  requires          =>
  { q|perl|  => qv( q|5.10.0| ),
    q|version| => qv( q|0.77| )                             },
  build_requires    =>
  { q|Module::Build| => '',
    q|Test::More|    => ''                                  },
  pm_files         => { q|lib/FSM.pm| => q|lib/Acme/FSM.pm| },
  pod_files         => {                                    },
  add_to_cleanup    => [qw| *.tmp *.bak foo.* skip_*       |] );

$engine->recursive_test_files( 1 );

$engine->create_build_script();

=head1 INSTALL

    perl Build.PL
    ./Build build
    ./Build test
    ./Build install

B<A::F> doesn't need anything (even core modules).
However,

=over

=item B<perl>

I<v5.10>, but that's not verified yet.

=item B<version>

I<v0.77>.
That's definetely contradicts B<perl>.
I haven't dug through F<Changes> yet,
can't say when The Core has switched to I<v0.77> though.

=item C<Carp>

Whatever comes with B<perl>, hopefully.

=item B<Module::Build>

Whatever comes with B<perl>.
Cut off version to be determined yet.

=back

=cut

=head1 AVAILABILITY

# TODO:202207292136:whynot: Fill me in.

=cut

=head1 BUGS

# TODO:202207292141:whynot: Fill me in.

=cut

=head1 COPYRIGHT AND LICENSING

    Copyright 2012, 2013, 2022 Eric Pozharski <whynto@pozharski.name>

    GNU LGPLv3

    AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL

=cut
