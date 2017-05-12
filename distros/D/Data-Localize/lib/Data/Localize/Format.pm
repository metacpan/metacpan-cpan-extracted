package Data::Localize::Format;
use Moo;

sub format { Carp::confess("format() must be overridden") }

1;

__END__

=head1 NAME

Data::Localize::Format - Base Format Class

=head1 METHODS

=head2 format

Must be overridden in subclasses

=cut
