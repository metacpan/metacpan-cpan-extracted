package App::Implode;

=head1 NAME

App::Implode - Pack an application into a single runable file

=head1 VERSION

0.03

=head1 DESCRIPTION

L<App::Implode> is an alternative to L<App::FatPacker> and L<App::fatten>. It
works by using L<Carton> to build all the dependencies and then bundle all the
deps to a single executable file.

It is very important that all the dependencies are documented in a
L<cpanfile|Module::CPANfile>. Example C<cpanfile>:

  requires "perl" => "5.12.0";
  requires "Mojolicious" => "5.00";

=head1 SYNOPSIS

=head2 Generetor

  $ cd my-project
  $ implode myapp.pl out.pl

=head2 Consumer

It is possible to set environment variables on the consumer side to instruct
how the code will be "exploded".

  $ out.pl
  $ APP_EXPLODE_VERBOSE=1 out.pl
  $ APP_EXPLODE_DIR=/extract/files/here out.pl

=over 4

=item * APP_EXPLODE_VERBOSE

Set this to a true value to get debug output.

=item * APP_EXPLODE_DIR

The default is to put the extracted files in a default
L<tmpdir|File::Spec/tmpdir>. A custom C<APP_EXPLODE_DIR> can be specified
if to override that behavior.

=back

=head1 CAVEAT

L<App::Implode> will put all the requirements into an bzip2'ed archive, and
write it into the generated file, in the C<__END__> section. This means that
you cannot use this section in the source script.

=cut

use strict;
use warnings;

our $VERSION = '0.03';

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
