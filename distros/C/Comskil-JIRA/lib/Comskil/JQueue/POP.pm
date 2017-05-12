
# #TODO Inherit from the JQueue class.
# #TODO Add in Perl documentation:  Full Documentation.
# #TODO Create a test program for this package.




package Comskil::JQueue::POP;

use strict;
use warnings;


use Net::POP3_auth;

use Comskil::JServer;
use Comskil::JQueue;

BEGIN {
    use Exporter();
	
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
 
    $VERSION = '0.10';
    @ISA = qw( Exporter Comskil::JQueue );
    @EXPORT	= qw( );
    @EXPORT_OK = qw( try );
    %EXPORT_TAGS = ( ALL => [ qw( try ) ] );
}

END { }

sub new {
	my ($type,@args) = @_;
	my $self = Comskil::JQueue->new();
	bless($self,$type);
	
	return($self);
}


sub try {
	my ($self,@args) = @_;
	return($self);
}
 

1;
__END__
### EOF ###

=head1 NAME

Comskil::JQueue:POP

=head1 VERSION

Version 0.1

=head1 SYNOPIS

asdads

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new()

=head2 try()

=head2 function1()

sub function1 {
}

=head2 function2()

=cut

sub function2 {
}

=head1 AUTHOR

Peter Shiner, C<< <pshiner at comskil.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-comskil-jwand at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Comskil-JWand>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Comskil::JWand


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Comskil-JWand>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Comskil-JWand>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Comskil-JWand>

=item * Search CPAN

L<http://search.cpan.org/dist/Comskil-JWand/>

=back

=head1 ACKNOWLEDGEMENTS

asdasda

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Peter Shiner.

This program is released under the following license: restrictive

=cut