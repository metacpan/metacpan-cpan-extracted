package AxKit::App::TABOO::XSP::Article;
use 5.6.0;
use strict;
use warnings;
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::AxKit::Exception;
use AxKit;
use AxKit::App::TABOO::Data::Article;
use AxKit::App::TABOO;
use Session;
use Time::Piece ':override';
use XML::LibXML;
use IO::File;
use MIME::Type;

use vars qw/$NS/;

our $VERSION = '0.4';

=head1 NAME

AxKit::App::TABOO::XSP::Article - Article management tag library for TABOO

=head1 SYNOPSIS

Add the story: namespace to your XSP C<E<lt>xsp:pageE<gt>> tag, e.g.:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article"
    >

Add this taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::App::TABOO::XSP::Article


=head1 DESCRIPTION

This XSP taglib provides tags to store information related to news
stories and to fetch and return XML representations of that data, as
it communicates with TABOO Data objects, particulary
L<AxKit::App::TABOO::Data::Article>.

L<Apache::AxKit::Language::XSP::SimpleTaglib> has been used to write
this taglib.

=head1 TODO

This taglib will be documented further in upcoming releases. While
there is quite a lot of working stuff here, it also has some bad
issues.


=cut


$NS = 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article';

# Some constants
# TODO: This stuff should go somewhere else!

use constant GUEST     => 0;
use constant NEWMEMBER => 1;
use constant MEMBER    => 2;
use constant OLDTIMER  => 3;
use constant ASSISTANT => 4;
use constant EDITOR    => 5;
use constant ADMIN     => 6;
use constant DIRECTOR  => 7;
use constant GURU      => 8;
use constant GOD       => 9;

# Internal function to get a filename we can work with.
sub _sanatize_filename {
  my $file = shift;
  $file =~ tr#A-Za-z0-9+#_#cd; # Replace any non-base64 with underscores
  return substr($file, 0, 29); # Return the 30 first chars.
}

sub _write_file {
    my %args = @_;
    my $fh = new IO::File;
    my $filename = $args{filename};
    my $ext = $args{extension} || 'txt';
    if ($args{upload}) {
	($filename, $ext) = $args{upload}->filename =~ m/^(.*)\.(\w*)$/;
    }
    $filename = _sanatize_filename($filename);
    my $i = 0;
    while (-e $args{docroot} ."/articles/content/$args{primcat}/$filename/$filename.$ext") { # Append an incrementing number if the file exists
	$i++;
	if ($i == 1) {
	    $filename .= '-' . $i;
	} else {
	    $filename =~ s/-\d+$/-$i/;
	}
	die "Can't really be $i identical files here, can it?" if ($i >= 100);
    }
    my $lookupfile = $args{docroot} ."/articles/content/$args{primcat}/$filename/";
    my $dir;
    foreach my $name (split('/', $lookupfile)) { # Make sure all dirs exist
	$dir .= $name . '/';
	unless (-d $dir) {
	    mkdir ($dir, 0775) || die "Failed to create directory " . $dir;
	}
    }
    $lookupfile .= "$filename.$ext";
    if ($fh->open("> " . $lookupfile)) {
	if ($args{upload}) {
	    my $uploadedfh = $args{upload}->fh;
	    while (<$uploadedfh>) {
		print $fh $_;
	    }
	} else {
	    die "Error saving string to filename $filename.$ext" unless (($filename) && ($args{text}));
	    print $fh $args{text};
	}
	$fh->close;
    } else { die "Failed to open file at $lookupfile for writing"  }
    return $filename;
}

package AxKit::App::TABOO::XSP::Article::Handlers;

=head1 Tag Reference


=head2 C<E<lt>store-required/E<gt>>

This tag will check and store the data from the required fields. It
will check for either uploaded files, and the MIME types of that, or
take plain text and save it to a local file. It doesn't do many
security checks yet.

If the save was successful, it will redirect to C</articles/edit>, so
that the submitter can continue editing of non-required fields. To
control where it redirects to, you should supply an attribute or child
element C<redirect> containing the URL of the page to redirect to and
C<retval>, with the HTTP return value. The latter defaults to 302.

If something went wrong, the tag will return a nodelist
C<problem>. The nodelist will contain the data store name of the
field(s) that weren't present, or C<nosave> if the save itself failed.

=cut


