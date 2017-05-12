package Data::Serializer::Benchmark::Serialize;

sub serialize {
#    $_[0]->{options}->{benchmark}->deflate($_[1]);
     my $benchmark = $_[0]->{options};
     $benchmark->{deflate}->($_[1], $benchmark->{args} );
}

sub deserialize {
#    $_[0]->{options}->{benchmark}->inflate($_[1]);
     my $benchmark = $_[0]->{options};
     $benchmark->{inflate}->($_[1], $benchmark->{args} );
}

1;
