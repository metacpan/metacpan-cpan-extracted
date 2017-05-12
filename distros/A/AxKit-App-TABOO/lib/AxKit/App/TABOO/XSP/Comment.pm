package AxKit::App::TABOO::XSP::Comment;
use 5.6.0;
use strict;
use warnings;
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::AxKit::Exception;
use AxKit;
use AxKit::App::TABOO::Data::Comment;
use AxKit::App::TABOO::Data::Plurals::Comments;
use AxKit::App::TABOO::Data::Story;
use AxKit::App::TABOO;
use Session;
use Time::Piece ':override';
use XML::LibXML;
use Net::Akismet;

use vars qw/$NS/;

our $VERSION = '0.52';

=head1 NAME

AxKit::App::TABOO::XSP::Comment - News comment management tag library for TABOO

=head1 SYNOPSIS

Add the comment: namespace to your XSP C<E<lt>xsp:pageE<gt>> tag, e.g.:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:comment="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment"
    >

Add this taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::App::TABOO::XSP::Comment


=head1 DESCRIPTION

This XSP taglib provides a single (for now) tag to store information
related to news stories, as it communicates with TABOO Data objects,
particulary L<AxKit::App::TABOO::Data::Comment>.

L<Apache::AxKit::Language::XSP::SimpleTaglib> has been used to write
this taglib.

=cut


$NS = 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment';


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

package AxKit::App::TABOO::XSP::Comment::Handlers;

=head1 Tag Reference

=head2 C<E<lt>store/E<gt>>

It will take whatever data it finds in the L<Apache::Request> object
held by AxKit, and hand it to a new
L<AxKit::App::TABOO::Data::Comment> object, which will use whatever
data it finds useful. It will not store anything unless the user is
logged in and authenticated with an authorization level. If an
authlevel is not found in the user's session object, it will throw an
exceptions with an C<AUTH_REQUIRED> code.

If TABOOAkismetKey is set (and spammers will make you want this really
fast), it will check the Akismet anti-spam system if the user has an
authlevel less than 2, and return a C<FORBIDDEN> if it is deemed to be
spam.

Finally, the Data object is instructed to save itself.

If successful, it will return a C<store> element in the output
namespace with the number 1.

=cut


sub store : node({http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output}store) {
    return << 'EOC'
    my %args;
    foreach my $name ($cgi->param) {
      $args{$name} = $cgi->param($name);
    }
    my $session = AxKit::App::TABOO::session($r);
    $args{'username'} = AxKit::App::TABOO::loggedin($session);

    my $authlevel = AxKit::App::TABOO::authlevel($session);
    AxKit::Debug(4, "Logged in as $args{'username'} at level $authlevel");
    unless (defined($authlevel)) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => AUTH_REQUIRED,
					       -text => "Not authenticated and authorized with an authlevel");
    }
    my $check = AxKit::App::TABOO::Data::Comment->new();
    if (($args{'parentcpath'})
	 && (!$check->exist(storyname => $args{'storyname'}, 
			    sectionid => $args{'sectionid'},
			    commentpath => $args{'parentcpath'}))) {
      # This is actually bad, it shouldn't ever happen
      throw Apache::AxKit::Exception::Retval(
					     return_code => FORBIDDEN,
					     -text => "The parent post of the submitter doesn't exist.");
    }
    my $timestamp = localtime;
    unless ($args{'timestamp'}) {
	$args{'timestamp'} = $timestamp->datetime;
    }
    $args{'commentpath'} = $args{'parentcpath'} . '/' . $args{'username'};
    my $check = AxKit::App::TABOO::Data::Plurals::Comments->new();
    my $exists = $check->exist(storyname => $args{'storyname'}, 
			       sectionid => $args{'sectionid'},
			       commentpath => $args{'commentpath'});
    if ($exists) {
      $args{'commentpath'} .= '_' . ++$exists;
    }
    delete $args{'parentcpath'};

    if ($r->dir_config('TABOOAkismetKey')) {
      AxKit::Debug(4, "Using Akismet");
      my $akismet = Net::Akismet->new(
                        KEY => $r->dir_config('TABOOAkismetKey'),
                        URL => 'http://'.$r->header_in('X-Forwarded-Host'),
                ) or throw Apache::AxKit::Exception::Error(-text => "Akismet key verification failed.");
      my %akismetstuff = (USER_IP => $r->header_in('X-Forwarded-For'),
			  COMMENT_CONTENT => $args{'content'},
			  REFERRER => $r->header_in('Referer'),
			  COMMENT_TYPE => 'comment',
			 );
      if ($authlevel >= 2) { # Presumed ham
	$akismet->ham(%akismetstuff);
      } else {
	AxKit::Debug(10, "Akismet check on: ".join("    ",values(%akismetstuff)));
	if ($akismet->check(%akismetstuff) eq 'true') {
	  throw Apache::AxKit::Exception::Retval(
						 return_code => FORBIDDEN,
						 -text => "Akismet check says that your comment is spam. Please contact webmaster if you received this message in error.");
	}
      }
    }

    my $comment = AxKit::App::TABOO::Data::Comment->new();
    $comment->populate(\%args);
    $comment->save();
    # Modify the last timestamp of the parent story
    my $story = AxKit::App::TABOO::Data::Story->new();
    $story->load(what => 'storyname,sectionid',
		 limit => {storyname => $args{'storyname'},
			   sectionid => $args{'sectionid'}});
    $story->lasttimestamp($timestamp);
    $story->save;
    1;
EOC
}


=head2 C<E<lt>this-comment/E<gt>>

Will return an XML representation of the data submitted in the last
request, enclosed in a C<comment-submission> element. Particularly
useful for previewing a submission.

=cut

sub this_comment : struct {
    return << 'EOC'
    my %args;
    foreach my $name ($cgi->param) {
      $args{$name} = $cgi->param($name);
    }
    $args{'username'} = AxKit::App::TABOO::loggedin(AxKit::App::TABOO::session($r));
    my $timestamp = localtime;
    unless ($args{'timestamp'}) {
	$args{'timestamp'} = $timestamp->datetime;
    }
    my $comment = AxKit::App::TABOO::Data::Comment->new();
    $comment->populate(\%args);
    $comment->adduserinfo();
#    $comment->addcatinfo();
    
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output', 'comm:comment-submission');
    $doc->setDocumentElement($root);
    $comment->write_xml($doc, $root); # Return an XML representation
EOC
}


=head2 C<E<lt>get-comment/E<gt>>

Will return an XML representation of the data for a previously saved
comment, enclosed in a C<comment-loaded> element. It needs to get the
comment identified by C<storyname>, C<sectionid> and C<commentpath>
attributes or child elements.

=cut


sub get_comment : struct attribOrChild(storyname,sectionid,commentpath) {
    return << 'EOC'
    my $comment = AxKit::App::TABOO::Data::Comment->new();
    unless ($comment->load(what => '*', limit => {sectionid => $attr_sectionid,
						  storyname=> $attr_storyname,
						  commentpath=> $attr_commentpath})) {
      throw Apache::AxKit::Exception::Retval(
					     return_code => 404,
					     -text => "Requested comment $attr_commentpath not found.");
    }
    $comment->adduserinfo();
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Comment/Output', 'comm:comment-loaded');
    $doc->setDocumentElement($root);
    $comment->write_xml($doc, $root); # Return an XML representation
EOC
}


1;



=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
