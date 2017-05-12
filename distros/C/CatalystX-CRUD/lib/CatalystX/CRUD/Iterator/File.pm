package CatalystX::CRUD::Iterator::File;
use strict;
use warnings;
use Carp;

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Iterator::File - simple iterator for CXCO::File objects

=head1 SYNOPSIS

 my $iterator = $c->model('MyFile')->iterator;
 while (my $file = $iterator->next)
 {
    # $file is a CatalystX::CRUD::Object::File
    # ...
 }


=head1 DESCRIPTION

CatalystX::CRUD::Iterator::File is a simple iterator to fulfull the
CatalystX::CRUD::Model::File API.

=cut

=head1 METHODS

=head2 new( I<files> )

Returns an iterator for I<files>. I<files> should be an array ref.

=cut

sub new {
    my $class = shift;
    my $files = shift or croak "need files array";
    return bless( $files, $class );
}

=head2 next

Returns the next File object or undef if no more files remain.

=cut

sub next {
    my $self = shift;
    return shift(@$self);
}

=head2 finish

Sets the array ref to empty. Always returns 1. This method is
generally useless but implemented for completeness' sake.

=cut

sub finish {
    my $self  = shift;
    my $class = ref $self;
    $self = bless( [], $class );
    return 1;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
