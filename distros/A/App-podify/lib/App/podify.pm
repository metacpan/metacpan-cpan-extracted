package App::podify;
use strict;
use warnings;

our $VERSION = '0.03';

1;

=encoding utf8

=head1 NAME

App::podify - Add POD to your modules

=head1 VERSION

0.03

=head1 SYNOPSIS

  # Print processed module to STDOUT
  $ podify lib/My/Module.pm

  # Replace module
  $ podify -i lib/My/Module.pm

  # Process all files in the lib/ directory
  $ podify -i lib/

  # Process all files in the lib/ directory recursively
  $ podify -r -i lib/

=head1 DESCRIPTION

L<App::podify> is an application which can help you document your
module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
