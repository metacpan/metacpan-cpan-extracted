package DBIx::QuickORM::Role::Type;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Type - Role defining the inflate/deflate type contract.

=head1 DESCRIPTION

Type classes (for example L<DBIx::QuickORM::Type::JSON> and
L<DBIx::QuickORM::Type::UUID>) consume this role to convert column values
between their database form and their inflated Perl form.

=head1 REQUIRED METHODS

=over 4

=item $perl = $type->qorm_inflate(...)

Convert a raw database value into its inflated Perl form.

=item $raw = $type->qorm_deflate(...)

Convert an inflated value back to the form stored in the database.

=item $bool = $type->qorm_compare($a, $b)

Compare two values for equality. Returns true when the two values are the
same, false when they differ.

=item $affinity = $type->qorm_affinity(...)

Return the storage affinity (C<string>, C<numeric>, C<binary>, C<boolean>).

=item $sql_type = $type->qorm_sql_type($dialect)

Return the SQL column type to use for the given dialect.

=back

=cut

sub qorm_register_type {
    my $this = shift;
    my $class = ref($this) || $this;
    croak "'$class' does not implement qorm_register_type() and cannot be used with autotype()";
}

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
