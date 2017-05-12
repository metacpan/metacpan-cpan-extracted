package DB::Introspector::SQLGen::TypeMapper;

use strict;


sub new {
    my $class = shift;
    my $self = bless({}, ref($class) || $class);

    return $self;
}

sub stringify {
    my $class = shift;
    my $column = shift;

    if( UNIVERSAL::isa($column, 'DB::Introspector::Base::IntegerColumn') ) {
        $class->stringify_integer($column);
    } elsif( UNIVERSAL::isa($column, 'DB::Introspector::Base::StringColumn') ) {
        $class->stringify_string($column);
    } elsif( UNIVERSAL::isa($column, 'DB::Introspector::Base::DateTimeColumn') ) {
        $class->stringify_date($column);
    } elsif( UNIVERSAL::isa($column, 'DB::Introspector::Base::CharColumn') ) {
        $class->stringify_char($column);
    } elsif( UNIVERSAL::isa($column, 'DB::Introspector::Base::BooleanColumn')) {
        $class->stringify_boolean($column);
    } elsif( UNIVERSAL::isa($column, 'DB::Introspector::Base::CLOBColumn')) {
        $class->stringify_clob($column);
    }
}

sub stringify_clob {
    my $class = shift;
    my $column = shift;

}

sub stringify_integer {
    my $class = shift;
    my $column = shift;

}

sub stringify_string {
    my $class = shift;
    my $column = shift;

} 

sub stringify_date {
    my $class = shift;
    my $column = shift;

}

sub stringify_char {
    my $class = shift;
    my $column = shift;

}

1;
