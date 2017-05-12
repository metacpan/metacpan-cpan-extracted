package MagicNumber;

# Export object-oriented methods!
@EXPORT       = qw(magic_number);

use base 'Class::Exporter';

sub new {
    my $class = shift;
    bless { magic_number=>3, @_ }, $class
}

sub magic_number {
    my $self = shift;
    @_ and $self->{magic_number} = shift;
    $self->{magic_number}
}

  
