package Dancer::SearchApp::IndexSchema;
use strict;
use Exporter 'import';
use Data::Dumper;
use Promises 'deferred';

use JSON::MaybeXS;
my $true = JSON->true;
my $false = JSON->false;

=head1 NAME

Dancer::SearchApp::IndexSchema - schema definition for the Elasticsearch index

Consider maybe extending this so different items (like Tweets, RSS)
have different fields instead of mushing all metadata into the same schema

=cut

use vars qw(@EXPORT_OK $VERSION @types);
$VERSION = '0.06';
@EXPORT_OK = qw(create_mapping multilang_text find_or_create_index %indices %analyzers );

# Maybe we should move away from the type so we can rely on just the id of a document
@types = (qw(file mail http));

=head2 Boost direct matches, still allow synonyms

PUT /<index_name>/<type_name>/_mapping
{
  "<type>": {
    "properties": {
      "title": {
        "type": "string",
        "fields": {
          "exact": {
            "type": "string",
            "index": "not_analyzed"
          },          
          "synonym": {
            "type": "string",
            "index": "analyzed",
            "analyzer": "synonym_analyzer"
          },
          "stemmed": {
            "type": "string",
            "index": "analyzed",
            "analyzer": "stemming_analyzer"
          }
        }
      }
    }
  }
}

And the following query should match as you wish :

POST /<index_name>/<type_name>/_search
{
  "query": {
    "multi_match": {
      "query": "injury",
      "fields": [
        "title.exact^3",
        "title.synonym^2",
        "title.stemmed"
      ]
    }
  }
}

=cut

# Datenstruktur für ES Felder, deren Sprache wir nicht kennen
sub multilang_text($$) {
    my($name, $analyzer)= @_;
    return { 
          "type" => "text",

          # Also for the suggestion box
          "fields" =>  {
              $name => {
                   "type" => "text",
                   "analyzer" => $analyzer,
                   "index" => "analyzed",
                    "store" => $true,
              },
              "${name}_synonyms" => {
                   "type" => "text",
                   # This should be configurable per language/synonyms
                   "analyzer" => 'searchapp_synonyms_en',
                   "index" => "analyzed",
                    "store" => $true,
              },
              
              # This is misnamed - it's more the autocorrect filter
              # usable for "did you mean XY" responses
              "autocomplete" => {
                  "analyzer" => "analyzer_shingle",
                  "search_analyzer" => "analyzer_shingle",
                  #"index_analyzer" => "analyzer_shingle",
                  "type" => "text",
                   "store" => $true,
              },
          }
    };
};

=head2 C<< create_mapping >>

Defines a Dancer::SearchApp index. This is currently the following
specification:

        "properties" => {
            "url"        => { type => "text" }, # file://-URL
            "title"      => multilang_text('title',$analyzer),
            "author"     => multilang_text('author', $analyzer),
            "content"    => multilang_text('content',$analyzer),
            'mime_type'  => { type => "string" }, # text/html etc.
            "creation_date"    => {
              "type"  =>  "date",
              "format" => "yyyy-MM-dd HH:mm:ss",
            },
        },

=cut

sub create_mapping {
    my( $analyzer ) = @_;
    $analyzer ||= 'english';
    my $mapping = {
        "properties" => {
            "url"        => { type => "text" }, # file://-URL
            "title"      => multilang_text('title',$analyzer),

            # Automatic (title) completion to their documents
            # https://www.elastic.co/blog/you-complete-me
            "title_suggest" => {
                  "type" => "completion",
                  #"payloads" => $true,
                  # Also add synonym filter
                  # Also add lowercase anaylzer
            },
            
            "author"     => multilang_text('author', $analyzer),
            "content"    => multilang_text('content',$analyzer),
            "folder"     => {
                  "type" => "text",
                  "analyzer" => $analyzer,
                  # Some day I'll know how to have a separate tokenizer per-field
                  # "tokenizer" => "path_hierarchy",
            },
            # This could also be considered a path_hierarchy
            'mime_type'  => { type => "text", index => 'not_analyzed' }, # text/html etc.
            "creation_date"    => {
              "type"  =>  "date",
              "format" => "yyyy-MM-dd HH:mm:ss",
            },
        },
    };
};

