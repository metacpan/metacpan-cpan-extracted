package App::MyPerl;

use Moo;
use IO::All;

our $VERSION = '0.003000';

with 'App::MyPerl::Role::Script';

sub run {
  my @perl_options = @{$_[0]->perl_options};
  print "@perl_options . \n" if $_[0]->_env_value('DEBUG');
  exec($^X, @perl_options, @ARGV);
}

1;

=head1 NAME

App::MyPerl - Your very own set of perl defaults, on a global or per
project basis

=head1 SYNOPSIS

  # .myperl/modules
  v5.14
  strictures
  autodie=:all

  $ myperl bin/some-script

Runs some-script with the following already loaded

  use v5.14;
  use strictures;
  use autodie qw(:all);

and through the magic of L<lib::with::preamble>, C<lib/> and C<t/lib/>
are already in C<@INC> but files loaded from there will behave as if they
had those lines in them, too.

It is possible to add global defaults, to all scripts and all C<myperl>
projects with C<~/.myperl/defaults/modules> and C<~/.myperl/always/modules>

=head1 DESCRIPTION

A C<.pm or .pl> file usually requires some preamble to get some defaults right.

  # important ones
  use strict;
  use warnings;

  # good
  use autodie qw(:all);

  # better exceptions
  use Try::Tiny;
  use Carp;

On top of that you might find L<Scalar::Util>, L<List::Util> useful all over
your code.

C<myperl> allows you define this boilerplate once and for all, while
B<maintaining compatiability> with existing code.

=head1 TUTORIAL

If there is no C<export MYPERL_HOME="~/.perl_defaults">, C<~/.myperl> is by
default read for global defaults.

  # ~/.myperl/always/modules
  strictures
  autodie=:all

  # ~/.myperl/defaults/modules
  v5.14

  # ~/some_scripts/script.pl
  say "Hello World"

The syntax for the modules file is,

=over

=item *

C<comment> -- # comment

=item *

C<empty space>

=item *

C<Foo=bar,qux,baz> -- This translates to C<use Foo qw(bar, qux, baz)>

=item *

C<-Foo=bar,qux,baz> -- This translates to C<no Foo qw(bar, qux, baz)>

=back

Now,

  $ myperl ~/some_scripts/script.pl

will print C<Hello World>.

Let's say you are working on a typical Perl module like,

  .myperl/
  lib/
  t/
  bin/
  README
  LICENSE
  Makefile.PL
  ...

Now,

  $ cd $project_dir; myperl bin/app.pl

will configure perl in such a way that C<lib/**> and C<t/lib/**>, will all
have the preamble defined in C<.myperl/modules> and
C<~/.myperl/always/modules> thanks to the import hooks in
L<lib::with::preamble>.

If you don't have a C<.myperl/modules>, myperl will use
C<~/.myperl/defaults/modules> in place of it.

You can configure the directory C<$project_dir/.myperl> with
C<export MYPERL_CONFIG>.

Running tests,

  $ myprove t/foo.t

And in your C<Makefile.PL> -

  sub MY::postamble {
    q{distdir: myperl_rewrite
  myperl_rewrite: create_distdir
  	myperl-rewrite $(DISTVNAME)
  };
  }

(warning: this is make - so the indent for the C<myperl-rewrite> line needs
to be a hard tab)

to have the defaults added to the top of C<.pm, .t and bin/*> files in your
dist when it's built for CPAN.

Sometimes though, you want a module to be used during development,
B<but not written into the final dist>. A good case
for this is C<indirect>.

For this, add C<-indirect> in C<$project_dir/.myperl/dev-modules>.

To specify modules loaded only into the top level script, prepend C<script->
to the file name - so C<$project_dir/.myperl/script-modules> specifies
modules only used for the top level script, and C<script-dev-modules>
the same but not rewritten onto scripts when myperl-rewrite is invoked.

And lastly, you can add C<if::minus_e=Some::Module> in
C<$MYPERL_HOME/defaults/script-dev-modules> for having
C<Some::Module> conveniently preloaded for <myperl -e '...'> oneliners
- see L<if::minus_e> for how this behaves in detail.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

mucker - (cpan:MUCKER) <mukcer@gmx.com>

=head1 COPYRIGHT

Copyright (c) 2013 the App::MyPerl L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