sub store_required : nodelist({http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output}art:problem) attribOrChild(redirect,retval) {
  return << 'EOC'
  my @errors = ();
  foreach my $required (qw(title authorid description primcat code)) {
      unless ($cgi->param($required)) {
	  push(@errors, $required);
      }
  }
  unless ((($cgi->param('text')) && ($cgi->param('filename'))) || ($cgi->param('upfile'))) {
      foreach my $required (qw(text filename upfile)) {
	  unless ($cgi->param($required)) {
	      push(@errors, $required);
	  }
      }
  }

  unless (@errors) { # OK, so far, so good
      my %args = map { $_ => $cgi->param($_) } $cgi->param;
      
      my $upload = $cgi->upload;
      if ($upload->size > 0) {
	  $args{'filename'} = AxKit::App::TABOO::XSP::Article::_write_file(upload=>$upload, primcat => $args{'primcat'}, docroot=>$r->document_root);
	  $args{'mimetype'} = $upload->type;
      } else {
	  $args{'filename'} = AxKit::App::TABOO::XSP::Article::_write_file(filename=>$args{'filename'}, text=>$args{'text'}, primcat => $args{'primcat'}, docroot=>$r->document_root);
	  $args{'mimetype'} = 'text/plain';
      }
      # TODO: Security sanity checks.
      $args{'authorok'} = 1; # Is assumed for now
      unless ($args{'date'}) {
	  my $timestamp = localtime;
	  $args{'date'} = $timestamp->datetime;
      }
      my $article = AxKit::App::TABOO::Data::Article->new();
      $article->populate(\%args, [[$args{'primcat'}, 'primcat']], [$args{'authorid'}]);
      unless($article->save) {
	  push(@errors, 'nosave');
      }
  }
      
  unless (@errors) { # Actually, everything went fine here, so we redirect to continue
    $cgi->status($attr_retval || 302);
    $cgi->err_headers_out->add("Location" => $attr_redirect || '/');
    Apache::exit($attr_retval || 302);
  } else { 
    AxKit::Debug(9, "Things that went wrong: " . join(' ', @errors));
  }
  @errors;
EOC
}

sub this_article : struct attribOrChild(primcat) {
  return << 'EOC'
  my %args = map { $_ => $cgi->param($_) } $cgi->param;
  my $upload =  $cgi->upload;

  my $lookupurl = AxKit::App::TABOO::XSP::Article::_write_file($upload, $attr_primcat, $r->document_root);
  $args{'format'} = $upload->type;
  # TODO: Security sanity checks.

  unless ($args{'date'}) {
      my $timestamp = localtime;
      $args{'date'} = $timestamp->datetime;
  }

  $args{'authorids'} = [$args{'authorid'}]; # Has to change to support more authors
  my $article = AxKit::App::TABOO::Data::Article->new();
  $article->populate(\%args);
  $article->adduserinfo();
  $article->addcatinfo();
  $article->addformatinfo();
    
  my $doc = XML::LibXML::Document->new();
  my $addel = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Article/Output', 'art:article-submission');
  $addel->setAttribute('contenturl', $lookupurl);
  $doc->setDocumentElement($addel);
  $article->write_xml($doc, $addel); # Return an XML representation
EOC
}


=head2 C<E<lt>get-article filename="foo" primcat="bar"/E<gt>>

This tag will get an XML representation of the article identified with
C<filename> and C<primcat>. The parameters may be given as attributes
or child elements.

=cut


sub get_article : struct attribOrChild(filename,primcat) {
    return << 'EOC'
    AxKit::Debug(8, "We look for article with filename: '" . $attr_filename . "'");
    my $article = AxKit::App::TABOO::Data::Article->new();
    unless ($article->load(limit => { filename => $attr_filename })) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => 404,
					       -text => "Article with identifier $attr_filename not found");
    }	
    unless ($article->editorok && $article->authorok) {
        my $session = AxKit::App::TABOO::session($r);
	my $authlevel = AxKit::App::TABOO::authlevel($session);
	if (!$authlevel) {
	    throw Apache::AxKit::Exception::Retval(
						   return_code => 401,
						   -text => "Not authorised with an authlevel");
	}
	my $editinguser = AxKit::App::TABOO::loggedin($session);
	unless (grep(/$editinguser/, @{$article->authorids}) || ($authlevel >= 5)) {
	    throw Apache::AxKit::Exception::Retval(
						   return_code => 403,
						   -text => "Authentication and higher priviliges required to load article");
      }
    }
	    
    $article->adduserinfo;
    $article->addcatinfo;
    $article->addformatinfo();

    my $lookupurl;
    foreach my $ext ($article->mimetype->extensions) {
	my $lookupfile = "/articles/content/$attr_primcat/$attr_filename/$attr_filename.$ext";
	warn $r->document_root . $lookupfile;
	if (-r $r->document_root . $lookupfile) {
	    $lookupurl = 'http://' . $r->get_server_name . ':' . $r->get_server_port . $lookupfile;
	}
	last if $lookupurl;
    }
    AxKit::Debug(8, "Content really at: " . $lookupurl);

    unless ($lookupurl) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => 404,
					       -text => "Content $lookupurl not found");
    }

    my $doc = XML::LibXML::Document->new();
    my $rootel = $doc->createElement('taboo');
    $rootel->setAttribute('contenturl', $lookupurl);
    #  $rootel->setAttribute('type', 'article');
    #  $rootel->setAttribute('origin', 'Article');
    $doc->setDocumentElement($rootel);
    $article->write_xml($doc, $rootel);
EOC
}




1;




=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
