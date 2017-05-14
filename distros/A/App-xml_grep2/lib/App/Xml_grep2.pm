#!/usr/bin/perl 

use strict;
use warnings;

package App::Xml_grep2;

use XML::LibXML;
use File::Find::Rule;

sub new
  { my( $class, $defaults, $options)= @_;

    my $self= bless {%$defaults, %$options}, $class;

    $self->check_options;

    $self->{ns_column} = $self->{ns}? "$self->{ns}:" : "";
 
    my %parser_option;
    if( $self->{catalog}) { $parser_option{catalog}= $self->{catalog}; }
    if( $self->{xl})
      { _use( "XML::Liberal" => "needed for xl option");
        $self->{parser}= XML::Liberal->new( LibXML => %parser_option);
      }
    else
      { $self->{parser}= XML::LibXML->new( %parser_option); }

   

    return $self;
  }

sub check_options
  { my $self= shift;
    # things that do not work with -v
      if( $self->{invert_match})
        { if( $self->{count})      { die "cannot use -v, --invert-match and -c, --count\n";     }
          if( $self->{text_only})  { die "cannot use -v, --invert-match and -t, --text-only\n"; }
          if( $self->{max_count})  { die "cannot use -v, --invert-match and -m, --max-count\n"; }
          if( !$self->{xml_wrap})  { $self->{no_xml_wrap}=1; }
        }

    # one option implies an other one
    if( $self->{quiet}) { $self->{no_messages}=1; }

  }


sub grep
  { my( $self, $xpath, @argv)= @_;

    binmode STDIN;
    if( !$self->{original_encoding}) { binmode STDOUT, ':encoding(utf-8)'; } 

    # get file list
    my @files;
    if( @argv)
      { @files= $self->{recursive }? $self->file_list( @argv) : @argv; }  
    else
      { push @files, undef; }

    my $more_than_one_file = scalar @files > 1;
    my $xml_result         = ! ($self->{text_only }|| $self->{files_with_matches} || $self->{files_without_matches} || $self->{count});
    my $split_result       = $self->{wrap} || ($more_than_one_file && !$self->{nowrap});
    my $need_file_wrapper  = $xml_result && $split_result;
    my $need_wrapper       = $xml_result && !$self->{no_xml_wrap};
    my $need_filename      = ($self->{text_only} || $self->{count}) && $split_result;


    my $header= $need_wrapper ? $self->header() : '';
    my $footer= $need_wrapper ? $self->footer() : '';

    $self->{ns_mapping}= keys %{$self->{define_ns}};

    if( $XML::LibXML::VERSION < 1.61 && $self->{ns_mapping}) 
      { _use( "XML::LibXML::XPathContext", "needed to use -N, --define-ns option"); }

    my $got_result;
    
    foreach my $file (@files)
      { if( $self->{quiet})
          { if( $self->{invert_match})
              { my $doc= $self->grep_v( $xpath, $file); 
                if( $doc && $self->doc_has_root( $doc)) { return 0; }
              }
            else
              { my $nb= $self->grep_nb( $xpath, $file);
                if( $nb) { return 0; }
              }
          }
        elsif( $self->{files_with_matches})
          { my $nb= $self->grep_nb( $xpath, $file);
            if( $nb) 
              { 
                $self->print_filename( $file);
              }
          }
        elsif( $self->{files_without_matches})
          { my $nb= $self->grep_nb( $xpath, $file);
            if( !$nb) 
              { 
                $self->print_filename( $file);
              }
          }
        elsif( $self->{invert_match})
          { my $doc= $self->grep_v( $xpath, $file);
            if( $doc)
              { if( $self->doc_has_root( $doc) )
                  { if( $header) { print $header; $header= ''; }
                    if( $self->{xml_wrap})
                      { # remove the XML declaration from the subdoc
                        (my $out= $doc->toString( $self->{format}, $self->{original_encoding}))=~s{^\s*<\?xml[^>]*>\n?}{};
                        print $out; 
                      }
                    else
                      { print $doc->toString( $self->{format}, $self->{original_encoding}), "\n"; }
                    $got_result=1;
                  }
              }
          }
        elsif( $self->{text_only})
          { my $set= $self->grep_text( $xpath, $file) or next;
            if( @$set)
              { 
                if( $need_filename) { foreach (@$set) { s{^}{$file:} } } # add filename
                print @$set;
              }
          }
        elsif( $self->{count})
          { my $nb= $self->grep_nb( $xpath, $file);
            if( !defined $nb) { next; }
            print $need_filename ? "$file:$nb\n" : "$nb\n"; 
          }
        else
          { # regular mode
            my $nodes= $self->grep_nodes( $xpath, $file) or next;
            if( @$nodes)
              { if( $header) 
                  { if( $self->{original_encoding}) 
                      { my $encoding= $nodes->[0]->ownerDocument->encoding;
                        if( $encoding) { $header=~ s{UTF-8}{$encoding}; }
                      }
                    print $header; 
                    $header= '';
                  }

                if( $need_file_wrapper)
                  { print $self->file_header( $file);
                    $self->_print_hits_in_file( 2 => $nodes);
                    print $self->file_footer(),
                          ;
                  }
                else
                  { $self->_print_hits_in_file( 1 => $nodes); }

                $got_result=1;
              }
          }         
      }
    
    if( $self->{quiet}) { return -1; }
    
    if( $header && $self->{generate_empty_set})                  { print $header; } # in case no result was found
    if( $footer && ($got_result || $self->{generate_empty_set})) { print $footer; }
    
    return 0;
  }

