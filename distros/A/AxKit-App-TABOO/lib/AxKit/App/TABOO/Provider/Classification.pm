package AxKit::App::TABOO::Provider::Classification;
use strict;
use warnings;
use Carp;

# This is the "Classification" Provider, that is, it constructs
# objects that eventually gives back XML containing classification of
# stories and articles.  It just implements the AxKit Provider API,
# and therefore contains no method that anybody should use for
# anything, so the POD deals with what you should expect from this
# module.


our $VERSION = '0.4';

=head1 NAME

AxKit::App::TABOO::Provider::Classification - Provider for classifiying things in TABOO

=head1 SYNOPSIS

In the Apache config:

  <Location /cats/>
  	PerlHandler AxKit
        AxContentProvider AxKit::App::TABOO::Provider::Classification
  </Location>


=head1 DESCRIPTION

This is a Provider, it implements the AxKit Provider API, and
therefore contains no method that anybody should use for anything. For
that reason, this documentation deals with what you should expect to
be returned for different URIs.


It is intended to be used to get an overview of articles, stories
etc. that can be found classified into different categories, of
different types.

In accordance with the TABOO philosophy, it interacts with Data
objects, that are Perl objects responsible for retrieving data from a
data storage, make up sensible data structures, return XML markup,
etc. In contrast with the News provider, this provider mainly
interacts with Plural objects to make lists of stories. Also, it
doesn't deal with comments.

The rest of the documentation has yet to be written, but as one can
guess, it may share some things with the NewsList Provider.


=cut



use Data::Dumper;
use XML::LibXML;

use vars qw/@ISA/;
@ISA = ('Apache::AxKit::Provider');

use Apache;
use Apache::Log;
use Apache::AxKit::Exception;
use Apache::AxKit::Provider;

use AxKit;
use AxKit::App::TABOO;
use AxKit::App::TABOO::Data::Story;
use AxKit::App::TABOO::Data::Plurals::Stories;
use AxKit::App::TABOO::Data::Category;
use AxKit::App::TABOO::Data::Plurals::Categories;
use AxKit::App::TABOO::Data::Article;
use AxKit::App::TABOO::Data::Plurals::Articles;


sub init {
  my $self = shift;

  my $r = $self->apache_request();
  
  AxKit::Debug(10, "[Classification] Request object: " . $r->as_string);
  AxKit::Debug(8, "[Classification] Provider using URI " . $r->uri);

  $self->{uri} = $r->uri;
  my @uri = split('/', $r->uri);
  splice(@uri, 0, 2); # The first part is just a keyword,
  $self->{cats} = \@uri;

  $self->{session} = AxKit::App::TABOO::session($r);

  AxKit::Debug(9, "[Classification] Data parsed in init: " . Dumper($self));
  return $self;
}

sub process {
  my $self = shift;
  $self->{foundcats} = AxKit::App::TABOO::Data::Plurals::Categories->new();
  foreach my $catname (@{$self->{cats}}) {
    my $category = AxKit::App::TABOO::Data::Category->new();
    unless ($category->load(limit => {catname => $catname})) {
      $self->{exists} = 0;
      $self->{catnotfound} = $catname;
      last;
    } else {
      $self->{foundcats}->Push($category);
      $self->{exists} = 1;
    }
  }
  if ($self->{exists}) {
    $self->{articles} = AxKit::App::TABOO::Data::Plurals::Articles->new();
    $self->{stories} = AxKit::App::TABOO::Data::Plurals::Stories->new();
    unless ($self->{articles}->incat(@{$self->{cats}})) {
      $self->{articles} = undef;
      unless ($self->{stories}->exists(primcat => @{$self->{cats}})) { 
	$self->{exists} = 0;
      }
    }
  }
  return $self->{exists};
}

sub exists {
  my $self = shift;
  if ($self->{exists}) {
    return 1;
  } else {
    return 0;
  }
  # Thanks, Kip! :-)
}


