package Bing::Search;
use Moose 1.00;
use URI 1.54;
use URI::QueryParam;
use Carp;
use LWP::UserAgent 5.835;
use JSON 2.21;
use Bing::Search::Response;
use vars qw($VERSION);

$VERSION = "0.0005";
$VERSION = eval $VERSION if $VERSION =~ /_/;

has 'sources' => ( 
   is => 'rw',
   isa => 'ArrayRef[Bing::Search::Source]',
   predicate => 'has_sources',
   default => sub { [] }
);

has 'request_obj' => ( 
   is => 'rw',
   isa => 'URI'
);

has 'agent' => ( 
   is => 'rw',
   isa => 'LWP::UserAgent',
   default => sub {  
      LWP::UserAgent->new( agent => 'bing-search/' . $VERSION . ' libwww-perl' ) 
   }
);

has 'AppId' => ( 
   is => 'rw',
   required => 1,
   default => 'NOAPPIDPROVIDED'
);

has 'Query' => ( 
   is => 'rw',
   isa => 'Str',
   default => ''
);

has 'response' => (
   is => 'rw',
   isa => 'Bing::Search::Response'
);


sub search { 
   my $self = shift;
   my $uri;
   if( @_ ) {
      $self->add_source( { source => 'Web' } );
      $self->Query( shift @_ );
   } 
   $self->_make_uri;
   $self->agent->env_proxy;
   $uri = $self->request_obj();
   my $response = $self->agent->get( $uri );
   unless( $response->is_success ) { 
      croak "Failed request: $!";
   }
   
   my $j = JSON->new->decode( $response->content );
   $self->_parse_json( $j );
}

sub _parse_json {
   # Debugging!
   use Data::Dumper;
   my( $self, $json ) = @_;
   my $resp = Bing::Search::Response->new( data => $json );
   $self->response( $resp  );
}

sub _make_uri { 
   my ($self) = @_;
   unless( $self->has_sources ) { 
      croak "No sources means no query, yo.";
   }
   my $uri = URI->new( 'http://api.bing.net/json.aspx' );
   my @source_names;
   for my $source ( @{$self->sources} ) {
      my $req = $source->build_request;
      for my $source_key ( keys %$req ) {
         if( ref $req->{$source_key} eq 'ARRAY' ) { 
            $uri->query_param_append( $source_key => $_ ) for @{$req->{$source_key}};
         } else { 
            $uri->query_param_append( $source_key => $req->{$source_key} );
         }
      }
      push @source_names, $source->source_name;
   }
   $uri->query_param_append( 'Sources' => @source_names );
   $uri->query_param_append( 'AppId' => $self->AppId );
   $uri->query_param_append( 'Query' => $self->Query );
   $self->request_obj( $uri );
}

sub add_source { 
   my( $self, $source ) = @_;
   unless( $source->isa('Bing::Search::Source') ) { 
      croak "Not a valid source: $source";
   }
   my $source_list = $self->sources;
   push @$source_list, $source;
   $self->sources( $source_list );
}


__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search - Implements the Bing AJAX Search API

=head1 SYNOPSIS

    use Bing::Search;
    use Bing::Search::Source::Web;

    my $search = Bing::Search->new(
      AppId => '1234567890',
      Query => 'Rocks'
    );
    
    my $source = Bing::Search::Source::Web->new();

    $search->add_source( $source );

    my $response = $search->search();

    print $_->Url for @{$response->results};

=head1 DESCRIPTION

This set of modules implements most of the Bing Search API.  See the
L</"UNIMPLEMENTED BITS"> for what's missing.  This is an object-oriented
monstrosity, intended to be easily extendible when the API changes.  Since
we all know who made Bing, we B<know> that's going to change.

=head2 Really Important Note

The Bing API B<requires> an AppId.  If you intend to use the API, you must
provide an AppId.  You may obtain one by visiting L<http://www.bing.com/developers/createapp.aspx>.
Please ensure you've read the terms and whatnot.  

=head2 The Quick And Easy Way

First, create a search object.

    my $search = Bing::Search->new();

And give it your AppId.  (See L</"Really Important Note">)

    $search->AppId('1234567890');

You almost always need to be searching for something, so:

    $search->Query('rocks');

Finally, Bing needs to know where to look for your rocks.  This is done by supplying
a C<Source> object.  You can add more than one type, but try not to add the same type 
more than once.  Poor Bing gets confused.

    $search->add_source( 
      Bing::Search::Source::Web->new
    );

Once that's done, you're ready to wander out into the wilds of the internet and 
do your search.

    my $response = $search->search();

You may have to wait a second.  Sometimes the internet is slow.  But now, 
you're ready to examine your results.
   

    foreach my $result ( @{$response->results} ) { 
      print $result->Title, " -> ", $result->Url, "\n";
    }

=head1 METHODS

=over 3

=item C<search>

Does the actual searching.  Any parameters are ignored.  Returns a 
L<Bing::Search::Response> object.

=item C<AppId>

B<Required>.  Sets the AppId.  

=item C<Query>

Sets the query string.

=item C<add_source>

Accepts a L<Bing::Search::Source> object, adds it to the list of sources.

=back

There are also some methods that you probably don't want to fiddle with.  In fact,
fiddling with them might break something.  Don't do it, man!

=over 3

=item C<sources>

An arrayref of C<Bing::Search::Source::*> objects.  Try not to change this yourself.

=item C<request_obj>

