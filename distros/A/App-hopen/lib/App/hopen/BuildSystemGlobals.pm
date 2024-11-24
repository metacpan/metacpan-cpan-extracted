# App::hopen::BuildSystemGlobals - global data for build-system use cases.
package App::hopen::BuildSystemGlobals;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'Exporter';
our @EXPORT;
BEGIN { @EXPORT = qw(*Generator *Toolset *Build *Phase *ProjDir *DestDir); }
        # export with `*` => `local` will work.

=head1 NAME

App::hopen::BuildSystemGlobals - global data for hopen build-system use cases

=head1 SYNOPSIS

This module exports variables used when employing hopen(1) as a build system.
They are in a separate module so that it's easy to tell in which parts of
L<App::hopen> I<don't> need them.

=head1 VARIABLES

=head2 $Generator

The current L<App::hopen::Gen> instance.

=head2 $Toolset

The name of the current toolset.  Support for language C<Foo> is in
package C<${Toolset}::Foo>.

=head2 $Build

The L<Data::Hopen::G::DAG> instance representing the current build.
Goals in C<$Build> will become, e.g., top-level targets of a
generated C<Makefile>.

=head2 $Phase

Which phase we're in (string).

=head2 $ProjDir

A L<Path::Class::Dir> instance representing the project directory.

=head2 $DestDir

A L<Path::Class::Dir> instance representing the destination directory.

=cut

our ($Generator, $Toolset, $Build, $Phase, $ProjDir, $DestDir);

1;
__END__
# vi: set fdm=marker: #