# the print is done here to avoid passing a potentially pretty big string around
sub _print_hits_in_file
  { my( $self, $format, $nodes)= @_;
    print map( { $self->{format} ? $self->indented_xml( $_->toString( $self->{format}, $self->{original_encoding}), $format)  . "\n"
                                                 : $_->toString( 0, $self->{original_encoding}) . "\n"
                               } @$nodes
                              );
  } 
      
sub file_list
  { my $self= shift;
    my $rules= File::Find::Rule->new;
    if( $self->{include}) { $rules->name( $self->{include});     }
    if( $self->{exclude}) { $rules->not_name( $self->{exclude}); }
    unless( $self->{recursive})   { $rules->maxdepth( 0);                }
    $rules->not_directory();
    my @files= $rules->in( @_);
    return @files;
  }


sub grep_nodes
  { my( $self, $xpath, $file)= @_;
    my( undef, @nodes)= $self->findnodes( $file => $xpath) or return ;
    if( $self->{max_count }&& (@nodes >= $self->{max_count})) { $#nodes= $self->{max_count }-1; }
    return \@nodes;
  }

sub grep_v
  { my( $self, $xpath, $file)= @_;
    my( $doc, @nodes)= $self->findnodes( $file => $xpath) or return ;
    foreach my $node (@nodes)
      { my $parent= $node->parentNode or return;
        $parent->removeChild( $node);
      }
    return $doc;
  }


sub findnodes
  { my( $self, $file, $xpath)= @_;

    my $doc;


    if( defined $file)
      { # need to test this instead of calling parse_*_file, or we get an untrappable "I/O error : Permission denied" 
        # message from XML::LibXML
        if( ! -e $file) 
          { $self->mwarn( "xml_grep2: $file: No such file or directory"); 
            return;
          } 
        elsif( ! -r $file) 
          { $self->mwarn( "xml_grep2: $file: Permission denied"); 
            return;
          } 
      }

    my( $method, @parse_args);

    if( $XML::LibXML::VERSION > 1.70 && ! $self->{xl})
      { $method    = $self->{html} ? 'load_html' : 'load_xml';
        @parse_args = defined $file ? ( location => $file) : ( IO => \*STDIN);
      }
    else
      { $method = $self->{html} ? 'parse_html' : 'parse'; 
        $method .= defined $file ? '_file' : '_fh'      ;
        @parse_args = defined $file ? $file : \*STDIN;
      }
        
    eval { $doc= $self->{parser}->$method( @parse_args); };
    if( $@) 
      { if( !$self->{no_messages}) 
          { $self->parsing_exception( $@); }
        return;
      }

    if( $self->{ns_mapping})
      { my $xc= XML::LibXML::XPathContext->new( $doc);
        while( my( $prefix, $uri)= each %{$self->{define_ns}}) { $xc->registerNs( $prefix => $uri) }
        return $xc, $xc->findnodes( $xpath);
      }
    else
      { return $doc, $doc->findnodes( $xpath); }
  }


sub grep_text
  { my $self= shift;
    my $nodes= $self->grep_nodes( @_) or return;
    my @text= map { $_->textContent } @$nodes;
    foreach (@text) { s{[\n\r]\s*}{ }g; $_ .= "\n"} # trim linefeeds
    return \@text;
  }

sub grep_nb
  { my $self= shift;
    my $nodes= $self->grep_nodes( @_) or return;
    return scalar @$nodes;
  }

sub _use
  { my( $module, $message)= @_;
    if( eval "require $module" )
           { import $module; }
         else
           { die "$module not found, $message\n"; }
  }

sub parsing_exception
  { my( $self, $warning)= @_;

    if( $warning=~ m{^I/O error}) { return; }

    if( $warning=~ m{^Could not create file parser context for file "(.*?)": (.*?)( at .* line \d+)?\s*$})
      { $warning= "$1: $2"; }
    $self->mwarn( "xml_grep2: $warning"); 
    return;
  }

sub doc_has_root
  { my( $self, $doc)= @_;
    return scalar grep { $_->nodeType == XML_ELEMENT_NODE } $doc->childNodes()
  }

sub mwarn
  { my $self= shift;
    if( ! $self->{no_messages}) 
      { my $warning= join '', @_;
        $warning=~ s{\s*$}{\n};
         warn $warning; 
       } 
  }

sub print_filename
  { my( $self, $file)= @_;
    if( ! defined $file) { $file = $self->{label} ? $self->{label }: "(stdin)"; }
    print "$file\n";
  }

sub header
  { my $self= shift;
    my $xmlns= $self->{ns} ? qq{ xmlns:$self->{ns}="$self->{ns_uri}"} : '';
    return qq{<?xml version="1.0" encoding="UTF-8"?>\n<$self->{ns_column}$self->{result_tag}$xmlns>\n}; 
  }

sub footer  
  { my $self= shift;
    return qq{</$self->{ns_column}$self->{result_tag}>\n};
  }

sub file_header
  { my $self= shift;
    my $file= defined $_[0] ? xml_escape( shift()) : '(stdin)'; 
    return qq{  <$self->{ns_column}$self->{file_tag } $self->{ns_column}$self->{att_filename}="$file">\n}; 
  }

sub file_footer
  { my $self= shift;
    return qq{  </$self->{ns_column}$self->{file_tag}>\n};
  }

sub indented_xml
  { my $self= shift;
    my( $string, $level)= @_;
    my $prefix= $self->{indent }x $level;
    $string=~ s{^}{$prefix}gm;
    return $string;
  }

sub xml_escape
  { my $string= shift();
    $string=~ s{&}{&amp;}g;
    $string=~ s{<}{&lt;}g;
    $string=~ s{>}{&gt;}g;
    $string=~ s{"}{&quote;}g;
    return $string;
  }

1;
