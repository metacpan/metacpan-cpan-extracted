use v5.36;

package DBIx::Squirrel::Pipes;

use Ekorn::Pipeline::Pipes qw();

# A facade over Ekorn::Pipeline::Pipes, inheriting its methods.
our @ISA = ('Ekorn::Pipeline::Pipes');

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Pipes - the pipe and tap methods of DBIx::Squirrel's handles

=head1 SYNOPSIS

    package My::Handle;

    our @ISA = ('Some::Parent', 'DBIx::Squirrel::Pipes');

=head1 DESCRIPTION

A parent class giving its children L<DBIx::Squirrel/pipe> and
L<DBIx::Squirrel/tap>. DBIx::Squirrel's database and statement handle
classes, L<DBIx::Squirrel::db> and L<DBIx::Squirrel::st>, inherit from
it as well as from the DBI's own.

It's a subclass of L<Ekorn::Pipeline::Pipes>, and inherits its
methods. C<pipe> runs the handle through a pipeline of stages, and
returns what comes out. C<tap> runs it through them for their side
effects, and returns the handle.

=head1 SEE ALSO

L<Ekorn::Pipeline::Pipes>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
