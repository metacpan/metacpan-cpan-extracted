package App::Grepl::Base;

use warnings;
use strict;
use Scalar::Util 'reftype';

=head1 NAME

App::Grepl::Base - Common methods for App::Grepl (internal only)

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Common methods for App::Grepl

=head1 METHODS

=head2 Class Methods

=head3 C<new>

 my $grepl = App::Grepl->new;

Common constuctor for C<App::Grepl> classes.  If an argument is passed, it
must be a hashref.

All initialization should be via an overridden C<_initialize> method.

=cut

sub new {
    my ( $class, $arg_for ) = @_;
    $arg_for ||= {};

    my $reftype = reftype $arg_for || 'SCALAR';
    unless ( 'HASH' eq $reftype ) {
        $class->_croak("Argument to new must be a hashref, not a ($reftype)");
    }

    my $self = bless {} => $class;
    $self->_initialize($arg_for);
    return $self;
}

sub _croak {
    my ( $class, $message ) = @_;
    require Carp;
    Carp::croak($message);
}

=head1 AUTHOR

Curtis Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-grepl at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Grepl>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Grepl::Base

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Grepl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Grepl>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Grepl>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Grepl>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Curtis Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
