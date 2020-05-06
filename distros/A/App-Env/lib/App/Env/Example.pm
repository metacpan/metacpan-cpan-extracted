package App::Env::Example;

# ABSTRACT: example application environment module for App::Env.

use strict;
use warnings;

our $VERSION = '0.35';

# This example uses Shell::GetEnv to illustrate how to source a shell
# script which defines the environment for an application.  Other
# similar modules are Shell::Source and Shell::EnvImporter.

use Shell::GetEnv;


sub envs
{
    #     my ( $opt ) = @_;

    # source the shell script and return the changed environment
    return Shell::GetEnv->new( 'tcsh',
                               'source /usr/local/mypkg/setup.csh'
                             )->envs;
}

1;

#
# This file is part of App-Env
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

App::Env::Example - example application environment module for App::Env.

=head1 VERSION

version 0.35

=head1 DESCRIPTION

Modules used by B<App::Env> to load application environments are named

  App::Env::<application>

or, if there is a site specific version:

  App::Env::<SITE>::<application>

It is very important that the loaded environment be based upon the
I<current> environment.  For example, if the environment is derived
from running a shell script, make sure either that the shell script is
run without running the user's startup file, or that any differences
between the current environment and that constructed by the script
which are not due to the application are resolved in the current
environment's favor.  For example, say that B<LD_LIBRARY_PATH> is set
in the user's F<.cshrc> file:

  setenv LD_LIBRARY_PATH /my/path1

and that before invoking B<App::Env> the user has modified it to

  /my/path1:/my/path2

If a B<csh> script is sourced to create the environment, and B<csh> is
not run with the B<-f> flag, the user's F<.cshrc> will be sourced, the
user's modifications to B<LD_LIBRARY_PATH> will be lost, and breakage
may happen.

With that said, it may be necessary in some cases to provide an
environment which is independent of the current one.  If a module is
capable of doing so, it should do so when presented with the
B<Pristine> B<AppOpts> option.  If it is not capable of doing so the
presence of that option should be treated as an error.  Pristine
environments will by definition cause problems in merged environments.

=head2 Application Aliases

If application environments should be available under alternate names
(primarily for use B<appexec>), a module should be created for each alias
with the single class method B<alias> which should return the name of
the original application.  For example, to make C<App3> be an alias
for C<App1> create the following F<App3.pm> module:

  package App::Env::App3;
  sub alias { return 'App1' };
  1;

The aliased environment can provide presets for B<AppOpts> by returning
a hash as well as the application name:

  package App::Env::ciao34;
  sub alias { return 'CIAO', { Version => 3.4 } };
  1;

These will be merged with any C<AppOpts> passed in via B<import()>, with
the latter taking precedence.

=head1 Functions

They should define the following functions:

=over

=item envs

  $hashref = envs( \%opts );

C<$hashref> is a hash containing environmental variables and their
values. C<%opts> will contain the options passed to
B<App::Env::import> via the B<AppOpts> option.

=back

See the source of this module for a simple example.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-app-env@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=App-Env

=head2 Source

Source is available at

  https://gitlab.com/djerius/App-Env

and may be cloned from

  https://gitlab.com/djerius/App-Env.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<App::Env|App::Env>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
