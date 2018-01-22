package ActiveRecord::Simple::Utils;

use strict;
use warnings;

require Exporter;

use Module::Load;
use Module::Loaded;

use Scalar::Util qw/blessed/;

our @ISA = qw/Exporter/;
our @EXPORT = qw/class_to_table_name all_blessed load_module/;


sub quote_sql_stmt {
    my ($sql, $driver_name) = @_;

    return unless $sql && $driver_name;

    $driver_name //= 'Pg';
    my $quotes_map = {
        Pg => q/"/,
        mysql => q/`/,
        SQLite => q/`/,
    };
    my $quote = $quotes_map->{$driver_name};

    $sql =~ s/"/$quote/g;

    return $sql;
}

sub class_to_table_name {
    my ($class) = @_;

    #load $class;

    return $class->_get_table_name if $class->can('_get_table_name');

    $class =~ s/.*:://;
    #$class_name = lc $class_name;
    my $table_name = join('_', map {lc} grep {length} split /([A-Z]{1}[^A-Z]*)/, $class);

    return $table_name;
}

sub is_integer {
    my ($data_type) = @_;

    return unless $data_type;

    return grep { $data_type eq $_ } qw/integer bigint tinyint int smallint/;
}

sub is_numeric {
    my ($data_type) = @_;

    return unless $data_type;
    return 1 if is_integer($data_type);

    return grep { $data_type eq $_ } qw/numeric decimal/;
}

sub all_blessed {
    my ($list) = @_;

    for my $item (@$list) {
        return unless defined $item;
        return unless blessed $item;
    }

    return 1;
}

sub load_module {
    my ($module_name) = @_;

    if (!is_loaded $module_name) {
        eval { load $module_name; };
        mark_as_loaded $module_name;
    }
}

1;