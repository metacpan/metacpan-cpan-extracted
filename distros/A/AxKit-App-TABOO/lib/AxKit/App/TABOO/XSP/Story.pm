package AxKit::App::TABOO::XSP::Story;
use 5.6.0;
use strict;
use warnings;
use utf8;
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::AxKit::Exception;
use AxKit;
use AxKit::App::TABOO;
use AxKit::App::TABOO::Data::Story;
use AxKit::App::TABOO::Data::Plurals::Stories;
use Session;
use Time::Piece ':override';
use XML::LibXML;
use Text::Unaccent;
use IDNA::Punycode;
use Net::Akismet;

use vars qw/$NS/;

our $VERSION = '0.53';

=head1 NAME

AxKit::App::TABOO::XSP::Story - News story management tag library for TABOO

=head1 SYNOPSIS

Add the story: namespace to your XSP C<E<lt>xsp:pageE<gt>> tag, e.g.:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:story="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story"
    >

Add this taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::App::TABOO::XSP::Story


=head1 DESCRIPTION

This XSP taglib provides tags to store information related to news
stories and to fetch and return XML representations of that data, as
it communicates with TABOO Data objects, particulary
L<AxKit::App::TABOO::Data::Story>.

L<Apache::AxKit::Language::XSP::SimpleTaglib> has been used to write
this taglib.

=cut


$NS = 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story';

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

# This sub will create a useful storyname from the title
sub _create_storyname {
    my $intitle = shift;
    my $nl = 30; # Should be the length of storyname in the table
    chomp($intitle);
 
    my $endno = '';
    $intitle =~ s/\p{TerminalPunctuation}//gs; # Remove terminal punctutation
    if ($intitle =~ s/(\d+)$//) { # if it ends with a number, the number might be useful, so put it into a variable but strip it
	$endno = $1;
    }
    idn_prefix('');
#    warn "INTITLE: ". $intitle;
    $intitle = unac_string('utf8', $intitle); # Try to translate most
    $intitle = encode_punycode(lc($intitle)); # Punycode the rest if needed
    $intitle =~ s/\s+/-/gs; # All spaces become one -
    $intitle =~ s/[^a-z0-9\-_]//g; # Remove all now not a alphanumeric or -
#    warn $intitle;
#    warn $endno;
#    warn length($endno);
    
    my $base = substr($intitle, 0, $nl-2-length($endno));
    
#    warn $base;
    my $storyname = $base . $endno;
    my $stories = AxKit::App::TABOO::Data::Plurals::Stories->new();
    
    my $i = 1;    
    while ($stories->exists(storyname => $storyname)) { # Checking if the story exists
	$base = substr($base, 0, $nl-3-length($i)-length($endno));
	$storyname = $base . $endno . '-' . $i;
	AxKit::Debug(9, "Try '$storyname' for storyname");

	$i++;
	if ($i>99) { # We've gone too far allready
	    throw Apache::AxKit::Exception::Retval(
						   return_code => 500,
						   -text => "Tried $i storynames, all taken. Editors need more imagination.");
	}
    }
    if (length($storyname) > $nl) { # Is likely to cause a crash
	AxKit::Debug(2, "Length of '$storyname' is higher than $nl");
    }
    return $storyname;
}

package AxKit::App::TABOO::XSP::Story::Handlers;

=head1 Tag Reference

=head2 C<E<lt>store/E<gt>>

It will take whatever data it finds in the L<Apache::Request> object
held by AxKit, and hand it to a new L<AxKit::App::TABOO::Data::Story>
object, which will use whatever data it finds useful. It will not
store anything unless the user is logged in and authenticated with an
authorization level. If an authlevel is not found in the user's
session object, it will throw an exception with an C<AUTH_REQUIRED>
code. If asked to store certain priviliged fields, it will check the
authorization level and throw an exception with a C<FORBIDDEN> code if
not satisfied. If timestamps do not exist, they will be created based
on the system clock.

If TABOOAkismetKey is set (and spammers will make you want this really
fast), it will check the Akismet anti-spam system if article has not
been approved by an editor and the user has an authlevel less than 2,
and return a C<FORBIDDEN> if it is deemed to be spam. Once the article
has been approved by an editor, it is fed to Akismet to teach it what
is ham.

Finally, the Data object is instructed to save itself.

If successful, it will return a C<store> element in the output
namespace with the number 1.

=cut


