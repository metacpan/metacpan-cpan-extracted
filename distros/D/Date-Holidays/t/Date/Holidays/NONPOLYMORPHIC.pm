package Date::Holidays::NONPOLYMORPHIC;

sub new {
    my $class = shift;    

    my $self = bless {
        calendar => { 1224 => 'christmas' },              
    }, $class || ref $class;
    
    return $self;
}

sub nonpolymorphic_holidays {
    my $self = shift;
    
    return $self->{calendar};        
}

sub is_nonpolymorphic_holiday {
    my ($self, $year, $month, $day) = @_;
    
    my $key = $month.$day;

    if (exists $self->{calendar}->{$key}) {
        return $self->{calendar}->{$key};
    }
}

1;
