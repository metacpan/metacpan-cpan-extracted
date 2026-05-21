package CLI::Simple::Shell;

use strict;
use warnings;

1;

__END__

=pod

=head1 NAME

cli-simple - Scaffold a new project from a .yml file

=head1 SYNOPSIS

 cat >my-project.yml <<EOF
---
commands:
  foo: MyProject::Role::Foo
  bar: MyProject::Role::Bar

options:
  - help|h
  - verbose|v
  - type|t=s
  - output|o=s

default_options:
  type:   json

extra_options:
  - buz
EOF

  cli-simple -scaffold my-project.yml

Commands:

 -scaffold <spec-file>   Scaffold role stubs from an existing modulino

=head1 DESCRIPTION

The C<cli-simple> script's sole use is to scaffold a new project from
a .yml file. You can also run the same command from any C<CLI::Simple>
based modulino script.

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See
L<https://dev.perl.org/licenses/> for more information.

=head1 SEE ALSO

L<CLI::Simple>

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