sub key {
  my $self = shift;
  return $self->{uri} . "/" . AxKit::App::TABOO::loggedin($self->{session});
}


sub mtime {
  my $self=shift;
  return time();
}


sub get_fh {
  throw Apache::AxKit::Exception::IO(
	      -text => "No fh for Classification Provider");
}

sub get_dom {
  my $self = shift;
  unless ($self->{dom}) {
    unless ($self->{exists}) {
      throw Apache::AxKit::Exception::Retval(
					     return_code => 404,
					     -text => "Category " . $self->{catnotfound} . " was not found");
    }
#    warn "ANT: " . Dumper($self);
    my $authlevel = AxKit::App::TABOO::authlevel($self->{session});
    if (scalar(@{$self->{cats}}) == 1) {
      my %limit;
      if (! defined($authlevel)
	  || ($authlevel < 4)) {
	$limit{'editorok'} = 1;
      } elsif ($self->{editor}) {
	$limit{'editorok'} = 0;
      }
      $limit{'primcat'} = ${$self->{cats}}[0];
      
      $self->{stories}->load(what => 'storyname,sectionid,primcat,editorok,title,submitterid,timestamp',
			     limit => \%limit, 
			     orderby => 'timestamp DESC');
      $self->{stories}->addcatinfo;
      $self->{stories}->adduserinfo;
    } else {
      $self->{stories} = undef;
    }
    my $doc = XML::LibXML::Document->new();
    my $rootel = $doc->createElement('taboo');
    $rootel->setAttribute('type', 'catlists');
    $rootel->setAttribute('origin', 'Classification');
    $doc->setDocumentElement($rootel);
    if ($self->{stories}) {
      $self->{stories}->write_xml($doc, $rootel);
    }
    $self->{foundcats}->write_xml($doc, $rootel);
    my $anyarticles = 0;
    if($self->{articles}) {
      my %limit;
      if (! defined($authlevel)
	  || ($authlevel < 4)) {
	$limit{'editorok'} = 1;
	$limit{'authorok'} = 1;
      }
      if ($self->{articles}->load(limit => \%limit)) {
	$anyarticles = 1;
      }
      $self->{articles}->addcatinfo;
      $self->{articles}->adduserinfo;
      $self->{articles}->addformatinfo;
      $self->{articles}->write_xml($doc, $rootel);
    }
#    warn Dumper($self->{stories});
#    warn Dumper($self->{articles});
    
    unless (($anyarticles) || (defined($self->{stories}))) {
      if (defined($authlevel)) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => 403,
					       -text => "Articles or stories exist, but are only accessible to editors.");
      } else {
	throw Apache::AxKit::Exception::Retval(
					       return_code => 401,
					       -text => "Articles or stories exist, but are only accessible to editors, you have to log in as one.");
      }
    }

    $self->{dom} = $doc;
  }
  return $self->{dom};
}

sub get_strref {
  my $self = shift;
  return \ $self->get_dom->toString(1);
}



sub get_styles {
  my $self = shift;
  my @styles = (
		{ type => "text/xsl",
		  href => "/transforms/categories/xhtml/class-provider.xsl" },
	       );
  return \@styles;
}



=head1 URI USAGE

This Provider doesn't place any constraints of what first part of the
local part of the URI should be, but the XSLT that is included in the
distribution does, and you should set this with e.g.

    PerlAddVar AxParamExpr cats.prefix '"/cats/"'

in the Apache config.

After that, you may simply append the C<catname>s of categories, and
the Provider will return all stories and articles classified in B<all>
those categories. Since for stories, there is a only a primary
categorization, they are only displayed when there is a single
category in the path.


=head1 BUGS/TODO

I guess this documentation could be more verbose.


=head1 SEE ALSO

L<AxKit::App::TABOO::Data::Provider::NewsList>,
L<AxKit::App::TABOO::Data::Plurals::Categories>


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut



1;


