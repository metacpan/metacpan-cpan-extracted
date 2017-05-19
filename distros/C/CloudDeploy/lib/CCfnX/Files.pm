package CCfnX::Files {
  use Moose;
  use CCfnX::File;
  use CCfnX::UserData;
  use File::Slurp;
  
  use autodie;

  has Files => (isa => 'HashRef[CCfnX::File]', is => 'ro', required => 1);

  sub filespec {
    my ($class, %filespec) = @_;
    return $class->new(Files => { map { ( $_ => CCfnX::File->new(
                                             mode => $filespec{$_}->[0],
                                             owner => $filespec{$_}->[1],
                                             group => $filespec{$_}->[2],
                                             content => CCfnX::UserData->new(text => [ read_file($filespec{$_}->[3]) ]) ))
                                      } keys %filespec
                                } );
  }
  sub as_hashref {
    my $self = shift;
    return { map { ($_ => $self->Files->{$_}->as_hashref)  } keys %{ $self->Files } };
  }
}

1;
