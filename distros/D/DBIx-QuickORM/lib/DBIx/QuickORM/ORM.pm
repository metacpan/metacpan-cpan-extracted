package DBIx::QuickORM::ORM;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;

use DBIx::QuickORM::DSL();

use parent 'DBIx::QuickORM';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::ORM - Base class for an ORM defined as classes.

=head1 DESCRIPTION

The C<orm> block of L<DBIx::QuickORM::DSL> makes its package a subclass of
this one. C<new> gathers what the C<orm> block and the table classes collected
into arguments for L<DBIx::QuickORM's C<new>|DBIx::QuickORM/"PUBLIC METHODS">,
then constructs the ORM with them.

The table classes are the modules directly under the ORM class's namespace
(C<My::ORM::*> for C<My::ORM>), found in C<@INC>. Every module there is
loaded, and those with a C<table> block are used. The C<tables> keyword
replaces that search with another namespace or a list of classes. A table
that needs nothing adjusted needs no class.

=head1 SYNOPSIS

    package My::ORM;
    use DBIx::QuickORM::DSL ':orm';

    orm {
        retain_cache 1;
    };

    package main;

    my $orm = My::ORM->new(
        dbh   => $dbh,
        types => {users => {prefs => undef}},
    );

=head1 PUBLIC METHODS

=over 4

=item $orm = My::ORM->new(%args)

=item $orm = My::ORM->new(\%args)

Constructs the ORM from the collected specs and C<%args>, which takes the
arguments of L<DBIx::QuickORM's C<new>|DBIx::QuickORM/"PUBLIC METHODS">.

Precedence, lowest to highest: the C<orm> block's keywords, its C<override>,
the table classes, then C<%args>. C<time_zone> and its alias C<tz> count as
one argument, so either spelling in C<%args> beats either in C<override>.

C<types> merge per field and C<fks> per target table: a higher source's
entry for a field (or target table) replaces the lower one's, and the rest
stay.

C<omit>, C<default_fields>, and C<row_classes> apply per table: a higher
source's entry for a table replaces the lower one's entry for that table
whole. C<omit> and C<default_fields> count as one setting there, so a higher
source's C<omit> for a table also drops a lower one's C<default_fields> for
it, and the other way around.

Croaks when:

=over 4

=item *

The class has no C<orm> block of its own. Specs are not inherited, so a
subclass of an ORM class needs its own.

=item *

Two table classes name one table.

=item *

A table class names a table the database does not have.

=item *

C<tables> lists a class without a C<table> block.

=back

=back

=cut

my %TABLE_ARG = (
    omit           => 'omit',
    default_fields => 'default_fields',
    types          => 'types',
    fks            => 'fks',
    row_class      => 'row_classes',
);

my %PER_TABLE = map { $_ => 1 } values %TABLE_ARG;
my %PER_ENTRY = (types => 1, fks => 1);

sub new {
    my $class = shift;
    my %args  = @_ == 1 && ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;

    my $spec = DBIx::QuickORM::DSL->orm_spec($class) or croak "$class has no orm block; DBIx::QuickORM::ORM specs are not inherited";

    my %orm      = %$spec;
    my $tables   = delete $orm{tables};
    my $override = delete($orm{override}) // {};

    my ($from_tables, $claimed) = $class->_table_args($tables);
    my $self = $class->SUPER::new($class->_merge({%orm, %$override}, $from_tables, \%args), caller => [caller]);

    for my $table (sort keys %$claimed) {
        croak "$claimed->{$table} names the table '$table', which is not in the database map" unless $self->db_map->table($table);
    }

    return $self;
}

=pod

=head1 PRIVATE METHODS

=over 4

=item (\%args, \%claimed) = $class->_table_args($tables)

The table classes' C<new> arguments, and which class named each table.

=back

=cut

sub _table_args {
    my $class = shift;
    my ($tables) = @_;

    my (%args, %claimed);
    for my $table_class ($class->_table_classes($tables)) {
        my $spec = DBIx::QuickORM::DSL->table_spec($table_class);
        my $name = $spec->{name};

        croak "Both $claimed{$name} and $table_class name the table '$name'" if $claimed{$name};
        $claimed{$name} = $table_class;

        for my $key (keys %TABLE_ARG) {
            $args{$TABLE_ARG{$key}}->{$name} = $spec->{$key} if exists $spec->{$key};
        }
    }

    return (\%args, \%claimed);
}

=pod

=over 4

=item @classes = $class->_table_classes($tables)

The table classes: those listed, or those found under a namespace (the class's
own unless C<$tables> names another). Loads each class it looks at.

=back

=cut

sub _table_classes {
    my $class = shift;
    my ($tables) = @_;

    if (ref($tables) eq 'ARRAY') {
        for my $table_class (@$tables) {
            $class->load_class("'tables' lists $table_class, which", $table_class) unless DBIx::QuickORM::DSL->table_spec($table_class);
            croak "'tables' lists $table_class, which has no 'table' block"        unless DBIx::QuickORM::DSL->table_spec($table_class);
        }
        return @$tables;
    }

    my $namespace = $tables // $class;
    croak "'tables' must be a namespace or an arrayref of class names" if ref($namespace) || !length($namespace);

    (my $dir = $namespace) =~ s{::}{/}g;
    my %found;
    for my $inc (grep { !ref($_) } @INC) {
        opendir(my $dh, "$inc/$dir") or next;
        $found{"${namespace}::$_"} = 1 for map { m/^(\w+)\.pm$/ ? $1 : () } readdir($dh);
    }

    my @classes = sort keys %found;
    $class->load_class("The table class '$_'", $_) for @classes;
    return grep { DBIx::QuickORM::DSL->table_spec($_) } @classes;
}

=pod

=over 4

=item %args = $class->_merge(\%lowest, ..., \%highest)

Merges argument sets, a higher one replacing a lower one's argument, or for
the per-table arguments its entry for each table it names. C<types> and
C<fks> go one level deeper: per field and per target table. A table named in a
higher set's C<omit> or C<default_fields> loses its entries in both from the
lower sets. C<time_zone> and its alias C<tz> count as one argument.

=back

=cut

sub _merge {
    my $class = shift;

    my %merged;
    for my $args (@_) {
        delete @merged{qw/time_zone tz/} if grep { exists $args->{$_} } qw/time_zone tz/;

        my @named = map { ref($args->{$_}) eq 'HASH' ? keys %{$args->{$_}} : () } qw/omit default_fields/;
        for my $key (grep { ref($merged{$_}) eq 'HASH' } qw/omit default_fields/) {
            my %kept = %{$merged{$key}};
            delete @kept{@named};
            $merged{$key} = \%kept;
        }

        for my $key (keys %$args) {
            my ($have, $new) = ($merged{$key}, $args->{$key});
            unless ($PER_TABLE{$key} && ref($have) eq 'HASH' && ref($new) eq 'HASH') { $merged{$key} = $new; next }

            my %both = (%$have, %$new);
            if ($PER_ENTRY{$key}) {
                for my $table (grep { ref($have->{$_}) eq 'HASH' && ref($new->{$_}) eq 'HASH' } keys %$new) {
                    $both{$table} = {%{$have->{$table}}, %{$new->{$table}}};
                }
            }
            $merged{$key} = \%both;
        }
    }

    return %merged;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
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
