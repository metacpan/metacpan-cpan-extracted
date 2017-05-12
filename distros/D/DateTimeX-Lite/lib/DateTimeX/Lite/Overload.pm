package DateTimeX::Lite;

use overload (
    fallback => 1,
    '<=>' => '_compare_overload',
    'cmp' => '_compare_overload',
    '""'  => '_stringify_overload',
    'eq'  => '_string_equals_overload',
    'ne'  => '_string_not_equals_overload',
);

sub _stringify_overload {
    my $self = shift;

    return $self->iso8601 unless $self->{formatter};
    return $self->{formatter}->format_datetime($self);
}

sub _compare_overload
{
    # note: $_[1]->compare( $_[0] ) is an error when $_[1] is not a
    # DateTime (such as the INFINITY value)
    return $_[2] ? - $_[0]->compare( $_[1] ) : $_[0]->compare( $_[1] );
}

sub _string_equals_overload {
    my ( $class, $dt1, $dt2 ) = ref $_[0] ? ( undef, @_ ) : @_;

    return unless(
        blessed $dt1 && $dt1->can('utc_rd_values') &&
        blessed $dt2 && $dt2->can('utc_rd_values')
    );

    $class ||= ref $dt1;
    return ! $class->compare( $dt1, $dt2 );
}

sub _string_not_equals_overload {
    return ! _string_equals_overload(@_);
}


1;
