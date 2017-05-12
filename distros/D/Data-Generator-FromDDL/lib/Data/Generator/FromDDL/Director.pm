package Data::Generator::FromDDL::Director;
use strict;
use warnings;
use Carp qw(croak);
use List::MoreUtils qw(any);
use Class::Accessor::Lite (
    new => 1,
    rw => [qw(builder_class schema include exclude)],
);

use Data::Generator::FromDDL::Formatter;

sub generate {
    my ($self, $num, $format, $pretty, $bytes_per_sql) = @_;
    my @tables = $self->_get_right_order_tables;
    croak("Not all tables found: You must specify all tables schema.\n")
        unless @tables;

    my @recordsets;
    for my $table (@tables) {
        my $builder = $self->builder_class->new({
            table => $table,
            recordsets => \@recordsets,
        });
        my $n = $self->_get_num_for_table($num, $table->name);

        if ($n) {
            push @recordsets, $builder->generate($n);
        }
    }

    return @recordsets;
}

sub flush {
    my ($self, $recordsets, $out_fh, $format, $pretty, $bytes_per_sql) = @_;

    my $formatter = Data::Generator::FromDDL::Formatter->new(
        format => $format,
        pretty => $pretty,
        bytes_per_sql => $bytes_per_sql,
    );

    for my $recordset (@$recordsets) {
        $recordset->iterate_through_chunks(sub {
            my ($table, $fields, $rows) = @_;
            my $sql = $formatter->to_string($table, $fields, $rows);
            print $out_fh $sql . "\n";
        });
    }
}

sub _get_num_for_table {
    my ($self, $num, $table_name) = @_;
    if (ref $num eq 'HASH') {
        return exists $num->{tables}{$table_name}
            ? $num->{tables}{$table_name}
            : $num->{all};
    } else {
        return $num;
    }
}

sub _get_right_order_tables {
    my $self = shift;
    my @tables = $self->schema->get_tables;
    my @filtered = $self->_filter_tables(\@tables);

    return $self->_resolve_data_generation_order(\@filtered);
}

sub _filter_tables {
    my ($self, $tables) = @_;
    my @include = @{$self->include};
    my @exclude = @{$self->exclude};

    my @filtered;
    if (scalar(@include)) {
        for my $t (@$tables) {
            push @filtered, $t if any { $t->name eq $_ } @include;
        }
    } elsif (scalar(@exclude)) {
        for my $t (@$tables) {
            push @filtered, $t unless any { $t->name eq $_ } @exclude;
        }
    } else {
        @filtered = @$tables;
    }

    return @filtered;
}

sub _resolve_data_generation_order {
    my ($self, $tables) = @_;
    my @unresolved = @$tables;
    my @resolved;

    while (my @before = @unresolved) {
        $self->_resolve_inter_table_reference(\@unresolved, \@resolved);

        # can't resolve inter table reference anymore.
        if (@before == @unresolved) {
            croak("Not all tables found: You must specify all tables schema.\n");
        }
    }

    return @resolved;
}

sub _resolve_inter_table_reference {
    my ($self, $unresolved, $resolved) = @_;
    my @old_unresolved = @$unresolved;
    splice @$unresolved, 0;

    for my $ur (@old_unresolved) {
        if ($self->_exist_all_foreign_key_reference($ur, $resolved)) {
            push @$resolved, $ur;
        } else {
            push @$unresolved, $ur;
        }
    }
}

sub _exist_all_foreign_key_reference {
    my ($self, $table, $others) = @_;
    my @fk_constraints = grep { uc($_->type) eq 'FOREIGN KEY' }
        $table->get_constraints;
    for my $constraint (@fk_constraints) {
        my $ref_table = $constraint->reference_table;
        unless (grep { $ref_table eq $_->name } @$others) {
            return undef;
        }
    }

    return 1;
}

1;
