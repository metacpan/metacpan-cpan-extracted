use v5.36;

package DBIx::Squirrel::Stages::Flow;

use Exporter qw(import);

use Ekorn::Pipeline::Stages::Flow qw(take drop take_while drop_while);

# A facade over Ekorn::Pipeline::Stages::Flow, exporting DBIx::Squirrel's
# own list of its functions, imported from it by name, so a name
# Ekorn::Pipeline drops fails here, as the module loads, and one it
# adds isn't exported until it's listed here.
our @EXPORT      = qw(take drop);                          ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = (@EXPORT, qw(take_while drop_while));
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Flow - stages taking or dropping values: take, drop, take_while and drop_while

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Flow;

=head1 DESCRIPTION

DBIx::Squirrel's name for L<Ekorn::Pipeline::Stages::Flow>, which
describes its stages in full. It exports C<take> and C<drop> by
default, and C<take_while> and C<drop_while> on request, or all four
with C<:all>. They're Ekorn's functions, from a list of
DBIx::Squirrel's own, so a stage added there reaches this module only
once it's listed here. The module is here to stay, beside
DBIx::Squirrel's own stages, such as L<DBIx::Squirrel::Stages::Rows>.

=head1 SEE ALSO

L<Ekorn::Pipeline::Stages::Flow>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
