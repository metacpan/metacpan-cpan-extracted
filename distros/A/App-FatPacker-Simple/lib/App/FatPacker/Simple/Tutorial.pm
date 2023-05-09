package App::FatPacker::Simple::Tutorial;
use v5.16;
use warnings;

1;
__END__

=for stopwords fatpack fatpacks fatpacked deps

=head1 NAME

App::FatPacker::Simple::Tutorial - tutorial!

=head1 SUMMARY

If you execute C<fatpack-simple script.pl>,
then you will get C<script.fatpack.pl>
that is the fatpacked C<script.pl> with all modules in
C<lib,fatlib,local,extlib> directories.
Also note that the all modules are automatically perl-stripped.

=head1 TUTORIAL

Let's say you have C<hello.pl> and want to fatpack it.
And assume

=over 4

=item * C<hello.pl> uses your modules in C<lib> directory: C<lib/Hello.pm>, C<lib/Hello/CLI.pm>

=item * external cpan module dependencies are declared in C<cpanfile>

=back

so that you have:

  $ find . -type f
  ./cpanfile
  ./hello.pl
  ./lib/Hello/CLI.pm
  ./lib/Hello.pm

  $ cat cpanfile
  requires 'Sub::Retry';
  requires 'HTTP::Tiny';

Well, C<fatpack-simple> just fatpacks a script with all modules in
C<lib,fatlib,local,extlib>,
so let's install dependencies to C<local> directory first:

  # if you have carton, then:
  $ carton install

  # or just:
  $ cpanm -Llocal -nq --installdeps .

  # Oh, HTTP::Tiny is not core module for old perls, so we have to fatpack it too!
  $ cpanm --reinstall -Llocal -nq HTTP::Tiny

  # Oh, Sub::Retry depends on 'parent' module, so we have to fatpack it too!
  $ cpanm --reinstall -Llocal -nq parent

Now the whole dependencies are in C<lib> and C<local> directories,
it's time to execute C<fatpack-simple>.
However if you use perl 5.20+,
then cpanm installed configure deps Module::Build, CPAN::Meta, right?
They are not necessary for runtime, so execute C<fatpack-simple> with
C<--exclude> option:

  $ fatpack-simple --exclude Module::Build,CPAN::Meta hello.pl
  -> perl strip Hello.pm
  -> perl strip Hello/CLI.pm
  -> perl strip parent.pm
  -> exclude CPAN/Meta.pm
  ...
  -> perl strip HTTP/Tiny.pm
  -> exclude Module/Build.pm
  ...
  -> perl strip Sub/Retry.pm
  -> Successfully created hello.fatpack.pl

Finally you get C<hello.fatpack.pl>!

=cut
