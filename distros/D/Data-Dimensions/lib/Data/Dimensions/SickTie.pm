package Data::Dimensions::SickTie;
# This module does horrid things with tie to allow ->set = stuff to
# perform type checking

sub TIESCALAR {
    my $class = shift;
    return bless [@_], $class;
}
sub FETCH {
    return $_[0]->[0];
}
sub STORE {
    my ($self, $val) = @_;
    my $obj = $self->[0];
    if (!ref($val) || !UNIVERSAL::isa($val, 'Data::Dimensions')) {
	$obj->natural($val);
    }
    else {
	$obj->_moan("Storing value with incorrect units")
	    unless $obj->same_units($val);
	$obj->base($val->base);
    }
}
1;

__END__

=head1 Data::Dimensions::SickTie

This is ugly and shouldn't need to see the light of day.  I consider
this package evidence enough that perl6 won't be released a minute too
soon.

=cut
