package Dancer::SearchApp;
use strict;
use File::Basename 'basename';
use Dancer;
use Search::Elasticsearch::Async;
use URI::Escape 'uri_unescape';
use URI::file;
#use Search::Elasticsearch::TestServer;

use Dancer::SearchApp::Defaults 'get_defaults';

use Dancer::SearchApp::Entry;
use Dancer::SearchApp::HTMLSnippet;    

use vars qw($VERSION $es %indices);
$VERSION = '0.06';

=head1 NAME

Dancer::SearchApp - A simple local search engine

=head1 SYNOPSIS

=head1 QUICKSTART

Also see L<Dancer::SearchApp::Installation>.

  cpanm --look Dancer::SearchApp
  
  # Install prerequisites
  cpanm --installdeps .

  # Install Elasticsearch https://www.elastic.co/downloads/elasticsearch
  # Start Elasticsearch
  # Install Apache Tika from https://tika.apache.org/download.html into jar/

  # Launch the web frontend
  plackup --host 127.0.0.1 -p 8080 -Ilib -a bin\app.pl

  # Edit filesystem configuration
  cat >>fs-import.yml
  fs:
    directories:
        - folder: "C:\\Users\\Corion\\Projekte\\App-StarTraders"
          recurse: true
          exclude:
             - ".git"
        - folder: "t\\documents"
          recurse: true

  # Collect some content
  perl -Ilib -w bin/index-filesystem.pl -f

  # Search in your browser

=head1 CONFIGURATION

Configuration happens through config.yml

  elastic_search:
    home: "./elasticsearch-2.1.1/"
    index: "dancer-searchapp"

The Elasticsearch instance to used can also be passed in C<%ENV>
as C<SEARCHAPP_ES_NODES>.

=cut

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my $config = get_defaults(
    env      => \%ENV,
    config   => config(),
    #defaults => \%
    names => [
        ['elastic_search/index' => 'elastic_search/index' => 'SEARCHAPP_ES_INDEX', 'searchapp'],
        ['elastic_search/nodes' => 'elastic_search/nodes' => 'SEARCHAPP_ES_NODES', 'localhost:9200'],
    ],
);

# A small helper subroutine that adds some API headers that result in
# the API not being interpretable as pages to be displayed by a browser
sub add_api_headers {
    header 'Content-Disposition' => 'attachment; filename="1.txt"';
    header 'X-Content-Type-Options' => 'nosniff';
};

sub search {
    if( ! $es ) {
        my $nodes = $config->{elastic_search}->{nodes};
        $nodes = [split /,/, $nodes] # our config system doesn't provide for lists...
            unless ref $nodes;
        $es = Search::Elasticsearch->new(
            nodes => $nodes,
        );
    };
    
    $es
};

$Template::Stash::PRIVATE = $Template::Stash::PRIVATE = 1;

