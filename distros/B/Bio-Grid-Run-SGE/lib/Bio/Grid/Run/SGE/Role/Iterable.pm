package Bio::Grid::Run::SGE::Role::Iterable;

use Mouse::Role;

use warnings;
use strict;

our $VERSION = '0.066'; # VERSION

has indices => (is => 'rw', required => 1, isa => 'ArrayRef'); 
has _iterating => (is => 'rw');
has _range => (is => 'rw');

requires qw/cur_comb_idx peek_comb_idx num_comb cur_comb next_comb range/;

sub BUILD { }

before range => sub{
    my ($self, $idx_range) = @_;
    
    confess "range problems: [" . ( $idx_range ? join( ",", @$idx_range ) : $idx_range ) . "]"
        unless ( $idx_range && @$idx_range >= 2 );
    confess "You specified a range that is bigger than the number of combinations ($idx_range->[0], $idx_range->[1]), ". $self->num_comb
        if ( $idx_range->[1] >= $self->num_comb );
        #FIXME more range checks

};

#sub BUILD { }
#after BUILD => sub {
    #my ($self) = @_;
    
    #for my $idx (@{$self->indices}) {
        #$idx->create;
    #}
#};
    #create indices input files newer or if not exist

#sub range { my ($self, $num_parts, $idx_range) = @_; }


1;

__END__

=head1 NAME

Bio::Grid::Run::SGE::Role::Iterable - iterator role/base class

=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 REQUIRED METHODS

=over 4

=item B<< num_comb >>

Return the number of combinations

=item B<< peek_comb_idx >>

Take a peek to the index of next combination.

=item B<< cur_comb_idx  >>

Return the index of the current combination.

=item B<< cur_comb >>

Get the current combination

=item B<< next_comb >>

Get the next combination. Switches to the next combination. CHANGES THE ITERATOR.

=back

=head1 METHODS

=over 4

=item B<< idx_range >>

get or set the index range that this iterator should span

=item B<< indices >>

get or set the indices this iterator should iterate over.

=item B<< num_parts >>

Get the number of jobs/parts that are generated


=back


=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
