package Bing::Search::Result::InstantAnswer;
use Moose;
use Bing::Search::Result::InstantAnswer::Encarta;
use Bing::Search::Result::InstantAnswer::FlightStatus;
extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';

with qw(
   Bing::Search::Role::Result::Url
   Bing::Search::Role::Result::Attribution
   Bing::Search::Role::Result::ContentType
   Bing::Search::Role::Result::Title
);

has 'Answer' => ( 
   is => 'rw',
);

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $results = delete $data->{InstantAnswerSpecificData};
   my $obj;
   if( exists $results->{Encarta} ) { 
      $obj = Bing::Search::Result::InstantAnswer::Encarta->new;
      $obj->data( $results->{Encarta} );
   } elsif( exists $results->{FlightStatus} ) { 
      $obj = Bing::Search::Result::InstantAnswer::FlightStatus->new;
      $obj->data( $results->{FlightStatus} );
   } 
   $obj->_populate;
   $self->Answer( $obj );
   
};

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::InstantAnswer - Instant answers from Bing

=head1 METHODS

=over 3

=item C<Url>

A L<URI> object linking to a more detailed answer, or at least,
the source material.

=item C<Attribution>

The "source" for the instant answer.  Nto always present.

=item C<ContentType>

The type of instant answer you got.  Is generally an "Encarta." or "FlightStatus." 
type.  

=item C<Title>

For most cases, the title is also the query, as understood by Bing.  

=item C<Answer>

Contains a specific object with your answer.  Depending on the type
of answer, it may be either a L<Bing::Search::Result::InstantAnswer::Encarta>
or L<Bing::Search::Result::InstantAnswer::FlightStatus> object.  You 
should use C<ref> to check which one you got.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.