get '/' => sub {
    # Later, separate out the code paths between
    # search and index page only, to serve the index
    # page as a static file
    
    my $statistics;
    my $results;
    
    my $from = params->{'from'} || 0;
    $from =~ s!\D!!g;
    my $size = params->{'size'} || 25;
    $size =~ s!\D!!g;
    my $search_term = params->{'q'};
    
    if( defined $search_term) {
        
        #warning "Reading ES indices\n";
        %indices = %{ search->indices->get({index => ['*']}) };
        #warning $_ for sort keys %indices;

        my @restrict_type;
        my $type;
        if( $type = params->{'type'} and $type =~ m!([a-z0-9+-]+)/[a-z0-9+-]+!i) {
            #warn "Filtering for '$type'";
            @restrict_type = (filter => { term => { mime_type => $type }});
        };
        
        my $sanitized_search_term = $search_term;
        # Escape colons, as they're special in search queries...
        $sanitized_search_term =~ s!([:\\])!\\$1!g;
        
        # Move this to an async query, later
        my $index = $config->{elastic_search}->{index};
        $results = search->search(
            # Wir suchen in allen Sprachindices
            index => [ grep { /^\Q$index\E/ } sort keys %indices ],
            body => {
                from => $from,
                size => $size,
                query => {
                    # multi_match => { ... grep for the non-autocomplete stuff, and include the boosters
                    bool => {
                        must => {
                            query_string => {
                                query => $search_term,
                                fields => ['title','folder','content', 'author'] #'creation_date'] 
                            },
                        },
                        @restrict_type,
                    },
                },
                sort => {
                    _score => { order => 'desc' },
                },
               "highlight" => {
                    "pre_tags" => '<b>',
                    "post_tags" => '</b>',
                    "fields" => {
                    # we want the whole content so we can strip it down
                    # ourselves:
                        "content" => {"number_of_fragments" => 0},
                        #"content" => {}
                    }
                }
            }
        );
        
        #warn Dumper $results->{hits};
    } else {
        # Update the statistics
        #$statistics = search->search(
        #    search_type => 'count',
        #    index => config->{index},
        #    body        => {
        #        query       => {
        #            match_all => {}
        #        }
        #    }
        #);
        #warn Dumper $statistics;
    };
    
    if( $results ) {
        for( @{ $results->{ hits }->{hits} } ) {
            $_->{source} = Dancer::SearchApp::Entry->from_es( $_ );
            for my $key ( qw( id index type )) {
                $_->{$key} = $_->{"_$key"}; # thanks, Template::Toolkit
            };
            
        };
    };
    
    if( $results and exists params->{lucky}) {
        my $first = $results->{ hits }->{hits}->[0];
        
        if( $first ) {
            my( $index, $type, $id ) = @{$first}{qw(index type id)};
            warn "Redirecting/reproxying first document";
            if( $type eq 'http' ) {
                return
                    redirect $id
            } else {
                my $doc = $first->{source};
                my $local = URI::file->new( $id )->file;
                return
                    reproxy( $doc, $local, 'Inline',
                        index => $index,
                        type => $type,
                );
            }
        };
    } else {

        if( $results and $results->{hits} and $results->{hits}->{hits} and $results->{hits}->{hits}->[0]->{highlight}) {
            # Rework the result snippets to show only the highlighted stuff, together
            # with the appropriate page number if available
            for my $document (@{ $results->{hits}->{hits} }) {
                my $html = $document->{highlight}->{content}->[0];
                my @show = Dancer::SearchApp::HTMLSnippet->extract_highlights(
                    html => $html,
                    max_length => 300,
                );

                # Find the PDF page numbers from Tika
                for my $s (@show) {
                    $s->{page} = () = (substr($html,0,$s->{start}) =~ /<div class="page"/g);
                };

                $document->{highlight}->{content} =
                    [map {
                           +{ snippet => substr( $html, $_->{start}, $_->{length} ),
                             page     => $_->{page},
                           }
                         } @show
                    ];
            };
        };
    
        template 'index', {
                results => ($results ? $results->{hits} : undef ),
                params => {
                    q    => $search_term,
                    from => $from,
                    size => $size,
                },
        };
    };
};

# Show (cached) elements
get '/cache/:index/:type/:id' => sub {
    my $index = params->{index};
    my $type = params->{type};
    my $id = uri_unescape( params->{id} );
    my $document = retrieve($index,$type,$id);
    #warn $document->basic_mime_type;
    
    $document->{type} = $type;
    $document->{index} = $index;
    
    if( $document ) {
        return template 'view_document', {
            result => $document,
            backlink => scalar( request->referer ),
            # we should also save the page offset...
        }
    } else {
        status 404;
        return <<SORRY
        That file does (not) exist anymore in the index.
SORRY
        # We could delete that item from the index here...
        # or schedule reindexing of the resource?
    }
};

# Reproxy elements from disk
sub reproxy {
    my( $document, $local, $disposition, %options ) = @_;
    
    # Now, if the file exists both in the index and locally, let's reproxy the content
    if( $document and -f $local) {
        status 200;
        content_type( $document->mime_type );
        header( "Content-Disposition" => sprintf '%s; filename="%s"', $disposition, basename $local);
        my $abs = File::Spec->rel2abs( $local, '.' );
        open my $fh, '<', $local
            or die "Couldn't read local file '$local': $!";
        binmode $fh;
        local $/;
        <$fh>
        
    } else {
        status 404; # sorry
        return <<SORRY
        That file does (not) exist anymore or is currently unreachable
        for this webserver. We'll need to implement 
        cleaning up the index from dead items.
SORRY
        # We could delete that item from the index here...
        # Or schedule reindexing of the resource?
    }
};

sub retrieve {
    my( $index, $type, $id ) = @_;
    my $document;
    if( eval {
        $document = search->get(index => $index, type => $type, id => $id);
        1
    }) {
        my $res = Dancer::SearchApp::Entry->from_es($document);
        return $res
    } else {
        warn "$@";
    };
    # Not found in the Elasticsearch index
    return undef
}

get '/open/:index/:type/:id' => sub {
    my $index = params->{index};
    my $type = params->{type};
    my $id = uri_unescape params->{id};
    my $document = retrieve($index,$type,$id);
    if( $type eq 'http' ) {
        return
            redirect $id
    } else {
        my $local = URI::file->new( $id )->file;
        return
        reproxy( $document, $local, 'Attachment',
            index => $index,
            type => $type,
        );
    }
};

