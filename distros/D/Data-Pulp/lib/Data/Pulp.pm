package Data::Pulp;

use warnings;
use strict;

=head1 NAME

Data::Pulp - Pulp your data into a consistent goop

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Pulp;

    my $pulper = pulper
        case { $_ eq 'apple' } then { 'APPLE' }
        case { $_ eq 'banana' }
        case { $_ eq 'cherry' } then { 'CHERRY' }
        case { ref eq 'SCALAR' } then { 'SCALAR' }
        empty { 'empty' }
        nil { 'nil' }
        case { m/xyzzy/ } then { 'Nothing happens.' }
        default { croak "Don't understand $_" }
    ;

    $pulper->pulp( 'apple' )        # APPLE
    $pulper->pulp( 'banana' )       # CHERRY
    $pulper->pulp( 'xyyxyzzyx' )    # Nothing happens.
    $pulper->pulp( undef )          # nil
    $pulper->pulp( '' )             # empty
    $pulper->pulp( '1' )            # Throw an exception: Don't understand 1

    # You can also operate on an array or hash

    my $set = $pulper->prepare( [ qw/apple banana cherry/, '', undef, qw/xyzzy xyyxyzzyx grape/ ] )

    $set->all       # APPLE, CHERRY, CHERRY, empty, nil, Nothing happens ...
    $set->first     # APPLE
    $set->last      # Throw an exception: Don't understand grape

=head1 DESCRIPTION

Data::Pulp is a tool for coercing and/or validating input data. Instead of doing this:

    if ( defined $value ) {
        if ( ref $value eq ... ) {
            ...
        }
        elsif ( $value =~ m/.../ ) {
            ...
        }
        ...
    }
    else {
    }

You can do something like this:

    my $pulper = pulper
        case { $_ eq ... }  then { ... }
        case { m/.../ }     then { ... }
        nil { ... # Do action if value is undefined }
    ;

    $pulper->pulp( $value )

A pulper can act transparently on a single value, ARRAY, or HASH:

    my $set = $pulper->prepare( $value ) # A single value list
    my $set = $pulper->prepare( [ $value, ... ] )
    my $set = $pulper->prepare( { key => $value, ... } ) # Throws away the keys, basically

So, given a subroutine:

    sub method {
        my $data = shift;
        # $data could be a single value, or an array, or even a hash
        my $set = $pulper->prepare( $data )
        my @data = $set->all # Get all the data coerced how you want
                             # or throw an exception if something bad is encountered

        ...
    }

=cut

use Moose();
use Data::Pulp::Carp;

sub EXPORT () {qw/
    case if_value if_type if_object
    then empty nil default
    pulper
/}

use Sub::Exporter -setup => {
    exports => [
        EXPORT,
    ],
    groups => {
        default => [ EXPORT ],
    },
};

use Data::Pulp::Pulper;

sub case (&@) { return case => @_ }
sub if_value (&@) { return if_value => @_ }
sub if_type (&@) { return if_type => @_ }
sub if_object (&@) { return if_object => @_ }
sub then (&@) { return then => @_ }
sub empty (&@) { return empty => @_ }
sub nil (&@) { return nil => @_ }
sub default (&@) { return default => @_ }

sub pulper {
    shift if $_[0] eq __PACKAGE__;
    return Data::Pulp::Pulper->parse( @_ );
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-pulp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Pulp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Pulp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Pulp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Pulp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Pulp>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Pulp/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Data::Pulp
