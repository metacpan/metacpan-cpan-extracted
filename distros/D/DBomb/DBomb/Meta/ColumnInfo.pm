package DBomb::Meta::ColumnInfo;

=head1 NAME

DBomb::Meta::ColumnInfo - Meta data about a column.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.15 $';

use Carp qw(carp croak);
use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new_internal',
    'get_set' => [qw(table_info), # table_info
                  qw(name),       # column name
                  qw(fq_name),    # fully qualified -- read only
                  qw(accessor),   # accessor name
                  qw(attr),       # attribute name
                  qw(select_when_null),  # list of 1 element. promote NULLs to this value. default: []
                  qw(update_when_empty), # list of 1 element. promote empty string to this value. default: []
                  ],
    'boolean' => [qw(is_resolved),
                  qw(is_expr),     # Is an expression column (not a real column)
                  qw(is_generated), # database generates it (auto_increment, etc.)
                  qw(select_trim), # trim whitespace
                  qw(update_trim), # trim whitespace
                  qw(recurse_on_copy), # deep copy
                  ],
    ;

## new ColumnInfo($table_info, $name, $opts)
sub new
{
    ## This new() is actually a class factory, following a parameterized singleton pattern
    ## The real new() is new_internal().
    my $class = ref($_[0]) ? ref(shift) : shift;
    my ($table_info,$name,$opts) = @_;

    assert(defined $table_info);
    assert(defined $name);

    my $cols = DBomb->tables->{$table_info->name}->columns;
    if (exists $cols->{$name}){
        croak "duplicate column name '$name' for table " . $table_info->name;
    }
    else{
        $table_info->add_column($class->new_internal($table_info, $name, $opts));
    }
    return $cols->{$name};
}

sub init
{
    my ($self, $table_info, $name, $opts) = @_;

    assert(defined($table_info), "table_info defined");
    assert(defined($name), "column name defined");
    assert(defined($opts), "options defined");

    $self->table_info($table_info);
    $self->name($name);
    $self->fq_name($self->table_info->name .".". $self->name);
    $self->is_resolved(1); ## nothing to resolve
    $self->select_trim(0);
    $self->update_trim(0);
    $self->recurse_on_copy(0);
    $self->select_when_null([]);
    $self->update_when_empty([]);

    ## defaults
    $self->accessor($name);
    $self->attr("__dbo_column: $name");
    $self->enable_string_mangle if $opts->{'string_mangle'};

    for (keys %$opts) {
        my $v = $opts->{$_};
        /^column$/         && do{ $self->name($v); next};
        /^accessor$/       && do{ $self->accessor($v); next};
        /^attr$/           && do{ $self->attr($v); next};
        /^expr(?:ession)?$/ && do{ $self->name($v); $self->fq_name($v); $self->is_expr(1); next};
        /^is_generated|auto_increment$/   && do{ $self->is_generated($v); next};
        /^select_trim$/    && do{ $self->select_trim($v); next};
        /^update_trim$/    && do{ $self->update_trim($v); next};
        /^recurse_on_copy$/    && do{ $self->recurse_on_copy($v); next};
        /^select_when_null$/  && do{ $self->select_when_null->[0] = $v; next};
        /^update_when_empty$/ && do{ $self->update_when_empty->[0] = $v; next};
        /^string_mangle$/ && do { next; }; # handled above.
        croak "unrecognized option '$_'";
    }
}

sub is_in_primary_key
{
    my $self = shift;
        assert(@_ == 0);
    exists $self->table_info->primary_key->columns->{$self->name};
}

sub enable_string_mangle
{
    my $self = shift;
    $self->select_trim(1);
    $self->update_trim(1);
    $self->select_when_null->[0] = '';
    $self->update_when_empty->[0] = undef;
}

sub resolve { 1 }

1;
__END__

