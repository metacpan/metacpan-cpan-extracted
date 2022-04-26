package App::remarkpl;
use Mojo::Base -strict;

our $VERSION = '0.06';

1;

__END__

=head1 NAME

App::remarkpl - Web based presentation tool

=head1 VERSION

0.06

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

=head1 ENVIRONMENT VARIABLES

=over 2

=item * REMARK_JS

Can be set to an external URL such as
L<https://remarkjs.com/downloads/remark-latest.min.js> to use a different
version than the bundled remarkjs version.

=item * REMARK_STATIC

Path to static files to include. Default value is the current working
directory.

=item * REMARK_TEMPLATES

Path to custom Mojolicious templates. Default to C<./templates> in the current
working directory.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
