package CPAN::Testers::Reports::Query::JSON::Set;

use Moose;
use namespace::autoclean;

has name           => ( isa => 'Str', is => 'ro', default => 'no-name' );
has total_tests    => ( isa => 'Int', is => 'rw', default => 0 );
has number_passed  => ( isa => 'Int', is => 'rw', default => 0 );
has number_failed  => ( isa => 'Str', is => 'rw', default => 0 );
has percent_passed => ( isa => 'Str', is => 'rw', default => 0 );
has data => ( isa => 'ArrayRef', is => 'rw', );

sub BUILD {
    my $self = shift;

    my $total_tests   = 0;
    my $number_failed = 0;

    # Go get the data
    foreach my $data ( @{ $self->data() } ) {
        $total_tests++;
        $number_failed++ unless $data->state eq 'pass';
    }
    return unless $total_tests;

    $self->total_tests($total_tests);
    $self->number_failed($number_failed);
    $self->number_passed( $total_tests - $number_failed );

    # calc percent
    $self->percent_passed( ( $self->number_passed() / $total_tests ) * 100 );

    # We don't need the data now
    $self->data( [] );
}

__PACKAGE__->meta->make_immutable;

1;

__DATA__

=head1 NAME

  CPAN::Testers::Reports::Query::JSON::Set

=head1 DESCRIPTION

You should not use this directly, CPAN::Testers::Reports::Query::JSON
returns objects of this type when you call all(), win32_only(), non_win32()
or for_os().

=head1 methods

=over

=item name() 
        
=item total_tests()   

=item number_passed()

=item number_failed()

=item percent_passed()

=back

=head1 AUTHOR
 
Leo Lapworth, LLAP@cuckoo.org

=cut
