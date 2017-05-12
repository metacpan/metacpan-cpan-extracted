package Cisco::UCS::Fault;

use strict;
use warnings;

use Carp		qw(croak);
use Scalar::Util	qw(weaken);

our $VERSION = '0.51';

our @ATTRIBUTES	= qw(ack code cause created dn id occur rule severity tags 
type);

our %ATTRIBUTES	= (
	last_transition		=> 'lastTransition',
	highest_severity	=> 'highestSeverity',
	original_severity	=> 'origSeverity',
	previous_severity	=> 'prevSeverity',
	desc			=> 'descr'
);

sub new {
        my ( $class, %args ) = @_; 

        my $self = {}; 
        bless $self, $class;

        defined $args{dn}
		? $self->{dn} = $args{dn}
		: croak 'dn not defined';

        defined $args{ucs}
		? weaken($self->{ucs} = $args{ucs})
		: croak 'ucs not defined';

        my %attr = %{ $self->{ucs}->resolve_dn(
					dn => $self->{dn}
				)->{outConfig}->{faultInst}};

        while ( my ($k, $v) = each %attr ) { $self->{$k} = $v }

        return $self
}

{
        no strict 'refs';

        while ( my ( $pseudo, $attribute ) = each %ATTRIBUTES ) { 
                *{ __PACKAGE__ . '::' . $pseudo } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }   

        foreach my $attribute ( @ATTRIBUTES ) {
                *{ __PACKAGE__ . '::' . $attribute } = sub {
                        my $self = shift;
                        return $self->{$attribute}
                }   
        }   
}

1;

__END__

=pod

=head1 NAME

Cisco::UCS::Fault - Class for operations with Cisco UCS fault instances.

=head1 SYNOPSIS

  foreach my $error ( $ucs->get_errors ) {
    print 	"-"x50 . "\n" .
		"Error		: " . $error->id . "\n" . 
		"Created	: " . $error->created . "\n" .
		"Severity	: " . $error->severity . "\n" .
		"Description	: " . $error->desc . "\n";
  }
  
=head1 DESCRIPTION

Cisco::UCS::Fault is a class providing operations with Cisco UCS fault 
instances (errors).

Note that you are not supposed to call the constructor yourself, rather 
Cisco::UCS::Fault objects are created for you automatically by calls to 
methods in Cisco::UCS.

=head1 METHODS

=head2 ack

Returns the acknowledgement state of the specified error.

=head2 code

Returns the internal error code of the specified error.

=head2 cause

Returns the cause of the specified error.

=head2 created

Returns the creation timestamp of the specified error.

=head2 desc

Returns a description of the specified error.

=head2 dn

Returns a distinguished name of the specified error in the UCSM information 
management heirarchy.

=head2 id

Returns a ID of the specified error.

=head2 highest_severity

Returns the highest severity classification the specified error reached.

=head2 last_transition

Returns a last transition timestamp of the specified error.

=head2 original_severity

Returns the original severity classification the specified error.

=head2 previous_severity

Returns the severity classification the specified error prior to the most 
recent transition.

=head2 occur

Returns the number of occurences for the specified error.

=head2 rule

Returns the rule that triggered the specified error.

=head2 severity

Returns the severity of the specified error.

=head2 tags

Returns the tags associated with the specified error.

=head2 type

Returns the specified error type.

=cut

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-cisco-ucs-fault at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cisco-UCS-Fault>.  I will be 
notified, and then you'll automatically be notified of progress on your bug as 
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cisco::UCS::Fault

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cisco-UCS-Fault>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cisco-UCS-Fault>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cisco-UCS-Fault>

=item * Search CPAN

L<http://search.cpan.org/dist/Cisco-UCS-Fault/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
