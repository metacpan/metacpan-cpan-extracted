package Data::Localize::Storage;
use Moo::Role;

has 'lang' => (
    is       => 'ro',
    required => 1
);

requires qw(get set);

sub is_volatile { 1 }

1;

__END__

=head1 NAME

Data::Localize::Storage - Base Role For Storage Objects

=head1 SYNOPSIS

    package MyStorage;
    use Moo;
    with 'Data::Localize::Storage';

    sub get { ... }
    sub set { ... }

=head1 METHODS

=head2 is_volatile

=cut
