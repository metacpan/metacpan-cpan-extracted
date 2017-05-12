package Business::TW::Invoice::U420;

use warnings;
use strict;
use base ('Class::Accessor::Fast', 'Exporter');

__PACKAGE__->mk_accessors(qw(heading lines_available fh lines_used lines_total lines_stamp footer));

use constant ESC => "\x1b";

=head1 NAME

Business::TW::Invoice::U420 - Print Taiwan Unified Invoice with U420 printer

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Business::TW::Invoice::U420->init_printer;
my $u420 = Business::TW::U420->new
    ({ heading => [ DateTime->now->ymd, '',
                    'order: #232', ''],
       lines_total     => 35,
       lines_available => 18,
       lines_stamp     => 5,
       fh => \*STDOUT  });

$u420->println("123123") for 1..30;
$u420->cut;

# to actually print to the printer, run:
# perl your-program.pl > COM1


=head1 DESCRIPTION

This module generates commands for the C<Epson RP-U420 invoice>
printer for printing the Unified Invoice in Taiwan.

You must install the driver and printer processor properly before you
can use the module.

You can define multiple lines of headers that will appear on each page
of the printed invoices, and when you do println the module does all
the necessary paging and stamping for you.

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->fh( \*STDOUT ) unless $self->fh;
    $self->heading( [] ) unless $self->heading;
    $self->footer( [] ) unless $self->footer;
    $self->lines_total(35)
      unless $self->lines_total;
    $self->lines_available(18)
      unless $self->lines_available;
    $self->lines_stamp(5)
      unless $self->lines_stamp;
    return $self;
}

=head2 init_printer

=cut

sub init_printer {
    my $self = shift;
    $self->print( ESC . '@');
}

=head2 feed( $lines )

Feed C<$lines> lines, default is 1.

=cut

sub feed {
    my $self = shift;
    my $lines = shift || 1;
    $self->{lines_used} += $lines;
    $self->print( ESC . 'd'. chr( $lines ) );
}

=head2 stamp

Make the printer stamp on the invoice.  note that you generally don't
want to call this method directly, due to the stamp positioning.  When
you call C<cut>, the module automatically detects the correct place to
stamp for the next invoice.

=cut

sub stamp {
    my $self = shift;
    $self->print( ESC . 'o' );
}

=head2 cut

feed the current invoice and cut, as well as stamping on the next
invoice.

=cut

sub cut {
    my $self = shift;
    return unless defined $self->lines_used;

    $self->feed( $self->lines_total - $self->lines_used + 1 );
    $self->stamp;
    $self->print( "\x0c" );
    $self->lines_used(undef);
}

=head2 print

Low level print function.

=cut

sub print {
    my $self = shift;
    print {$self->fh} @_;
}

=head2 println

Print a line on the invoice.  Does all the paging logic here.

=cut

sub println {
    my $self = shift;
    unless (defined $self->lines_used) {
	$self->lines_used(0);
	$self->feed( $self->lines_stamp );
	$self->println($_) for @{$self->heading};
    }
    $self->print(@_, "\n");
    if (++$self->{lines_used} == $self->lines_available + $self->lines_stamp ) {

	$self->cut;
    }
}

1;

=head1 AUTHOR

Chia-liang Kao, C<< <clkao at clkao.org> >>

=head2 TODO

=over

=item *

Split the device control parts into C<Device::Serial::U420> for
generic use and keep the paging/stamping logic here

=item *

Tests

=item *

Add footer support

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-tw-invoice-u420 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-TW-Invoice-U420>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::TW::Invoice::U420

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-TW-Invoice-U420>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-TW-Invoice-U420>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-TW-Invoice-U420>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-TW-Invoice-U420>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 AIINK co., ltd, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Business::TW::Invoice::U420
