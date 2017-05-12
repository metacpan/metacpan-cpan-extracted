package App::Grepl::Results;

use warnings;
use strict;
use App::Grepl;
use App::Grepl::Results::Token;

use base 'App::Grepl::Base';
use Scalar::Util 'reftype';

=head1 NAME

App::Grepl::Results - PPI-powered grep results object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

OO interface to grepl's results

    use App::Grepl::Results;

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

    my $grepl = App::Grepl::Results->new( { file => $file } );

=cut

sub _initialize {
    my ( $self, $arg_for ) = @_;

    $self->file( delete $arg_for->{file} );
    $self->{results} = [];
    return $self;
}

=head2 Instance Methods

=head3 C<file>

 my $file = $result->file;
 $result->file($file);

Get or set the filename the results pertain to.  Will C<croak> if the file
does not exist.

=cut

sub file {
    my $self = shift;
    return $self->{file} unless @_;
    my $file = shift;
    unless ( -e $file ) {
        $self->_croak("Cannot find file ($file)");
    }
    $self->{file} = $file;
    return $self;
}

=head3 C<have_results>

 if ( $found->have_results ) { ... }

Boolean accessor indicating if we have results for the search.

=cut

sub have_results { return scalar @{ shift->{results} } }

=head3 C<add_results>

 $found->add_results( 'heredoc' => \@array_ref_of_strings );

Add results to the result object. Takes two arguments:

=over 4

=item * token

This should be a string representing the result type (e.g., C<comment>,
C<pod>, etc).

Will C<croak> if C<App::Grepl> does not recognize the result type.

=item * results

This should be an array reference of strings.  These are the actual results.

Will C<croak> if something other than an array reference is passed.

=back

=cut

sub add_results {
    my ( $self, $elem, $results ) = @_;
    push @{ $self->{results} } => App::Grepl::Results::Token->new( {
        token => $elem,
        results => $results,
    } );
    return $self;
}

=head3 C<filename_only>

 if ( $result->filename_only ) {
     ...
 }
 $result->filename_only(1);

A boolean getter/setter for whether or not results are 'filename only'.  These
are returned to indicated that a file matched the criteria.  The actual
matches will not be returned.

=cut

sub filename_only {
    my $self = shift;
    return $self->{filename_only} unless @_;
    my $filename_only = shift;
    $self->{filename_only} = $filename_only;
    return $self;
}

=head3 C<next>

 while ( defined ( my $result = $found->next ) ) {
     ...
 }

Returns the next result found.

Will C<croak> if results are requested from a 'filename_only' object.

Note that the iterator is destructive.

=cut

sub next {
    my $self = shift;
    if ( $self->filename_only ) {
        $self->_croak("No results available for 'filename_only' results objects");
    }
    my $next = shift @{ $self->{results} };
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

    perldoc App::Grepl::Results

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
