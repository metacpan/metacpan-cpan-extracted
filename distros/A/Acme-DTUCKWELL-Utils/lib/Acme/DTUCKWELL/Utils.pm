package Acme::DTUCKWELL::Utils;

use 5.006;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT  = qw(sum);

our %EXPORT_TAGS = (
  all       => [ @EXPORT ]
  );

=head1 NAME

Acme::DTUCKWELL::Utils - The great new Acme::DTUCKWELL::Utils!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Acme::DTUCKWELL::Utils;

    my $foo = Acme::DTUCKWELL::Utils->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub sum {

   my @inputlist = @_;
   my $sum = 0;
   #my $sum = 1;
   OUTER:
   for my $each (@inputlist) {
       if ($each =~ /[A-Za-z]/){
          $sum = 'Invalid';
          last OUTER;
          #die 'Only numbers allowed';
       };
       $sum += $each;
       #$sum = $sum * $each;
   }
   return $sum;
   
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

DTUCKWELL, C<< <dstuckwell at novartis.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-dtuckwell-utils at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-DTUCKWELL-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::DTUCKWELL::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-DTUCKWELL-Utils>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Acme-DTUCKWELL-Utils>

=item * Search CPAN

L<https://metacpan.org/release/Acme-DTUCKWELL-Utils>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by DTUCKWELL.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Acme::DTUCKWELL::Utils