A L<URI> object.  This is what ends up getting sent out over the internet.  Careful,
it changes a lot when you're not looking.

=item C<agent>

A L<LWP::UserAgent> object.  Used to make the request.  This has a default agent string 
of "bing-search/$VERSION libwww-perl"

=item C<_parse_json>

As with all methods beginning with _, don't fiddle with it.  It does what it says
on the tin.

=item C<_make_uri>

Called by C<search> to generate the URI object and fiddle with the query string.  
Again, what it says on the tin.  

=back


=head1 SOURCES

L<Bing::Search::Source> objects what what tell Bing what sort of things to look for.  
The return value of the C<search> method is a L<Bing::Search::Response> object, which 
among other things contains some L<Bing::Search::Result> objects.  The sources you 
specifiy determine what results you'll end up with.

Sources currently implemented:

L<Bing::Search::Source::Image>, L<Bing::Search::Source::InstantAnswer>,
L<Bing::Search::Source::MobileWeb>, L<Bing::Search::Source::News>,
L<Bing::Search::Source::Phonebook>, L<Bing::Search::Source::RelatedSearch>,
L<Bing::Search::Source::Spell>, L<Bing::Search::Source::Translation>,
L<Bing::Search::Source::Video>, L<Bing::Search::Source::Web>

You should consult the documentation for each source you intend on using, as some have 
various options you may find useful.  Some, like L<Bing::Search::Source::Translation>
have some required options you B<must> set.

=head2 Attributes Available to All Sources

There are some attributes available to every source.  Which each Source may
not implement each of the below, this is a key-saving technique.

=over 3

=item C<Market>

The market the search is to take place in.  See L<http://msdn.microsoft.com/en-us/library/dd251064.aspx>
for details about valid markets.  Bing will attempt to select the correct market automatically
if none is provided.  

=item C<Version>

The version of the API you wish to use.  The default is "2.1".

=item C<Adult>

Indicates how to filter "adult" content.  Per L<http://msdn.microsoft.com/en-us/library/dd251007.aspx>,
valid options are: "Off", "Moderate", and "Strict".  

=item C<UILanguage>

The langauge in which "user interface strings" are presented.  In most cases, this will
not have affect your results or use of this module.  

Valid language codes are available here:  L<http://msdn.microsoft.com/en-us/library/dd250941.aspx>.

=item C<Latitude>

Latitude for searches where location is relevant.  Valid values are between -90 and 90.

=item C<Longitude>

Similar to the Latitude option.  vcalud values are between -180 and 180.  

=item C<Radius>

For searches where a radius (for a location-based search) are relevant.  Valid values
are from 0 to 250 miles.  The default value is 5.

=item C<Options>

Options is a strange beast, in that there are several "options" that may be set or 
removed.  While you may set this directly (it is an arrayref), it's suggested that
you use the handy function written up nicely for you, C<setOptions>.  

Valid values are: B<DisableLocationDetection> and B<EnableHilighting>.  You almost 
never need to set either of these. 

=item C<setOptions>

Accepts a single parameter, the name of an option.  Optionally prefixed with a C<->, 
it will remove the option from the list.  For consistency's sake, prefixing an
option with C<+> will add the option to the list.  C<+> is not required 
to add an option.

=back


=head1 RESULTS

L<Bing::Search::Result> objects are what you've been looking for.  They contain the 
well-parsed data from your query.  To determine what methods are available to you, 
you should check each object's type.  I suggest using the built-in C<ref> function.

A notable exception is the L<Bing::Search::Result::Errors> result.  It occurs whenever
Bing spits out an error of some sort.  Remember to check for it if things aren't
doing what you think they should.

Currently implemented Results:

L<Bing::Search::Result::Errors>, L<Bing::Search::Result::Image>, 
L<Bing::Search::Result::Image::Thumbnail>, L<Bing::Search::Result::MobileWeb>, 
L<Bing::Search::Result::InstantAnswer>, L<Bing::Search::Result::InstantAnswer::Encarta>, 
L<Bing::Search::Result::InstantAnswer::FlighStatus>, L<Bing::Search::Result::News>, 
L<Bing::Search::Result::Phonebook>, L<Bing::Search::Result::RelatedSearch>, 
L<Bing::Search::Result::Spell>, L<Bing::Search::Result::Translation>, 
L<Bing::Search::Result::Video>, L<Bing::Search::Result::Video::StaticThumbnail>, 
L<Bing::Search::Result::Web>

=head1 UNIMPLEMENTED BITS

I got lazy and opted to not bother implementing a few small bits of the API,
mostly because I got distracted by video games or a shiny piece of metal.  
Future versions, if I ever get around to it, may have these bits implemented.

Also, patches welcome.

=head2 Currently unimplemented

=over 3

=item The C<AdSource> Source is not implemented.  This is a design decision.

=item In the Video and Image's C<Filter> sections, the custom Height and Width
fitlers are not implemented.  The pre-defined filters remain.

=back 

=head1 BUGS

Oh yeah.  And I bet these docs are full of typos and other broken 
things, too.  I dare you to find them!  Patches welcome.

=head1 SEE ALSO

L<Moose>, L<URI>, L<LWP::UserAgent>, L<DateTime>, L<DatTime::Duration>, L<JSON>

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 CONTRIBUTORS

=over 3

=item Peter Edwards L<peter@dragonstaff.co.uk>

=back


=head1 LICENSE

This library is free software; you may redistribute and/or modify it under the same
terms as Perl itself.
