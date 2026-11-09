use v5.36;

package DBIx::Squirrel::Stages::Batch;

use Exporter qw(import);

use Ekorn::Pipeline::Stages::Batch qw(batch collect);

# A facade over Ekorn::Pipeline::Stages::Batch, exporting DBIx::Squirrel's
# own list of its functions, imported from it by name, so a name
# Ekorn::Pipeline drops fails here, as the module loads, and one it
# adds isn't exported until it's listed here.
our @EXPORT      = qw(batch collect);      ## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Stages::Batch - stages gathering values: batch and collect

=head1 SYNOPSIS

    use DBIx::Squirrel::Stages::Batch;

=head1 DESCRIPTION

DBIx::Squirrel's name for L<Ekorn::Pipeline::Stages::Batch>, which
describes its stages in full. It exports C<batch> and C<collect> by
default, or with C<:all>: Ekorn's functions, from a list of
DBIx::Squirrel's own, so a stage added there reaches this module only
once it's listed here. It's here to stay, beside DBIx::Squirrel's own
stages, such as L<DBIx::Squirrel::Stages::Rows>.

=head1 SEE ALSO

L<Ekorn::Pipeline::Stages::Batch>, L<DBIx::Squirrel>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