=head2 C<< find_or_create_index >>

  my $found = find_or_create_index( $es, $index_name, $lang, $type );
  $found->then( sub {
      my( $name ) = @_;
      print "Using index '$name'\n";
  });

Returns the full name for the index C<$index_name>, concatenated with the
language. The language is important to chose the correct stemmer. Existing
indices will be cached in the package global variable C<%indices>.

=cut

use vars qw(%pending_creation %indices %analyzers );
sub find_or_create_index {
    my( $e, $index_name, $lang, $type ) = @_;
    
    my $res = deferred;
    
    my $full_name = "$index_name-$lang";
    #warn "Initializing deferred for $full_name";
    #warn join ",", sort keys %indices;
    if( ! $indices{ $full_name }) {
        #warn "Checking for '$full_name'";
        $e->indices->exists( index => $full_name )
        ->then( sub{
            if( $_[0] ) { # exists
                #warn "Full name: $full_name";
                $res->resolve( $full_name );

            # index creation in progress
            } elsif( $pending_creation{ $full_name }) {
                #warn "push Pending";
                push @{ $pending_creation{ $full_name } }, $res;

            # we need to create it ourselves
            } else {
                $pending_creation{ $full_name } = [];
                #warn "Creating";
                my $mapping = create_mapping($analyzers{$lang});
                #warn Dumper $mapping;
                my @typemap = map { $_ => $mapping } @types;
                $e->indices->create(index=>$full_name,
                    body => {
                    settings => {
                        analysis => {
                            analyzer => {
                                "analyzer_shingle" => {
                                   "tokenizer" => "standard",
                                   "filter" => ["standard", "lowercase", "filter_stop", "filter_underscores", "filter_shingle"],
                                },
                                # Synonyms should be configurable per language
                                "searchapp_synonyms_en" => {
                                   "tokenizer" => "standard",
                                   "filter" => ["standard", "lowercase", "searchapp_synonyms_en"],
                                },
                                "searchapp_en" => {
                                   "tokenizer" => "standard",
                                    "filter" => ["filter_stem_${lang}"],
                                },
                   #"filter" => ['standard','lowercase',"${analyzer}_stemmer"],
                            },
                            "filter" => {
                                # Synonyms should be configurable per language
                                "searchapp_synonyms_en" => {
                                    "type" =>  "synonym", 
                                    # relative to the ES config directory
                                    "synonyms_path" => "synonyms/synonyms_en.txt"
                                },
                                "filter_stem_${lang}" => {
                                    type => "stemmer",
                                    name => $lang,
                                },
                                "filter_underscores" => {
                                   "type" => "stop",
                                   "stopwords" => ['_'],
                                },
                                "filter_stop" => {
                                   "type" => "stop",
                                   # We'll need another filter to filter out the underscores...
                                },
                                "filter_shingle" => {
                                   "type" =>"shingle",
                                   "max_shingle_size" => 5,
                                   "min_shingle_size" => 2,
                                   "output_unigrams" => $true,
                                },
                                "ngram" => {
                                  "type" => "ngram",
                                  "min_gram" => 2,
                                  "max_gram" => 15, # long enough even for German
                                },
                            },
                        },
                        
                        mapper => { dynamic => $false }, # this is "use strict;" for ES
                        "number_of_replicas" => 0,
                    },
                    "mappings" => {
                        # Hier muessen/sollten wir wir die einzelnen Typen definieren
                        # https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html
                        #$type => $mapping,
                        # One schema fits all
                        @typemap,       
                    },
                })->then(sub {
                    my( $created ) = @_;
                    #warn "Full name: $full_name";
                    $res->resolve( $full_name );
                    for( @{ $pending_creation{ $full_name }}) {
                        $_->resolve( $full_name );
                    };
                    delete $pending_creation{ $full_name };
                }, sub { warn "Couldn't create index $full_name: " . $_[0]->{text}  });
            };
        });
    } else {
        #warn "Cached '$full_name'";
        $res->resolve( $full_name );
    };
    return $res->promise
};

1;
=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/dancer-searchapp>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 TALKS

I've given a talk about this module at Perl conferences:

L<German Perl Workshop 2016, German|http://corion.net/talks/dancer-searchapp/dancer-searchapp.html>

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