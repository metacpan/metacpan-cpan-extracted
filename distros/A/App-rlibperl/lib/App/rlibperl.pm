# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of App-rlibperl
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package App::rlibperl;
{
  $App::rlibperl::VERSION = '0.700';
}
BEGIN {
  $App::rlibperl::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Execute perl prepending relative lib to @INC

1;


__END__
=pod

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS rlibperl rbinperl executables cpan
testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto
metadata placeholders

=encoding utf-8

=head1 NAME

App::rlibperl - Execute perl prepending relative lib to @INC

=head1 VERSION

version 0.700

=head1 SYNOPSIS

Install this into a L<local::lib> directory
to simplify including the C<local::lib> when calling perl:

  # cron job:
  * * * * * /project/dir/bin/rlibperl -MProject::App -e 'run()'

  # program configuration file:
  command = /home/username/perl5/bin/rlibperl -MSome::Mod -e 'do { something; }'

If you're lazy (like me) you can use it in the shebang line:

  #!/home/username/perl5/bin/rlibperl

Then you don't need to add an explicit

  use lib '/home/username/perl5/lib/perl5';

before any of your other code.

=head1 DESCRIPTION

The C<rlibperl> script simplifies the inclusion of
relative library directories with perl.

Upon execution the script will look for lib directories
relative to the location of the script
then re-invoke perl with all supplied command line arguments
and any found lib directories added to C<@INC>.

The script was designed to be installed via L<local::lib>
(though L<local::lib> is not required).
Once installed, executing the script is just like
executing perl except that it adds the local lib directories
to C<@INC> for you.

It also adds the directory of the script to C<$PATH>
like L<local::lib> does which enables C<system>/C<qx>/C<exec>/etc.
to find executables in that directory.

So this:

  $HOME/perl5/bin/rlibperl -MSome::Module -e 'do_something'

is roughly the equivalent of:

  PATH=$HOME/perl5/bin:$PATH perl \
     -I$HOME/perl5/lib/perl5 -MSome::Module -e 'do_something'

If that isn't useful enough (it probably isn't)
check out L<App::rbinperl> which automatically adds C<-S>
which makes it just as easy to execute another
script in that bin directory.

=head1 DIRECTORY STRUCTURES

C<rlibperl> will look for the following directory structures
relative to the directory in which it is located:

If the script is located in a directory named C<bin>
(or C<script> or C<scripts>)
it assumes a structure similar to L<local::lib>
and will first look for
C<../lib/perl5>:

  ${root}/bin/rlibperl
  ${root}/lib/perl5

If not found it will check for C<./lib>.

  ${root}/rlibperl
  ${root}/lib

(If C<rlibperl> is not located in a directory matching C</bin|scripts?/>
the order will be reversed: it will look for C<./lib> first.)

Lastly it will check for simply C<../lib>.

  ${root}/bin/rlibperl
  ${root}/lib

If you have another directory structure you think should be supported
please send suggestions!

=head1 BUGS AND LIMITATIONS

The initial use-case for C<rlibperl> was
installing via L<local::lib>
(or without it using something like C<cpanm --local-lib /other/dir>)
and calling like so:

  $ /path/to/local-lib/rlibperl -perl-args

(It may also be useful in a per-project setting,
though it's likely easier to make custom scripts
and/or use the unrelated L<rlib>.)

The following limitations exist when used in other situations,
however they are considered bugs and may be "fixed" at some point
(so their functionality should not be relied upon):

=over 4

=item *

Installing this into a perl's default lib will end up duplicating
directories in C<@INC> and probably reverse the order of your search path.

This is a problem, but then installing C<rlibperl> into a directory
that is already in your C<@INC> isn't all that useful.

=item *

Using these scripts in the shebang is arguably the most useful
way to use them (and in fact the reason they were created).

Unfortunately shebangs aren't always portable.

Some systems don't allow using another script
(as opposed to a binary) in the shebang line.
You can work around this
by adding a slight variation of the common C<eval 'exec'> idiom.
Just insert what would have been your shebang into the exec arguments:

  #!/bin/sh
  eval 'exec perl /home/username/perl5/bin/rlibperl -S $0 ${1+"$@"}'
    if 0;

=back

If you think other functionality would be useful
please submit examples, rationale, or B<patches>.

=head1 SEE ALSO

=over 4

=item *

L<App::rbinperl> - included

=item *

L<local::lib> - The module that makes this one useful

=item *

L<ylib> (C<perl -Mylib>) - Configurable additional lib directories

=item *

L<Devel::Local> - An alternative to the above modules

=item *

L<rlib> - This module is not related to or dependent on L<rlib>
but it serves a similar purpose in a different situation.

=item *

L<App::local::lib::helper> - A more configurable alternative to this dist
that loads L<local::lib> and its environment variables.

The C<localenv> script installed by L<App::local::lib::helper>
may be more powerful as a shell tool,
but C<rlibperl> serves a few niches that C<localenv> does not,
including enabling shebang args and taint mode.

Use the tool that works for you.

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::rlibperl

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-rlibperl>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-rlibperl>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-rlibperl>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-rlibperl>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-rlibperl>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::rlibperl>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-rlibperl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-rlibperl>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/App-rlibperl>

  git clone https://github.com/rwstauner/App-rlibperl.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

