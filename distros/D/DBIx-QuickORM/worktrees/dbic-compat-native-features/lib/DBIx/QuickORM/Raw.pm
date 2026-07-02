package DBIx::QuickORM::Raw;
use strict;
use warnings;

our $VERSION = '0.000027';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Raw - Wrapper marking a value as already in database form.

=head1 DESCRIPTION

A thin wrapper around a single value that is already in its database
(deflated) form. When used as a value in a query it binds as-is rather than
being deflated again, which matters for types whose deflation is not
idempotent (JSON re-encodes a string, for example).

The main use is compare-and-set guards: the guard value is read straight from
a row's stored data and must be compared against the exact bytes in the
database, so it must not pass through deflation a second time.

This is intentionally B<not> a column type and cannot be used with C<autotype>;
it only ever wraps an individual value. It consumes the type role purely so the
existing bind path recognizes it and calls its C<qorm_deflate>, which hands the
value back untouched.

=head1 SYNOPSIS

    my $raw = DBIx::QuickORM::Raw->new($row->raw_stored_field('data'));

    # Compares against the stored value exactly, no re-deflation.
    $handle->where({data => {'-value' => $raw}})->...;

=head1 PUBLIC METHODS

=over 4

=item $raw = DBIx::QuickORM::Raw->new($value)

Wrap a database-form value.

=item $value = $raw->qorm_deflate(%args)

Return the wrapped value unchanged; it is already in database form.

=back

=cut

sub new {
    my $class = shift;
    my ($value) = @_;
    return bless \$value, $class;
}

sub qorm_deflate { ${$_[0]} }

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
