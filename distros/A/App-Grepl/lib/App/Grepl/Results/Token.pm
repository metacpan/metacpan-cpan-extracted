package App::Grepl::Results::Token;

use warnings;
use strict;
use App::Grepl;

use base 'App::Grepl::Base';
use Scalar::Util 'reftype';

=head1 NAME

App::Grepl::Results::Token - App::Grepl result by token type.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

OO interface to grepl's individual results.

    use App::Grepl::Results::Token;

    my $found = App::Grepl::Results->new( {
        file     => $file,
    } );
    $found->add_results( $token => \@results );

    print $found->file, "\n";
    while ( my $result = $found->next ) {
        print $result->token, "matched:\n";
        while ( my $item = $result->next ) {
            print "\t$item\n";
        }
    }

=head1 METHODS

=head2 Class Methods

=head3 C<new>

    my $grepl = App::Grepl::Results::Token->new( { 
        token   => 'pod',
        results => \@matching_pod,
    } );

=cut

sub _initialize {
    my ( $self, $arg_for ) = @_;
    $self->token( delete $arg_for->{token} );
    $self->results( delete $arg_for->{results} );
    return $self;
}

=head2 Class Methods

=head3 C<token>

 my $token = $result->token;
 $result->token($token);

Getter/setter for token type.  Will C<croak> if C<App::Grepl> does not
recognize the token type.

=cut

sub token {
    my $self = shift;
    return $self->{token} unless @_;
    my $token = shift;
    unless ( App::Grepl->handler_for($token) ) {
        $self->_croak("Do not know how to add a result for ($token)");
    }
    $self->{token} = $token;
    return $self;
}

=head3 C<results>

 my $results = $result->results;
 $result->results($results);

Getter/setter for results.  Will C<croak> if not passed an array reference.

=cut

sub results {
    my $self = shift;
    return $self->{results} unless @_;
    my $results = shift;
    unless ( 'ARRAY' eq reftype($results) ) {
        $self->_croak("Results must be an array references");
    }
    $self->{results} = $results;
    return $self;
}

=head3 C<next>

 while ( defined ( my $result = $found->next ) ) {
     ...
 }

Returns the next result found.

Note that the iterator is destructive.

=cut

sub next {
    my $self = shift;
    shift @{ $self->{results} };
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

    perldoc App::Grepl::Results::Token

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
