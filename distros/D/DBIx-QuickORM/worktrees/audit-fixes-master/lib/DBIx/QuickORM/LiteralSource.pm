package DBIx::QuickORM::LiteralSource;
use strict;
use warnings;

our $VERSION = '0.000028';

use Role::Tiny::With qw/with/;

use Carp qw/croak/;

with 'DBIx::QuickORM::Role::Source';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::LiteralSource - A raw SQL fragment used as a query source.

=head1 DESCRIPTION

A source (see L<DBIx::QuickORM::Role::Source>) backed by a literal SQL
string rather than a table, view, or join. The object is a blessed scalar
reference holding the SQL; C<source_db_moniker> returns that SQL verbatim.

The SQL is spliced in as the B<FROM target> of the generated statement, so by
default it must be a table name or FROM-fragment (for example C<users> or
C<users AS u>), B<not> a complete C<SELECT> statement. A full statement
produces broken SQL (C<SELECT * FROM SELECT ...>).

To query a complete statement, pass the C<subquery> option: the SQL is wrapped
as a derived table, C<< ( <sql> ) AS <alias> >>, where the alias is the value
of C<subquery>:

    # SELECT * FROM ( SELECT ... ) AS recent
    my $src = DBIx::QuickORM::LiteralSource->new($full_select, subquery => 'recent');

The alias must be a plain identifier (word characters only); it is interpolated
directly into the SQL and cannot be safely quoted here.

B<Changed in 0.000026:> a non-identifier alias now croaks. Previously any alias
string was spliced into the statement verbatim, which allowed SQL injection.

Literal sources carry no schema metadata: they expose no fields, no primary
key, and no row class, so the field/key accessors return nothing and the
source is not cachable. C<fields_to_fetch> is C<['*']>.

=head1 SYNOPSIS

    # FROM-fragment (table name)
    my $source = DBIx::QuickORM::LiteralSource->new("users");

    # Full statement wrapped as a derived table
    my $sub = DBIx::QuickORM::LiteralSource->new(
        "SELECT * FROM users WHERE active = 1",
        subquery => 'active_users',
    );

=cut

sub new {
    my $class = shift;
    my ($literal, %params) = @_;

    my $sql;
    if (my $ref = ref($literal)) {
        croak "'$literal' is not a scalar reference" unless $ref eq 'SCALAR';
        $sql = $$literal;
    }
    else {
        $sql = $literal;
    }

    # By default the SQL is spliced in as a FROM target (a table name or
    # fragment). When 'subquery' is given the SQL is a complete statement and
    # gets wrapped as a derived table: "( <sql> ) AS <alias>". The alias is the
    # value of 'subquery' (a true value of 1 uses a default alias).
    if (defined(my $sq = $params{subquery})) {
        # An empty or true-of-1 value means "wrap with the default alias"; any
        # other value is the alias. The alias is interpolated into raw SQL with
        # no dbh to quote it, so it must be a leading-letter identifier -- a
        # bare number like 0 would emit an invalid "AS 0".
        my $alias = (!length($sq) || $sq eq '1') ? 'subquery' : $sq;
        croak "subquery alias '$alias' is not a valid identifier" unless $alias =~ /\A[A-Za-z_]\w*\z/;
        $sql = "( $sql ) AS $alias";
    }

    # Bless a fresh scalar ref; never bless the caller's ref in place (doing so
    # would turn their \$sql into a LiteralSource behind their back).
    return bless(\$sql, $class);
}

# {{{ Role::Source interface

# No primary key, so Role::Source's cachable default already returns 0.

sub source_db_moniker { ${$_[0]} }
sub source_orm_name   { 'LITERAL' }

sub fields_list_all { ['*'] }
sub fields_to_fetch { ['*'] }

sub field_affinity { 'string' }

sub field_type     { }
sub fields_to_omit { }
sub has_field      { }
sub primary_key    { }
sub row_class      { }

sub field_db_name  { my ($self, $name) = @_; return $name }
sub field_orm_name { my ($self, $name) = @_; return $name }

sub field_is_generated { 0 }

sub source_has_aliases { 0 }

# }}} Role::Source interface

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