get '/inline/:index/:type/:id' => sub {
    my $index = params->{index};
    my $type = params->{type};
    my $id = uri_unescape params->{id};
    my $document = retrieve($index,$type,$id);
    
    my $local;
    if( 'http' eq $type ) {
        $document->content
    } else {
        $local = URI::file->new( $id )->file;
    };
    
    reproxy( $document, $local, 'Inline',
        index => $index,
        type => $type,
    );
    
};

# This is likely a really bad design choice which I will regret later.
# Most likely, manually encoding to JSON would be the saner approach
# instead of globally setting a serializer for all routes.
set 'serializer' => 'JSON';

get '/suggest/:query.json' => sub {
    my( $q ) = params->{query};
    #warn "Completing '$q'";
    
    return [] unless $q and $q =~ /\S/;
    
    # Strip leading/trailing whitespace, Justin Case
    $q =~ s!^\s+!!;
    $q =~ s!\s+$!!;

    # Reinitialize indices
    # Some day, we could cache that/not refresh them all the time    
    %indices = %{ search->indices->get({index => ['*']}) };

    my @restrict_type;
    my $type;
    if( $type = params->{'type'} and $type =~ m!([a-z0-9+-]+)/[a-z0-9+-]+!i) {
        #warn "Filtering for '$type'";
        @restrict_type = (filter => { term => { mime_type => $type }});
    };
        
    # This should be centralized
    # This is "did you mean X"
    #my @fields = ('title','content', 'author');
    
    # Query all suggestive fields at once:
    #my %suggest_query = map {;
    #    "my_suggestions_$_" => {
    #        phrase  => {
    #            field => "$_.autocomplete",
    #            #field => "$_",
    #            #text => $q,
    #        }
    #    }
    #} @fields;
    
    my @fields = ('title_suggest');
    
    # Query all suggestive fields at once:
    my %suggest_query = map {;
        "my_completions_$_" => {
            phrase  => {
                field => "title_suggest",
                #field => "$_",
                #text => $q,
            }
        }
    } @fields;

    #warn Dumper \%suggest_query;
    
    # Move this to an async query, later
    my $index = $config->{elastic_search}->{index};
    my $results = search->suggest(
        index => [ grep { /^\Q$index\E/ } sort keys %indices ],
        body    => {
            foo => {
                text  => $q,
                completion => {
                    field => 'title_suggest',
                    "fuzzy" => { "fuzziness" => 2 }, # edit distance of 2
                }
            }
            #%suggest_query
        }
    );
    
    #warn Dumper $results;
    
    my %suggestions;
    my @res = map {; +{
                  tokens => [split //, $_->{text}],
                  value => $_->{text},
                  url   => $_->{_source}->{url},
              } }
              sort { $b->{_score} <=> $a->{_score} || $b cmp $a } # sort by score+asciibetically descending
              map { $_->{options} ? @{ $_->{options} } : () } # unwrap again
              map { @$_ } # unwrap
              grep { ref $_ eq 'ARRAY' } values %$results
              ;
    
    add_api_headers;
    return \@res;
};

true;

__END__

=head1 SECURITY CONSIDERATIONS

=head2 Dancer::SearchApp

This web front end can serve not only the extracted content but also
the original files from your hard disk. Configure the file system crawler
to index only data that you are comfortable with sharing with whoever
gets access to the web server.

Consider making the web server only respond on requests originating from
127.0.0.1:

  plackup --host 127.0.0.1 -p 8080 -Ilib -a bin\app.pl

=head2 Elasticsearch

Elasticsearch has a long history of vulnerabilities and has little to no
concept of information segregation. This basically means that anything that
can reach Elasticsearch can read all the data you stored in it.

Configure Elasticsearch to only respond to localhost or to queries from
within a trusted network, like your home network.

Note that leaking a copy of the Elasticsearch search index is almost as
bad as leaking a copy of the original data. This is especially true if you
look at backups.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/dancer-searchapp>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 TALKS

I've given a talk about this module at Perl conferences:

L<German Perl Workshop 2016, German|http://corion.net/talks/dancer-searchapp/dancer-searchapp.de.html>

L<Video on Youtube, German|https://www.youtube.com/watch?v=X4j5LgmfgZY>

L<YAPC::Europe 2016, Cluj, English|http://corion.net/talks/dancer-searchapp/dancer-searchapp.en.html>

L<Video on Youtube, English|https://www.youtube.com/watch?v=TXSM-Izmia8>

=for html
<iframe title="YouTube video player" class="youtube-player" type="text/html" 
width="640" height="390" src="http://www.youtube.com/embed/TXSM-Izmia8"
frameborder="0" allowFullScreen></iframe>

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dancer-SearchApp>
or via mail to L<dancer-searchapp-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut