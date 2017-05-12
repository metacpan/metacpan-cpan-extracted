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

package App::rbinperl;
{
  $App::rbinperl::VERSION = '0.700';
}
BEGIN {
  $App::rbinperl::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Execute perl using relative lib and assuming -S

1;


__END__
=pod

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS rlibperl rbinperl apache CGI FCGI linux
login plack

=encoding utf-8

=head1 NAME

App::rbinperl - Execute perl using relative lib and assuming -S

=head1 VERSION

version 0.700

=head1 SYNOPSIS

Simplify cron jobs or other places where you specify commands
to execute which don't have your full environment.

Instead of:

  * * * * * perl -I/home/username/perl5/lib/perl5 \
                   /home/username/perl5/bin/somescript

Do:

  * * * * * /home/username/perl5/bin/rbinperl somescript

This is even more useful in a shebang line
which is often limited to a single argument...

This won't work on linux:

  #!/usr/local/bin/perl -I/home/username/perl5/lib/perl5 -S plackup

This will:

  #!/home/username/perl5/bin/rbinperl plackup

This example can be handy in a shared hosting environment
where you install the modules you want using L<local::lib>
and then want to use L<plackup> to run your app
from apache as a CGI or FCGI script.

=head1 DESCRIPTION

The C<rbinperl> script simplifies the execution of
a perl script that depends on modules located in 
relative library directories.

This uses the same logic as L<App::rlibperl>
to prepend relative lib directories to C<@INC> and
additionally passes the C<-S> argument to perl.
This causes perl to search the C<$PATH>
(which now contains the directory where C<rbinperl> was found)
for the specified script.

=head1 EXAMPLE USAGE WITH local::lib

If you have installed C<App::MadeUpScript> (and C<App::rbinperl>)
via L<local::lib> your directory tree will look something like this:

  ${root}/bin/rbinperl
  ${root}/bin/made-up-script
  ${root}/lib/perl5/${modules}
  ${root}/lib/perl5/${archname}/${extras}
  ${root}/man/${docs}

When you're using a login shell with L<local::lib> enabled
you can just call C<made-up-script> from the shell
because your environment variables are configured such that
C<${root}/bin> is in your C<$PATH> and
C<${root}/lib/perl5> is in C<$PERL5LIB>.

However to run from any sort of detached process
the environment variables from L<local::lib> won't be available,
and you'd have to do this instead:

  $ perl -I${root}/lib/perl5 -S made-up-script

C<rbinperl> simplifies this by adding the relative lib directories
automatically and passing C<-S>:

  $ ${root}/bin/rbinperl made-up-script

=head1 BLAH BLAH BLAH

Honestly the script itself is much simpler than explaining
how it can be useful (if it even is useful).

=head1 USE CASE

=head2 SHARED HOSTING

One of the reasons for creating this dist was to
make it as easy as possible to install a modern perl web framework
into a shared hosting environment.

You can build a web application and use L<Plack>
to run it as C<fastcgi> through Apache
(a common shared hosting option).

For example you could put this in C<dispatch.fcgi>:

  #!/usr/bin/env plack
  require 'mywebapp.pl';

and Apache would run your perl script through plack
which would detect an C<FCGI> environment and then load your web app.

If plack and your web framework are installed into a local lib
this won't work.  Instead you can do this:

  #!/home/username/perl5/bin/rbinperl plackup
  require 'mywebapp.pl';

It's almost as easy, and makes the rest
(loading your local lib) transparent.

=head1 BUGS AND LIMITATIONS

Unfortunately the shebang described above isn't entirely portable.

If you are on an operating system that doesn't allow
using another script (as opposed to a binary) in the shebang,
you may be able to use a work around like this instead:

  #!/bin/sh
  eval 'exec perl /home/username/perl5/bin/rbinperl plackup $0 ${1+"$@"}'
    if 0;
  require 'mywebapp.pl';

It's a slight variation of a common perl/shebang idiom.

See L<App::rlibperl/BUGS AND LIMITATIONS> for more.

=head1 SEE ALSO

=over 4

=item *

L<App::rlibperl>

=back

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

