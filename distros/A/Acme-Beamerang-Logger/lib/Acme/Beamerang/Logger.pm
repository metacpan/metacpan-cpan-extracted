use 5.006;    # our
use strict;
use warnings;

package Acme::Beamerang::Logger;

our $VERSION = '0.001000';

use parent 'Log::Contextual';

sub default_import { qw(:dlog :log ) }

# This ideally would be regulated by the importing class
# but I got tired of trying to guess what horrible magic
# was necessary to make Exporter::Declare and whatever
# the hell Log::Contextual's import logic does work.
sub _get_prefixes {
    my $class = $_[0];
    my (@parts) = split /::/sx, $class;

    # Always assume there is no Acme
    # Acme::X is X in the future.
    shift @parts if $parts[0] eq 'Acme';

    my (@prefixes);

    # Always include FQ name, sans Acme
    push @prefixes, uc( join q/_/, @parts );
    pop @parts;

    # If its a Beamerang subclass, split the namespace
    # and create env vars for each level.
    if ( 2 <= @parts and ( 'Beamerang' eq shift @parts ) ) {
        while (@parts) {
            push @prefixes, uc( join q/_/, 'BEAMERANG', @parts );
            pop @parts;
        }
    }
    return @prefixes, 'BEAMERANG';
}

sub arg_default_logger {
    return $_[1] if $_[1];
    require Log::Contextual::WarnLogger::Fancy;
    my $caller = caller(3);

    my ( $env, @group ) = _get_prefixes($caller);
    return Log::Contextual::WarnLogger::Fancy->new(
        {
            env_prefix       => $env,
            group_env_prefix => \@group,
            label            => $caller,
            label_length     => 21,
            default_upto     => 'warn',
        }
    );
}

1;

=head1 NAME

Acme::Beamerang::Logger - A Simple per-class clan warnlogger loader

=head1 SYNOPSIS

  # Interface is basically the same as Log::Contextual::Easy::Default
  use Acme::Beamerang::Logger; # imports :dlog and :log by default
                               # also assigns a default logger to the package.

=head1 DESCRIPTION

This class is a convenience layer to tie L<Log::Contextual::WarnLogger::Fancy>
into the C<Acme::Beamerang> project space.

This is very experiemental and is a research project ( hence C<Acme::> ).

This would otherwise be part of the other C<Acme::Beamerang> things that are still yet to
materialise, but the inversion control this project entails means directly coupling
this component with either of those parts would lead to a dependency graph that would
defeat the point of the control inversion.

This tool otherwise loads up C<Log::Contextual> with a nice default logger, with all the glue
in place to be convenient for this project, while still having an open door to a real logger.

=head1 ENVIRONMENT

This module utilizes the C<env_prefix> and C<group_env_prefix> of L<Log::Contextual::WarnLogger::Fancy>
to generate a collection of C<ENV> vars for narrow or broad incision of logging statements without need
to use more complex logging technology.

Every package that uses this logger will respond to C<BEAMERANG_$LOG_LEVEL> and C<BEAMERANG_UPTO> values.

Every package beginning with either C<Acme::Beamerang::> or C<Beamerang::> will additionally respond to
a collection of namespace oriented C<ENV> variables.

For instance,

  Acme::Beamerang::Foo::Bar::Baz

Will respond to any of the following C<ENV> vars:

  BEAMERANG_FOO_BAR_BAZ_$LEVEL
  BEAMERANG_FOO_BAR_$LEVEL
  BEAMERANG_FOO_$LEVEL
  BEAMERANG_$LEVEL
  BEAMERNAG_FOO_BAR_BAZ_UPTO
  BEAMERANG_FOO_BAR_UPTO
  BEAMERANG_FOO_UPTO
  BEAMERANG_UPTO

This means you can turn on debugging for as much, or as little as you like, without
having to radically change the code.

=head1 NAMING

=head2 Acme

Firstly, this is named C<Acme::>, because its a bunch of bad ideas glued together, and I
don't want people to use this until its "ready", but I'm going to need to use it lots before I get comfortable
anything right is done.

When its ready (if ever), it will ship as C<Beamerang::> ... maybe.

=head2 Beamerang

This is my dumb joke based on C<Beam>, which this compontent is going to end up being used in conjunction with.

I thought at first C<Beam> -> C<Boom>, but then that was too high level.

And then I thought C<Boomerang>  .... but eh, I didn't like that either.

So C<Beamerang> is a mutant hybrid of the above.

Other parts of this system that have yet to manifest will use the same convention.

=head1 SEE ALSO

=over 4

=item * L<< C<Log::Contextual::Easy::Default>|Log::Contextual::Easy::Default >> - Interface is otherwise identical to this
module, only the default logger in choice and its configuration differs.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 LICENSE

This software is copyright (c) 2016 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
