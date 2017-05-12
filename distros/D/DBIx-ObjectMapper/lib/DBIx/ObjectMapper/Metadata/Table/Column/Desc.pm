package DBIx::ObjectMapper::Metadata::Table::Column::Desc;
use strict;
use warnings;
use overload
    '""' => sub { $_[0]->{col} . ' DESC' },
    fallback => 1,
;

sub new {
    my ( $class, $col ) = @_;
    bless { col => $col }, $class;
}

sub as_alias {
    my $self = shift;
    my $name = shift;
    $self->{col} = $self->{col}->as_alias($name);
    return $self;
}

sub table { $_[0]->{col}->table }

1;
