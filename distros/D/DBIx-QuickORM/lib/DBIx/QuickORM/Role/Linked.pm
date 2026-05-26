package DBIx::QuickORM::Role::Linked;
use strict;
use warnings;

our $VERSION = '0.000020';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/column_key/;

use constant 'LINKS'          => '__links__';
use constant 'BUILT'          => 'built';
use constant 'CACHE_ID'       => 'cache_id';
use constant 'BY_ALIAS'       => 'by_alias';
use constant 'BY_TABLE'       => 'by_table';
use constant 'BY_TABLE_ALIAS' => 'by_table_alias';
use constant 'BY_TABLE_KEY'   => 'by_table_key';

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Linked - Role for sources that expose links.

=head1 DESCRIPTION

Provides link-resolution for sources that know about
L<DBIx::QuickORM::Link> objects. Given a link specification (a name, alias,
table, column set, or an existing link object), C<resolve_link> finds the
matching link, building and caching a set of lookup indexes the first time
it is needed.

=head1 SYNOPSIS

    package My::Source;
    use Role::Tiny::With;
    with 'DBIx::QuickORM::Role::Linked';

    sub links { ... }

    my $link = $source->resolve_link('author');

=head1 REQUIRED METHODS

Consumers must provide C<links>, returning the arrayref of
L<DBIx::QuickORM::Link> objects this source knows about.

=cut

requires qw{
    links
};

=pod

=head1 PUBLIC METHODS

=over 4

=item $source->connection

=item $source->from

Default no-op accessors; consumers override them when they have a
connection or can resolve a sub-source by name.

=back

=cut

sub connection {}
sub from {}

=pod

=over 4

=item $link = $source->resolve_link($spec, %params)

=item $link = $source->resolve_link(%params)

Resolve a link from a specification. Accepts an existing
L<DBIx::QuickORM::Link> (returned as-is), a reference (a hashref/arrayref
parsed into a link), or a name/alias/table/column lookup. Croaks when the
specification cannot be resolved or is ambiguous.

A bare string spec is a B<fuzzy> lookup: it is matched against aliases, then
table names, then column keys, and the first hit wins. To force a particular
dimension, pass it by keyword instead:

    $source->resolve_link(alias => 'author');           # by link alias only
    $source->resolve_link(table => 'users');            # by destination table only
    $source->resolve_link(table => 'users', columns => ['user_id']);  # by table + columns

C<alias> and C<table> resolve standalone; C<columns> (or a precomputed
C<key>) is scoped to a table, so pass it together with C<table>.

=back

=cut

sub resolve_link {
    my $self = shift;

    my %params;
    if (@_ % 2) {
        my $spec = shift;
        %params = @_;
        $params{spec} = $spec;
    }
    else {
        %params = @_;
    }

    return $params{link} if $params{link};

    my $spec = $params{spec};
    return $spec if $spec && blessed($spec) && $spec->isa('DBIx::QuickORM::Link');

    if ($params{from}) {
        my $s = $self->from($params{from});
        return $s->resolve_link($spec, %params) if $s;
    }

    return DBIx::QuickORM::Link->parse(
        source => $self,
        link        => $spec,
        connection  => $params{connection} // $self->connection,
    ) if ref $spec;

    my $found = $self->_link_from_name(%params) or croak "Could not resolve link";

    return $found unless ref($found) eq 'ARRAY';
    return $found->[0] if @$found == 1;

    croak join "\n" => (
        "Ambiguous link specification, found the following:",
        (map { "local_table: $_->{local_table} | other_table: $_->{other_table} | key: $_->{key} | aliases: " . join(', ', @{$_->{aliases}}) } @$found),
        '',
    );
}

=pod

=head1 PRIVATE METHODS

=over 4

=item $link = $source->_link_from_name(%params)

Look a link up in the cached indexes by table, alias, key, or columns,
building the indexes on first use. Returns a single link, an arrayref of
candidates, or undef.

=back

=cut

sub _link_from_name {
    my $self = shift;
    my (%params) = @_;

    my $cache = $self->{+LINKS};
    $cache = $self->{+LINKS} = {CACHE_ID() => "$self"} unless $cache && $cache->{+CACHE_ID} eq "$self";

    unless ($cache->{+BUILT}) {
        my %lookup;
        for my $l (sort { $a->other_table cmp $b->other_table || $a->key cmp $b->key } @{$self->links}) {
            my $f = $lookup{$l->other_table}->{$l->key};
            $lookup{$l->other_table}->{$l->key} = $f ? $f->merge($l) : $l;
        }

        $cache->{+BY_TABLE_KEY} = \%lookup;

        for my $link (map {values %{$_}} values %lookup) {
            push @{$cache->{+BY_TABLE}->{$link->other_table}} => $link;

            for my $alias (@{$link->aliases}) {
                push @{$cache->{+BY_ALIAS}->{$alias}} => $link;
                $cache->{+BY_TABLE_ALIAS}->{$link->other_table}->{$alias} //= $link;
            }
        }

        $cache->{+BUILT} = 1;
    }

    my $spec    = $params{spec};
    my $table   = $params{table};
    my $alias   = $params{alias};
    my $columns = $params{columns};
    my $key     = $params{key} //= $columns ? column_key(@$columns) : undef;

    my $out;
    $out //= $cache->{+BY_TABLE_ALIAS}->{$table}->{$alias} if $table && $alias;
    $out //= $cache->{+BY_TABLE_ALIAS}->{$table}->{$spec}  if $table && $spec && !$alias;
    $out //= $cache->{+BY_TABLE_ALIAS}->{$spec}->{$alias}  if $spec  && $alias && !$table;

    $out //= $cache->{+BY_TABLE_KEY}->{$table}->{$key} if $table && $key;
    $out //= $cache->{+BY_TABLE_KEY}->{$spec}->{$key} if $key && $spec && !$table;
    $out //= $cache->{+BY_TABLE_KEY}->{$table}->{$spec} if $table && $spec && !$key;

    $out //= $cache->{+BY_ALIAS}->{$alias} if $alias;
    $out //= $cache->{+BY_ALIAS}->{$spec} if $spec && !$alias;

    $out //= $cache->{+BY_TABLE}->{$table} if $table;
    $out //= $cache->{+BY_TABLE}->{$spec}  if $spec && !$table;

    return $out;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut