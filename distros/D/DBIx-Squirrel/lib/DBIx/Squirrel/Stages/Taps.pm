use v5.36;

package DBIx::Squirrel::Stages::Taps;

use Exporter qw(import);

use Ekorn::Pipeline::Stages::Taps qw(peek count_into dump_to);

# A facade over Ekorn::Pipeline::Stages::Taps, exporting DBIx::Squirrel's
# own list of its functions, imported from it by name, so a name
# Ekorn::Pipeline drops fails here, as the module loads, and one it
# adds isn't exported until it's listed here.
our @EXPORT      = qw(peek count_into);      ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = (@EXPORT, qw(dump_to));
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Taps - stages run for their side effects: peek, count_into and dump_to

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Taps;

=head1 DESCRIPTION

DBIx::Squirrel's name for L<Ekorn::Pipeline::Stages::Taps>, which
describes its stages in full. It exports C<peek> and C<count_into> by
default, and C<dump_to> on request, or all three with C<:all>: Ekorn's
functions, from a list of DBIx::Squirrel's own, so a stage added there
reaches this module only once it's listed here. It's here to stay,
beside DBIx::Squirrel's own stages, such as
L<DBIx::Squirrel::Stages::Rows>.

C<dump_to> is for debugging. It writes each value in full, secrets and
all, and doesn't escape control characters in strings, so a value from
outside can send escape sequences to a terminal.

=head1 SEE ALSO

L<Ekorn::Pipeline::Stages::Taps>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