sub store : node({http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output}store) {
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
    unless ($args{'storyname'}) {
	$args{'storyname'} = AxKit::App::TABOO::XSP::Story::_create_storyname($args{'title'});
    } 
    if ($args{'sectionid'} ne 'subqueue') {
	if ($authlevel < AxKit::App::TABOO::XSP::Story::EDITOR) {
	    throw Apache::AxKit::Exception::Retval(
						   return_code => FORBIDDEN,
						   -text => "Editor Priviliges are needed to store non-subqueue section. Your level: " . $authlevel);
	}
    }
    if (($args{'editorok'}) && ($authlevel < AxKit::App::TABOO::XSP::Story::EDITOR)) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => FORBIDDEN,
					       -text => "Editor Priviliges are needed to OK an article. Your level: " . $authlevel);
    }
    
    if ($r->dir_config('TABOOAkismetKey')) {
      AxKit::Debug(4, "Using Akismet");
      my $akismet = Net::Akismet->new(
                        KEY => $r->dir_config('TABOOAkismetKey'),
                        URL => 'http://'.$r->header_in('X-Forwarded-Host'),
                ) or throw Apache::AxKit::Exception::Error(-text => "Akismet key verification failed.");
      my %akismetstuff = (USER_IP => $r->header_in('X-Forwarded-For'),
			  COMMENT_CONTENT => $args{'minicontent'} ."\n". $args{'content'},
			  REFERRER => $r->header_in('Referer'),
			  COMMENT_TYPE => 'comment',
			 );
      if ($args{'editorok'}) { # Surely ham
	$akismet->ham(%akismetstuff);
      } elsif ($authlevel < 2) { # Above 2 is probably ham
	AxKit::Debug(10, "Akismet check on: ".join("    ",values(%akismetstuff)));
	if ($akismet->check(%akismetstuff) eq 'true') {
	  throw Apache::AxKit::Exception::Retval(
						 return_code => FORBIDDEN,
						 -text => "Akismet check says that your comment is spam. Please contact webmaster if you received this message in error.");
	}
      }
    }


    if (! $args{'submitterid'}) {
	# If the submitterid is not set, we set it to the current username
	$args{'submitterid'} = $args{'username'}
    }

    my $story = AxKit::App::TABOO::Data::Story->new();

    my $timestamp = localtime;
    unless ($args{'timestamp'}) {
	$args{'timestamp'} = $timestamp->datetime;
    }
    unless ($args{'lasttimestamp'}) {
	$args{'lasttimestamp'} = $timestamp->datetime;
    }

    $story->populate(\%args);
    $story->save;
    1;
EOC
}


=head2 C<E<lt>this-story/E<gt>>

Will return an XML representation of the data submitted in the last
request, enclosed in a C<story-submission> element. Particularly
useful for previewing a submission.

=cut

sub this_story : struct {
    return << 'EOC'
    my %args = map { $_ => $cgi->param($_) } $cgi->param;

    $args{'username'} = AxKit::App::TABOO::loggedin(AxKit::App::TABOO::session($r));

    unless ($args{'submitterid'}) {
      # If the submitterid is not set, we set it to the current username
	$args{'submitterid'} = $args{'username'}
    }
    
    my $timestamp = localtime;
    unless ($args{'timestamp'}) {
      $args{'timestamp'} = $timestamp->datetime;
    }
    unless ($args{'lasttimestamp'}) {
      $args{'lasttimestamp'} = $timestamp->datetime;
    }
    my $story = AxKit::App::TABOO::Data::Story->new();
    $story->populate(\%args);
    $story->adduserinfo();
    $story->addcatinfo();
    
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output', 'story:story-submission');
    $doc->setDocumentElement($root);
    $story->write_xml($doc, $root); # Return an XML representation
EOC
}


=head2 C<E<lt>get-story/E<gt>>

Will return an XML representation of the data for a previously saved
story, enclosed in a C<story-loaded> element. It needs to get the
story identified by C<storyname> and C<sectionid> attributes or child
elements.

=cut


sub get_story : struct attribOrChild(storyname,sectionid) {
    return << 'EOC'
        my %args;
    foreach my $name ($cgi->param) {
      $args{$name} = $cgi->param($name);
    }

    my $session = AxKit::App::TABOO::session($r);

    unless ($args{'username'}) {
      $args{'username'} = AxKit::App::TABOO::loggedin($session);
    }


    my $story = AxKit::App::TABOO::Data::Story->new();
    unless ($story->load(limit => {sectionid => $attr_sectionid, storyname=> $attr_storyname})) {
      throw Apache::AxKit::Exception::Retval(
					     return_code => 404,
					     -text => "Requested story $attr_storyname not found.");
    }
    $story->adduserinfo();
    unless ($story->editorok) {
      if (AxKit::App::TABOO::authlevel($session) < 4) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => 401,
					       -text => "Authentication and higher priviliges required to load story");
      }
    }
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Story/Output', 'story:story-loaded');
    $doc->setDocumentElement($root);
    $story->write_xml($doc, $root); # Return an XML representation
EOC
}

=head2 C<E<lt>number-of-unapproved sectionid="subqueue"/E<gt>>

Will return the number of articles in a given section that has not
been approved by an editor. Especially useful for giving the editors a
heads-up as to new articles in the submission queue, like in the
example.

=cut

sub number_of_unapproved : expr attribOrChild(sectionid) {
    return << 'EOC'
    my $stories = AxKit::App::TABOO::Data::Plurals::Stories->new();
    $stories->exists(sectionid => $attr_sectionid,
		   editorok => 0);
EOC
}


1;

=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
