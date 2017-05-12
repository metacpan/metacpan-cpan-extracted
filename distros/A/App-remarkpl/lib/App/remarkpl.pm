package App::remarkpl;

=head1 NAME

App::remarkpl - Web based presentation tool

=head1 VERSION

0.05

=head1 DESCRIPTION

L<App::remarkpl> is is a L<Mojolicious> based webserver for showing
L<remark|http://remarkjs.com> powered presentations locally.

Have a look at L<https://github.com/gnab/remark/wiki> for more information
about how to write slides.

=head1 SYNOPSIS

  # Start a slideshow server
  $ remarkpl slides.markdown

  # Start the server on a different listen address
  $ remarkpl slides.markdown --listen http://*:5000

  # Show an example presentation
  $ remarkpl example.markdown
  $ remarkpl example.markdown --print

After starting the server, you can open your favorite (modern) browser
at L<http://localhost:3000>.

=cut

use Mojo::Base -base;

our $VERSION = '0.05';

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
