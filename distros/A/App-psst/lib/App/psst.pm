use strict;
use warnings;

package App::psst;
{
  $App::psst::VERSION = '0.09';
}


=head1 NAME

App::psst - prompt string setting tool


=head1 VERSION

version 0.09

=head1 DESCRIPTION

Set-once configuration for F<~/.bashrc> to show presence of
C<$PERL_LOCAL_LIB_ROOT>.

=head2 Origin

I wrote a L<local::lib>-based installer for a small project.

I added the obligatory "set up the environment and start a shell in
there" script.

I wanted the new subshell to be clearly marked as having local::lib
environment, and decided that this functionality doesn't belong in the
small project.

=head2 Intentions

Polish it a little to make a small CPAN-installable package.  Install
in all my $HOMEs.


=head1 AUTHOR

Copyright (C) 2011 Genome Research Limited

Author Matthew Astley L<mca@sanger.ac.uk>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head2 Thanks

Thanks to Magnus Manske for some useful discussion of the mechanism,

and this post for convincing me that this is a useful route to sanity
http://blogs.perl.org/users/oliver_gorwits/2011/07/locallibs-for-dist-development.html

and to my employer for making it easy to mix free software with $work.


=head1 SEE ALSO

L<psst(1)>

=head2 Related tools

These are tools I have found links to.  I have not yet chosen some to
assemble a better working environment.

=over 4

=item *

L<Git::CPAN::Hook> or L<CPANPLUS::Dist::GitHook>

=item *

L<App::local::lib::helper> (L<App::local::lib::helper::rationale>)

C<localenv bash> starts a new shell, which psst can configure.

=item *

L<App::PerlLocalEnv>, L<perl-local-env(1)>

C<perl-local-lib $DIR activate> starts a new shell, which psst can
configure.

=item *

L<App::local::lib::Win32Helper>

This psst has not (yet) been tested with bash under Windows.

=item *

L<App::perlbrew>

This version of psst knows nothing about perlbrew.

=back

=cut

1;
