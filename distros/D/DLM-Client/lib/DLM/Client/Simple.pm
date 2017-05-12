package DLM::Client::Simple;

use warnings;
use strict;
use Carp qw/croak/;

use DLM::Client qw/LKM_EXMODE LKM_PRMODE LKF_NOQUEUE LKF_CONVERT/;

use base 'Exporter';
our @EXPORT=(qw/dlm_lock dlm_unlock/);
=head1 NAME

DLM::Client::Simple - Simplified interface to DLM::Client

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
 

=head1 SYNOPSIS

Quick summary of what the module does.


    use DLM::Client::Simple;

    if ( dlm_lock('lock_name', 'EXCL') ) {
        #do something exclusively
    } else {
        die $!;
    }
    ...
    dlm_unlock('lock_name') or die $!;

=head1 EXPORT

dlm_lock

dlm_unlock

=head1 FUNCTIONS

=head2 dlm_lock( $LOCK_NAME, $LOCK_MODE, $IS_NONBLOCKING )

    $LOCK_NAME - can be any string less than 64 bytes

    $LOCK_MODE - can be 'SHRD' or 'EXCL'

    $IS_NONBLOCKING - if true then funtion does not wait for lock

    RETURNS TRUE if lock was granted

    Repetive calls update lock

=cut

my %LOCKS;

sub dlm_lock {
    my ($name, $mode, $is_nb) = @_;
    
    croak 'Missed lock name!' unless $name;

    if ( $mode eq 'EXCL' ) {
        $mode = LKM_EXMODE
    } 
    elsif ( $mode eq 'SHRD' ) {
        $mode = LKM_PRMODE
    }
    else {
        croak 'Unsupported lock mode!';
    }
    
    my $flags = $is_nb ? LKF_NOQUEUE : 0;
    $flags |= LKF_CONVERT if exists $LOCKS{$name};
    
    my $lock_id = $LOCKS{$name} || 0;

    if ( DLM::Client::lock_resource( $name, $mode, $flags, $lock_id) == 0 ){
        $LOCKS{$name} = $lock_id;
        return $lock_id;
    }
    
    return;
}

=head2 dlm_unlock( $LOCK_NAME )

    $LOCK_NAME - unlocks lock with name $LOCK_NAME

    RETURNS TRUE on success

=cut

sub dlm_unlock {
    my ($name) = @_;
    
    croak 'Missed lock name!' unless $name ;

    if ( defined $name and $LOCKS{$name} and DLM::Client::unlock_resource( $LOCKS{$name} ) == 0 ) {
        delete $LOCKS{$name};
        return 1;
    } 
    
    return
}

=head1 AUTHOR

koorchik, C<< <koorchik at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dlm-client-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DLM-Client-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DLM::Client::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DLM-Client-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DLM-Client-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DLM-Client-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/DLM-Client-Simple>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 koorchik, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DLM::Client::Simple
