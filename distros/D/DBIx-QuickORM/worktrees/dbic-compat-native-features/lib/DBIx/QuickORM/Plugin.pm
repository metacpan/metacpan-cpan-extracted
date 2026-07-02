package DBIx::QuickORM::Plugin;
use strict;
use warnings;

our $VERSION = '0.000027';

use Object::HashBase;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Plugin - Base class for DBIx::QuickORM plugins.

=head1 DESCRIPTION

Base class for plugins. Plugins are registered into the builder (via the
C<plugin>/C<plugins> exports) and are given a chance to mutate each build
frame as it is compiled. A plugin registered at one nesting level applies
to every build nested inside it.

This base class adds no behavior of its own; subclasses provide a C<munge>
method (called with the build frame) to do their work.

=head1 SYNOPSIS

    package My::Plugin;
    use parent 'DBIx::QuickORM::Plugin';

    sub munge {
        my $self  = shift;
        my ($frame) = @_;
        # ... adjust $frame ...
    }

=cut

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
