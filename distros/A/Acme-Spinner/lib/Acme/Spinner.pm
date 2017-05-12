package Acme::Spinner;

use warnings;
use strict;

=head1 NAME

Acme::Spinner - A trivial example of one of those activity spinners

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Acme::Spinner;
    my $s = Acme::Spinner->new();
    while(<>) {
	print STDERR $s->next(), "\r";
        do_interesting_stuff( with => $_ );
    } 

=head1 ABSTRACT

This is a simple module that helps manage one of those silly spinning
bar things that some programs use when they want you to think they
are busy.

=head1 DESCRIPTION

Some programs take a long time to do some functions.  Sometimes
people are get confused about what is happening and start pressing
buttons in an effort to illicit some response while a program is
taking a long time.  Strangely enough if the program gives the
person using it something to watch while it is busy with other work
the person is much more likely to leave the program alone so that
can finish its work. 

=head1 METHODS

=head2 new

The creator.

=cut

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = {};
    $self->{y}     = shift;
    $self->{x}     = shift;
    $self->{count} = 0;
    $self->{seq}   = '|\\-/';

    return bless( $self, $class );
}

=head2 next

Bump the spinner by one and return it.

=cut

sub next {
    my $self = shift;
    my $f = $self->{seq};
    my $t = substr( $f, $self->{count} % length($f), 1 );
    $self->{count}++;

    return ($t);
}

=head1 AUTHOR

Chris Fedde, C<< <cfedde at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-spinner at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Spinner>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Spinner

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Spinner>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Spinner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Spinner>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Spinner>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Chris Fedde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::Spinner
