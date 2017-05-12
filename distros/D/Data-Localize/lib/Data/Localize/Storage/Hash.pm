package Data::Localize::Storage::Hash;
use Moo;

with 'Data::Localize::Storage';

sub get {
    my $self = shift;
    $self->{$_[0]}
}

sub set {
    my $self = shift;
    $self->{$_[0]} = $_[1];
}

1;

__END__

=head1 NAME

Data::Localize::Storage::Hash - Hash Backend

=head1 SYNOPSIS

    use Data::Localize::Storage::Hash;

    Data::Localize::Storage::Hash->new();

=head1 METHODS

=head2 get

=head2 set

=cut