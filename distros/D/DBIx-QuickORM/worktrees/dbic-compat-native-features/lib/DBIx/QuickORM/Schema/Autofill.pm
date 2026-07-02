package DBIx::QuickORM::Schema::Autofill;
use strict;
use warnings;

our $VERSION = '0.000027';

use Carp qw/croak/;
use DBIx::QuickORM::Util qw/load_class/;

use Object::HashBase qw{
    <types
    <affinities
    <hooks
    <autorow
    +skip
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Schema::Autofill - Autofill configuration for schema introspection.

=head1 DESCRIPTION

Holds the type maps, affinity callbacks, and hooks used while autofilling a
schema from a live database. It maps introspected SQL types to
L<DBIx::QuickORM::Type> classes, runs user-supplied hooks at well-known points,
and generates field and link accessors on autovivified row classes.

=head1 SYNOPSIS

    my $autofill = DBIx::QuickORM::Schema::Autofill->new(
        types      => {...},
        affinities => {...},
        hooks      => {...},
    );

    $autofill->define_autorow($row_class, $table);

=head1 ATTRIBUTES

=over 4

=item types

Hashref mapping SQL type names to type objects/classes.

=item affinities

Hashref mapping affinity names to arrayrefs of callbacks.

=item hooks

Hashref mapping hook names to arrayrefs of callbacks.

=item autorow

The autovivified row class configuration.

=item skip

Nested hashref describing what to skip during autofill.

=back

=cut

# Maps each valid hook name to its seed key: the args key whose value is
# threaded through the callbacks registered for that hook.
my %HOOKS = (
    column         => 'column',
    columns        => 'columns',
    index          => 'index',
    indexes        => 'indexes',
    links          => 'links',
    post_column    => 'column',
    post_table     => 'table',
    pre_column     => 'column',
    pre_table      => 'table',
    primary_key    => 'primary_key',
    table          => 'table',
    tables         => 'tables',
    unique_keys    => 'unique_keys',
    link_accessor  => 'name',
    field_accessor => 'name',
);

=pod

=head1 PUBLIC METHODS

=over 4

=item $bool = $autofill->is_valid_hook($name)

True if C<$name> is a recognized hook name.

=cut

sub is_valid_hook {
    my ($self, $hook) = @_;
    return $HOOKS{$hook} ? 1 : 0;
}

=pod

=item $out = $autofill->hook($name, \%args, $seed)

Run every callback registered for the named hook as a pipeline. Each hook has
a designated seed key in C<\%args> (for example C<table> for the table hooks,
C<name> for the accessor hooks). Every callback is called with the args (plus
C<autofill>) with the running value under the seed key, and its return value
becomes the running value passed to the next callback and ultimately returned.
A callback that modifies the seed in place must still return it so the
callbacks after it (and the caller) see the same value. The pipeline starts
from C<$seed> when given, otherwise from the seed key's value in C<\%args>;
with a single registered callback this matches the old single-callback
behavior exactly.

=cut

sub hook {
    my $self = shift;
    my ($hook, $args, $seed) = @_;

    croak "'$hook' is not a valid hook" unless $HOOKS{$hook};

    my $key = $HOOKS{$hook};
    my $out = @_ > 2 ? $seed : $args->{$key};

    for my $cb (@{$self->{+HOOKS}->{$hook} // []}) {
        $args->{$key} = $out;
        $out = $cb->(%$args, autofill => $self);
    }

    return $out;
}

=pod

=item $val = $autofill->skip(@path)

Walk the nested C<skip> hashref along C<@path>, returning the value found or
false (0) as soon as any step is missing.

=cut

sub skip {
    my $self = shift;

    my $from = $self->{+SKIP};
    while (@_) {
        my $arg = shift @_;
        $from = $from->{$arg} or return 0;
    }
    return $from;
}

=pod

=item $autofill->process_column(\%col)

Resolve the column's scalar-ref type into a real type object, using the type map
first and then affinity callbacks. Updates the column's C<type> and C<affinity>
in place when a match is found.

=cut

sub process_column {
    my $self = shift;
    my ($col) = @_;

    my $type = $col->{type};
    my $tref = ref($type);
    return unless $tref && $tref eq 'SCALAR';

    my $new_type;
    $new_type = $self->{+TYPES}->{$$type} // $self->{+TYPES}->{uc($$type)} // $self->{+TYPES}->{lc($$type)};

    unless ($new_type) {
        if (my $aff = $col->{affinity}) {
            if (my $list = $self->{+AFFINITIES}->{$aff}) {
                for my $cb (@$list) {
                    $new_type = $cb->(%$col) and last;
                }
            }
        }
    }

    return unless $new_type;

    $col->{type} = $new_type;
    $col->{affinity} = $new_type->qorm_affinity(sql_type => $$type);
}

=pod

=item $autofill->define_autorow($row_class, $table)

Load (or autovivify) the row class, then install field accessors for each column
and link accessors for each link, honoring the C<field_accessor> and
C<link_accessor> hooks and never clobbering accessors that already exist.

=back

=cut

sub define_autorow {
    my $self = shift;
    my ($row_class, $table) = @_;

    unless(load_class($row_class)) {
        my $err = $@;
        die $err unless $err =~ m/Can't locate.*in \@INC/;
        my $row_file = $row_class;
        $row_file =~ s{::}{/}g;
        $row_file .= ".pm";
        $INC{$row_file} = __FILE__;
    }

    for my $column ($table->columns) {
        my $field = $column->name;
        my $accessor = $self->hook(field_accessor => {table => $table, name => $field, field => $field, column => $column}, $field);
        next unless $accessor;

        no strict 'refs';
        next if defined &{"$row_class\::$accessor"};
        *{"$row_class\::$accessor"} = sub { shift->field($field, @_) };
    }

    for my $link (@{$table->links}) {
        my $to = $link->other_table;
        my $aliases = $link->aliases;

        $aliases = [$link->unique ? $to : "${to}s"] unless $aliases && @$aliases;

        for my $alias (@$aliases) {
            my $accessor = $self->hook(link_accessor => {table => $table, linked_table => $link->other_table, name => $alias, link => $link}, $alias);
            next unless $accessor;
            no strict 'refs';
            next if defined &{"$row_class\::$accessor"};
            *{"$row_class\::$accessor"} = $link->unique ? sub { shift->obtain($link) } : sub { shift->follow($link) };
        }
    }
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
