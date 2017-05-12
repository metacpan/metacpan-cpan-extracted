#!/usr/local/bin/perl -w --
# ------------------------------------------------------------------------
# Apache/NNTPGateway.pm: Apache mod_perl Handler.
# - Web Interface to NNTP. The complete pod doc is at the __END__.
# ------------------------------------------------------------------------

package Apache::NNTPGateway;
my ($NAMETAG) = __PACKAGE__ =~ /::(.*)$/;

require 5.00502;
use strict;
#use warnings;
use vars qw($VERSION $DEBUG $NNTP);

$VERSION = '0.9';

# Needed packages

use Apache::Constants qw(:common);
use Apache::URI qw();
use Apache::Request qw();
use Apache::Log qw();

#use CGI qw/:standard/;
use CGI::Cookie qw();

# Net::NNTP @ISA Net::Cmd, IO::Socket
use IO::Socket;
use Net::Cmd qw(CMD_REJECT CMD_ERROR);
use Net::NNTP qw();

use Net::Config qw();
use Net::Domain qw();

use Mail::Address qw();

#use HTML::Template;
use File::Spec qw();


# Configurable Variables -------------------------------------------------

$DEBUG = 0;

# This variable is a protection against installing this handler in an
# unwanted Location. If set, the URL of the request is matched against
# this var and the handler continue processing only if the match
# succeed. Check get_config() sub for more details.
my $REQUIRED_LOCATION_BASE_RE = undef;

# The default NNTP server used, on correctly configured systems, with
# correctly configured Net modules, this should be ok, but this could
# be overridden by a server config NNTPGatewayNewsServer anyway.
my $DEFAULT_NEWS_SERVER = $Net::Config::NetConfig{nntp_hosts}->[0] || 'newsserver';

####
## You should have nothing to modify below this line... except maybe in
## the MESSAGES or HTML DECORATIONS sections.
####

# Garbage cans
my @_dummy_; 
my $_dummy_;

my $DOMAIN_NAME   = &Net::Domain::hostdomain() || $Net::Config::NetConfig{inet_domain};
if ( defined $DOMAIN_NAME && $DOMAIN_NAME ne '' ) {
    ($DOMAIN_NAME, @_dummy_) = split ':', $DOMAIN_NAME;
}
my $COOKIE_DOMAIN = $DOMAIN_NAME;
my $SERVER_NAME   = 'www';

# NOT YET IMPLEMENTED!
# Server Root relative directory containing HTML Templates files,
# could be overridden by Directory config NNTPGatewayTemplatesDir.
my $DEFAULT_TEMPLATES_DIR = "lib/templates/${NAMETAG}";

# See Actions_Map.
my $DEFAULT_ACTION_NAME   = 'last';

# If you badly configure this module here is what will be shown in the
# Organisation field of your posts ... nice!?
my $DEFAULT_ORGANIZATION  = 'The Disorganized Corp';

# HTML DECORATIONS
my $HTML_DTD        = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">";
my $BODY_BGCOLOR    = '#eeeeee';
my $HEADER_BGCOLOR1 = '#ccccdd';
my $HEADER_BGCOLOR2 = '#ddddee';
my $MENU_BGCOLOR    = 'silver';

# Css classes names
my $article_class          = "nntp:article";
my $article_id_class       = "$article_class:id";
my $article_subject_class = "$article_class:subject";
my $article_from_class    = "$article_class:from";
my $article_date_class    = "$article_class:date";


# Variables & So ---------------------------------------------------------

# $NNTP is the connection to the nntp server and it is a global so
# that the connection is common to all requests in the current Apache
# child process. The first problem is that the connection could be
# closed on timeout by the nntp server, but this is handled in
# NNTPConnect, since v0.7. The second problem which is not handled yet
# could occur when the module is used with 2 differents configs (in 2
# <location xxx>) setting 2 DIFFERENTS NEWSSERVERS and that 2 requests
# are made in the same child with these 2 configs (or more) ... just
# cross your fingers ;-). Remark: I could not test this latest
# potential pb because I've access to only 1 newsserver.
$NNTP = undef;

# Misc information about this module.
my $PKG_NAME      = __PACKAGE__ . " v${VERSION}";
my $PKG_AUTHOR    = 'heddy Boubaker &lt;boubaker@cpan.org&gt;';
my $PKG_COPYRIGHT = "${PKG_NAME} (&copy;) 2000-" .  (1900 + (localtime)[5]) . " CENA/SSS/${PKG_AUTHOR}";
my $PKG_HOMEPAGE  = 'http://www.tls.cena.fr/~boubaker/WWW/Apache-NNTPGateway.shtml';

# MESSAGES, stuff that is printed on the user's screen... The current default
# language: Should be an entry in Messages_Map & LANGS_OK
my $USR_LANG = 'fr';
#my $USR_LANG = 'en';
# Allowed languages choice.
my %LANGS_OK = ( 'fr' => 1, 'en' => 1 );

# All messages that could be printed.
my %Messages_Map =
  (
   'n_unread' =>{
    # format: nb-articles
    'en' => "%d unread article(s):",
    'fr' => "%d article(s) non lus:",
   },
   'no_unread' =>
   {
    'en' => "No unread articles",
    'fr' => "Pas d'articles non lus",
   },
   'no_arts' =>
   {
    'en' => "No articles in this group",  
    'fr' => "Pas d'articles dans ce groups", 
   },
   'no_new' =>
   {
    'en' => "No new unread articles",  
    'fr' => "Pas de nouveaux articles non lus", 
   }, 
   'no_ref' =>
   { 
    'en' => "No article reference id!", 
    'fr' => "Pas de numero d'article reference!", 
   }, 
   'no_id' =>
   {
    # format: article-id
    'en' => "Could not get article id %d, may have been canceled !", 
    'fr' => "Ne peut obtenir l'article No %d !", 
   },
   'inv_id' => 
   {  
    # format: article-id
    'en' => "Invalid Article id %d !", 
    'fr' => "No d'article %d invalide !", 
   },  
   'no_subject' => 
   {
    'en' => "[no subject given]",  
    'fr' => "[sans objet]", 
   }, 
   'no_body' => 
   {
    'en' => "[This message has an empty body]", 
    'fr' => "[Le corps de ce message est vide]", 
   },  
   'no_anon' => 
   {
    'en' => "Anonymous use not allowed for unidentified users", 
    'fr' => "Usage anonyme non permis pour les utilisateurs non identifiés", 
   },  
   'nyi' => 
   {
    # format: action-string
    'en' => "Sorry, function \"%s\" not yet implemented", 
    'fr' => "Désolé, fonction \"%s\" non implementée pour l'instant", 
   },  
   'disabled' => 
   {
    # format: action-string
    'en' => "Sorry, function \"%s\" disabled by administrator", 
    'fr' => "Désolé, fonction \"%s\" désactivée par l'administrateur", 
   },  
   'no_post_ok' => 
   {
    'en' => "Posting not allowed !", 
    'fr' => "Postage interdit !", 
   },  
   'post_warning' => 
   {
    'en' => "Make sure you are posting your message to the appropriate bulletin board !", 
    'fr' => "Tous les champs sont obligatoires !", 
   },  
   'all_fields' => 
   {
    'en' => "(All fields are mandatory)", 
    'fr' => "(Tous les champs sont obligatoires)", 
   },  
   'posted' => 
   {
    # format: newsgroup-string
    'en' => "Following message had been posted in %s", 
    'fr' => "Le message suivant à été posté dans %s", 
   },  
   'try_again' => 
   {
    'en' => "Try again later please...", 
    'fr' => "Essayez encore plus tard SVP...", 
   },  
   'retry_post' => 
   {
    'en' => "Message not posted, try again please", 
    'fr' => "Message non posté, essayez encore SVP", 
   },  
   'fullheaders' => 
   {
    'en' => "Full Headers", 
    'fr' => "Entête complète", 
   },  
   'nofullheaders' => 
   {
    'en' => "Less Headers", 
    'fr' => "Entête réduite", 
   },  
   'post' => 
   {
    'en' => "Post", 
    'fr' => "Poster", 
   },  
   'reset' => 
   {
    'en' => "Reset", 
    'fr' => "RAZ", 
   },  
   'prev' => 
   {
    'en' => "Prev", 
    'fr' => "Prec", 
   },  
   'next' => 
   {
    'en' => "Next", 
    'fr' => "Suivant", 
   },  
   'read' => 
   {
    'en' => "Read", 
    'fr' => "Lire", 
   },  
   'list' => 
   {
    'en' => "List", 
    'fr' => "Liste", 
   },  
   'last' => 
   {
    'en' => "Last", 
    'fr' => "Dernier", 
   },  
   'followup' => 
   {
    'en' => "Followup", 
    'fr' => "Donner&nbsp;Suite", 
   },  
   'subject' => 
   {
    'en' => "Subject", 
    'fr' => "Objet", 
   },  
   'from' => 
   {
    'en' => "From", 
    'fr' => "De", 
   },  
   'date' => 
   {
    'en' => "Date", 
    'fr' => "Date", 
   },  
   'back' => 
   {
    'en' => "Back", 
    'fr' => "Retour", 
   },  
   'error' => 
   {
    'en' => "Error", 
    'fr' => "Erreur", 
   },  
   'long_format' => 
   {
    'en' => "Long&nbsp;format", 
    'fr' => "Format&nbsp;long", 
   },  
   'short_format' => 
   {
    'en' => "Short&nbsp;format", 
    'fr' => "Format&nbsp;court", 
   },  
   'msg_cite' => 
   {
    # format: article-id, from
    'en' => "In article %s, %s wrote", 
    'fr' => "Dans l'article %s, %s écrivait", 
   },  
   'catchup_at' => 
   {
    # format: date-string
    'en' => "Catchup at %s, done", 
    'fr' => "Catchup le %s, effectué", 
   },  
   'no_catchup' => 
   {
    'en' => "Catchup function not enabled for this server", 
    'fr' => "La fonction Catchup n'est pas active pour ce serveur", 
   },  
   'list_all' => 
   {
    'en' => "List all articles, even already read", 
    'fr' => "Liste de tous les articles, même déjà lus", 
   },  
   'list_new' => 
   {
    'en' => "List new articles", 
    'fr' => "Liste des nouveaux articles", 
   },  
  );


# All possibles actions
my %Actions_Map = 
  (
   'list'     => \&action_list,
   'last'     => \&action_last,
   'read'     => \&action_read, 
   'followup' => \&action_followup, 
   'post'     => \&action_post, 
   'catchup'  => \&action_catchup, 
  );


# Action shown in main menu
my %Menu_Entries_Map =
  (
   'list' => 1, 
   'last' => 1, 
   'post' => 1, 
  );

# Action that are posting actions....
my %Post_Actions_Map =
  (
   'post'     => 1, 
   'followup' => 1, 
  );

# Unauthorized actions (configurable).
my %Disabled_Actions = ();

# Headers shown in headers=min
my %Used_Headers_Map =
  (
   'from'    => 1, 
   'date'    => 1, 
   'subject' => 1, 
  );

# Anonymous posters map (configurable).
my %Anonymous_Posters =
  (
   'anonymous' => 'Anonymous', 
  );

# Run time global vars: 

# All keys are lowercase: see get_args()...
my $Args   = {};

# Populated by get_config() ....
my %From_Posters           = ();
my $The_Action             = $DEFAULT_ACTION_NAME;
my $Title                  = $PKG_NAME;
my $NNTP_Server            = $DEFAULT_NEWS_SERVER;
my $The_Newsgroup          = undef;
my $The_GroupDescription   = undef;
my $NewsUrl                = "news://$NNTP_Server/$The_Newsgroup";
my $Base                   = '/';
my $StyleSheet             = '';
my $Anonymous_Post_Allowed = 0;
my $Organization           = $DEFAULT_ORGANIZATION;
my $Templates_Dir          = $DEFAULT_TEMPLATES_DIR;
my $Catchup_Cookie_Name    = undef;
my $The_User               = '';



# Subs decl --------------------------------------------------------------

sub handler ( $ );

sub action_list ( $ );
sub action_catchup ( $ );
sub action_last ( $\$ );
sub action_read ( $\$$ );
sub action_followup ( $\$ );
sub action_post ( $ );

sub print_html_article ( $$\$$$ );
sub print_html_article_menu ( $$\$ );
sub print_html_list_menu ( $$ );
sub print_html_post_form ( $\$$$ );
sub print_html_head ( $\@ );
sub print_html_foot ( $ );
sub print_html_menu ( $\$ );
sub print_html_error ( $\$$$ );
sub to_html ( $ );

sub nntp_connect ( $ );
sub nntp_post_article ( $$$\$ );
sub nntp_get_article ( $\$ );
sub print_nntp_error ( $$ );

sub get_args ( $ );
sub get_config ( $ );
sub check_user ( $ );
sub message ( $\@ );
sub is_true ( $ );
sub is_false ( $ );
sub parse_from ( $ );



# The Apache mod_perl handler --------------------------------------------


sub handler ( $ ) {

  # using Apache::Request is better ...
  my $r = Apache::Request->new(shift);

  # Do not bother with HEAD requests
  return DECLINED if $r->header_only();
  # Do not bother with internal sub-requests
  return DECLINED unless $r->is_main();
  # Configuration tell to Stop it now ...
  return DECLINED if &is_true( $r->dir_config( 'NNTPGatewayStop' ));

  # Get misc args && config
  return SERVER_ERROR unless &get_config( $r );
  return SERVER_ERROR unless &get_args( $r );
  
  # Check username ... The handling and printing of possible errors is
  # done withing the sub.
  return OK unless &check_user( $r );

  # What asked to do ?
  $The_Action = $Args->{action};
  $The_Action = $DEFAULT_ACTION_NAME unless exists $Actions_Map{$The_Action};
  if ( $Disabled_Actions{$The_Action} ) {
    $r->log->warn( "${Base}: $The_User\@", 
                   $r->get_remote_host(), 
                   " trying to execute a disabled action: $The_Action" );
    # Action disabled by config, print a message to prevent the user
    # and exit.
    &print_html_head( $r );
    &print_html_error( $r, &message('disabled', &message( $The_Action )), undef );
    &print_html_foot( $r );
    return OK;
  }
  
  # Connecting to the newsserver ... The handling and printing of
  # possible errors is done withing the sub.
  return OK unless &nntp_connect( $r );

  # Execute action ...
  $r->log->info( "Executing action $The_Action ..." ) if $DEBUG;
  &{$Actions_Map{$The_Action}}( $r );

  return OK; 
} # handler() ends here...




# Actions -----------------------------------------------------------


### Sub action_list() ###
# &action_list( request ):
# - Description: List all articles in the group ...
# - Arguments  : the Apache request
###
sub action_list  ( $ ) {
  my ($r) = @_;

  # Print html headers, do not cache list.
  &print_html_head( $r, 1 );
  # Print menu
  &print_html_menu( $r );

  my $force = &is_true( $Args->{force} );  
  unless ( $force ) {
    # Check range of articles to display, see get_args() for cookies
    # parsing, and action_catchup for cookies setting.
    my $catchupdate = $Args->{catchup_date};
    my $catchupid   = $Args->{catchup_id};
    my $rnews       = undef;
    $rnews = $NNTP->newnews( $catchupdate, $The_Newsgroup ) if $catchupdate;
    if ( $rnews ) {
      $r->log->info( "New news: ", @$rnews, ", since $catchupdate" ) if $DEBUG;
      # Things to do here, HELP ME! I have no way to test this feature
      # as the newnews command had been disabled by the newsserver
      # administrator here...
      #$Args->{first_art} = $rnews->[0]???
      $Args->{first_art} = $catchupid +1;
    } elsif ( $catchupid ) {
      # The main reason to get here is that the newsserver
      # administrator disabled the newnews command, villain!
      $Args->{first_art} = $catchupid +1;
    }
  }
  my $first_art = $Args->{first_art};
  my $last_art  = $Args->{last_art};
  my $n_arts    = ($last_art - $first_art) +1;
  $r->log->notice( "Listing $n_arts articles from $first_art to $last_art..." ) if $DEBUG;

  if ( $n_arts > 0 ) {

    # Some articles to display...
    &print_html_list_menu( $r, $n_arts );
    $r->print( "\n<hr noshade>\n" );
    my $i = $first_art;
    for ( ; $i <= $last_art; $i++ ) {
      # All articles are got now one by one from the newsserver,
      # remember this is not a real newsreader we will not build
      # threads trees here we've no time for that. But a powerful
      # patch to do that will be welcome anyway ;-)
      my $Article = &nntp_get_article( $i, 1 );
      if ( $Article ) {
        &print_html_article( $r, $Article, 1, &is_true( $Args->{long} ));
      } else {
        $r->print( "<span id=\"bad_id\"><strong>", &message('no_id', $i ), "</strong></span><br>\n" );
      }
    }
    # Print the list menu
    $r->print( "\n<hr noshade>\n" );
    &print_html_list_menu( $r, $n_arts );

  } else {

    # No articles to display...
    &print_html_list_menu( $r, $n_arts );

  }

  # Print global menu
  &print_html_menu( $r );
  # Print html footer
  &print_html_foot( $r );
  return;

} # end action_list();


### Sub action_catchup() ###
# &action_catchup( request ):
# - Description: Mark all articles in the group as read.
# - Arguments  : the Apache request
###
sub action_catchup ( $ ) {
  my ($r) = @_;
  
  # Prepare catchup...
  my $catchupid   = $Args->{last_art};
  my $catchupdate = $NNTP->date();
  my $newnewsok   = $NNTP->newnews( $catchupdate, $The_Newsgroup )?1:0;

  # Build the catchup cookie
  my $cookie      = new CGI::Cookie 
    ( 
     -name    => $Catchup_Cookie_Name, 
     -value   => "Id=${catchupid},Date=${catchupdate}", 
     # 10 years should be enough as expiration date.
     -expires => '+10y', 
     -domain  => $COOKIE_DOMAIN, 
     -path    => $Base
    );
  $r->header_out( 'Set-Cookie' => $cookie );

  # Print html header
  &print_html_head( $r, 1 );
  # Print menu
  &print_html_menu( $r );
  $r->print( "\n<hr noshade>\n" );

  # Just Inform user
  $r->print
    ( 
     "<h2 align=\"center\">${NewsUrl}<br>\n<font color=\"red\">", 
     &message( 'catchup_at', scalar( localtime( $catchupdate ))), 
     "</font></h2>\n", 
     "<div align=\"center\">[<a href=\"${Base}/list?force=1\">", 
     &message( 'list_all' ), 
     "</a>]</div>\n" 
    );

  # Print menu
  $r->print( "\n<hr noshade>\n" );
  &print_html_menu( $r );
  # Print html footer
  &print_html_foot( $r );
  return;

} # end action_catchup();


### Sub action_last() ###
# &action_last( request [, force] ):
# - Description: Print last article in the group.
# - Arguments  : the Apache request
###
sub action_last ( $\$ ) {
  my ($r, $force) = @_;
  my $id_last = $Args->{last_art};
  # Everything is handled by action_read with ID of last article. And
  # as last article could always change caching is not allowed.
  &action_read( $r, $id_last, 1 );
  return;

} # end action_last();


### Sub action_read() ###
# &action_read( request [, id, no-cache] ):
# - Description: Print article given it's Id.
# - Arguments  : the Apache request, article id to read
###
sub action_read ( $\$$ ) {
  my ($r, $id, $no_cache ) = @_;

  # Get id of article to read
  my $args = $Args->{action_args};
  if ( $args && @$args ) {
    # id of article to read
    $id ||= $args->[0];
  } else {
    $id ||= $Args->{last_art};
  }

  # Get the article and print it.
  my $Article = &nntp_get_article( $id );
  if ( $Article ) {

    # Got it!
    my $title = $Article->{Header}{subject} || "article $id";
    &print_html_head( $r, $no_cache, $title );
    &print_html_menu( $r );
    &print_html_article( $r, $Article, 0, 
                         $Args->{headers} eq 'max', 
                         $Args->{showsig} );
  } else {

    # invalid article id
    &print_html_head( $r, $no_cache, &message( 'inv_id', $id ));
    &print_html_menu( $r );
    &print_html_error( $r, &message( 'inv_id', $id ));
  }

  # Print menu
  &print_html_menu( $r );
  # Print html footer
  &print_html_foot( $r );
  return;

} # end action_read();


### Sub action_followup() ###
# &action_followup( request [, id] ):
# - Description: Post a followup to an article
# - Arguments  : The Apache request, article id to followup
###
sub action_followup ( $\$ ) {
  my ($r, $id) = @_;

  # Print html header
  &print_html_head( $r );
  # Print menu
  &print_html_menu( $r );
  $r->print( "\n<hr noshade>\n" );

  # Get article Id to followup.
  my $args = $Args->{action_args};
  if ( $args && @$args ) {
    # id of article to read
    $id ||= $args->[0];
  } elsif ( $id ) {
    ;
  } else {
    &print_html_error( $r, &message( 'no_ref' ));
    # Print menu
    $r->print( "\n<hr noshade>\n" );
    &print_html_menu( $r );
    # Print html footer
    &print_html_foot( $r );
    return;
  }

  # Get the article to followup.
  my $Article  = &nntp_get_article( $id, 0 );
  if ( $Article ) {

    # Prepare new subject
    my $subject = $Article->{Header}{subject};
    $subject = "Re: $subject" unless $subject =~ /^re\s*:/i;
    # Add references
    my $refs  = $Article->{Header}{references};
    my $msgid = $Article->{Header}{'message-id'};
    $refs .= $msgid;
    # Quote body
    my $body = "\n " . &message( 'msg_cite', $msgid, $Article->{Header}{from} ) . ":\n\n";
    $Article->{Body} =~ s/^\s*(.*)$/ > $1/gm;
    $body .= $Article->{Body} . "\n\n";
    # Print a form for user to edit fields and post.
    &print_html_post_form( $r, $subject, $body, $refs );
    # The remaining, that is the real NNTP posting is handled by
    # action_post() which is called from a submit (POST method) with
    # the form with the right arguments.

  } else {

    # invalid article id
    &print_html_error( $r, &message( 'inv_id', $id ));
  }

  # Print menu
  $r->print( "\n<hr noshade>\n" );
  &print_html_menu( $r );
  # Print html footer
  &print_html_foot( $r );
  return;

} # end action_followup();


### Sub action_post() ###
# &action_post( request ):
# - Description: Post an article
# - Arguments  : The Apache request
###
sub action_post ( $ ) {
  my ($r) = @_;

  # Print html header
  &print_html_head( $r );
  # Print menu
  &print_html_menu( $r );
  $r->print( "\n<hr noshade>\n" );

  # Check if nntp server allow us to post.
  unless ( $NNTP->postok()) {
    &print_html_error( $r, &message( 'no_post_ok' ));
    # Print menu
    $r->print( "\n<hr noshade>\n" );
    &print_html_menu( $r );
    # Print html footer
    &print_html_foot( $r );
    return;
  }

  if ( $r->method() eq 'POST' ) {

    # This part is called when user submit the form that had been
    # shown him within an action_post() but with a GET method. NNTP
    # Post the article from here.
    my $from    = $Args->{from};
    my $subject = $Args->{subject};
    my $body    = $Args->{body};
    my $refs    = $Args->{refs};

    # Jie's modification for WASM authentication check.
#    unless (defined $from && $from eq $ENV{'USER_NAME'}) {
#      &print_html_error( $r, &message( 'You are only allowed to post as yourself.' ));
#      &print_html_post_form( $r, $subject, $body );
#      $r->print( "\n<hr noshade>\n" );
#      &print_html_menu( $r );
#      # Print html footer
#      &print_html_foot( $r );
#      return;
#    }

    unless ( $from && $body && $subject ) {
      # From && Body && Subject are required
      &print_html_error( $r, &message( 'retry_post' ));
      &print_html_post_form( $r, $subject, $body );
      # Print menu
      $r->print( "\n<hr noshade>\n" );
      &print_html_menu( $r );
      # Print html footer
      &print_html_foot( $r );
      return;
    }

    my $from_name = $From_Posters{$from};
    $from .= "\@" . $DOMAIN_NAME unless $from =~ /\@.+/;
    $from .= " ($from_name)" if $from_name;

    # Do post the article here
    $r->log->notice( "Posting message \"$subject\" to $NewsUrl..." );
    if ( &nntp_post_article( $subject, $from, $body, $refs )) {

      # Print confirmation
      $r->print
        (
         "<table width=\"100%\">\n", 
         "\t<caption><strong>", &message( 'posted', $NewsUrl ), "</strong></caption>\n", 
         "\t<tr>\n", 
         "\t\t<td width=\"5%\"><strong><u>", &message('from'), "</u>:</strong></td>\n", 
         "\t\t<td bgcolor=\"$HEADER_BGCOLOR1\"><span class=\"$article_from_class\">$from</span></td>\n", 
         "\t</tr>\n", 
         "\t<tr>\n", 
         "\t\t<td width=\"5%\"><strong><u>", &message('subject'), "</u>:</strong></td>\n", 
         "\t\t<td bgcolor=\"$HEADER_BGCOLOR1\"><span class=\"$article_subject_class\">$subject</span></td>\n", 
         "\t</tr>\n", 
         "\t<tr>\n", 
         "\t\t<td colspan=\"2\" bgcolor=\"$BODY_BGCOLOR\"><pre>$body</pre></td>\n", 
         "\t</tr>\n", 
         "</table>\n", 
        );
    } else {
      # Post failed
      &print_html_error( $r, &message( 'no_post_ok' ));
    }
    
  } else {

    # In a GET method: Print the form to post the article
    &print_html_post_form( $r );
    # The real nntp post is handled here when the method, invoked from
    # a submit in the post form, is a POST.

  }

  # Print menu
  $r->print( "\n<hr noshade>\n" );
  &print_html_menu( $r );
  # Print html footer
  &print_html_foot( $r );
  return;

} # end action_post();




# HTML Utilities ----------------------------------------------------


### Sub print_html_article() ###
# &print_html_article( args ):
# - Description:
# - Arguments  :
###
sub print_html_article ( $$\$$$ ) {
  my ($r, $A, $header_only, $fullheaders, $showsig) = @_;
  my $id = $A->{Id};
  $r->print( "\n<!-- article $id -->\n" );
  if ( $header_only && $fullheaders ) {

    # Print one line only article but with some more headers
    $r->print
      (
       "<table width=\"100%\">\n", 
       "\t<tr>\n", 
       "\t<td bgcolor=\"$HEADER_BGCOLOR2\" width=\"15%\">\n", 
       "\t\t<font size=\"-1\"><a name=\"__${id}__\">${id}</a>:&nbsp;", 
       "[<a href=\"${Base}/read/${id}\">", &message('read'), "</a>]", 
       "[<a href=\"${Base}/followup/${id}\">", &message('followup'), "</a>]", 
       "</font></td>\n", 
       "\t<td bgcolor=\"$HEADER_BGCOLOR1\" align=\"center\" width=\"30%\">\n", 
       "\t\t",
       "<span class=\"$article_date_class\"><font size=\"-1\"><em>", $A->{Header}{date}, "</em></font></span>", 
       "</td>\n", 
       "\t<td bgcolor=\"$HEADER_BGCOLOR1\" align=\"center\">\n", 
       "\t\t<font size=\"-1\"><em><a href=\"mailto:", $A->{Header}{_from_email}, "\">", 
       "<span class=\"$article_from_class\"><strong>", $A->{Header}{_from_name}, "</strong></span>", 
       "</a></em></font></td>\n", 
       "\t</tr>\n", 
       "\t<tr>\n", 
       "\t<td align=\"right\" width=\"15%\"><font size=\"-1\"><em>", 
       $A->{Header}{lines}, " lines</em></font>&nbsp;</td>\n", 
       "\t<td colspan=\"2\" bgcolor=\"$BODY_BGCOLOR\">&nbsp;&quot;<a href=\"${Base}/read/${id}\">", 
       "<span class=\"$article_subject_class\">", $A->{Header}{_subject_html}, "</span>", 
       "</a>&quot;</td>\n", 
       "\t</tr></table>\n", 
      );

  } elsif ( $header_only ) {

    # Print one line only article
    $r->print
      (
       "<div class=\"$article_class\">",
       "<span class=\"$article_id_class\"><strong><a name=\"__${id}__\">$id</a></strong></span>", 
       ":&nbsp;&quot;<a href=\"${Base}/read/${id}\">", 
       "<span class=\"$article_subject_class\"><em>", $A->{Header}{_subject_html}, "</em></span>", 
       "</a>&quot;&nbsp;", lc(&message('from')), "&nbsp;",
       "&lt;<a href=\"mailto:", $A->{Header}{_from_email}, "\">", 
       "<span class=\"$article_from_class\"><font size=\"-1\">", $A->{Header}{_from_name}, "</font></span>", 
       "</a>&gt;<br>",
       "</div>\n", 
      );

  } else {

    # Print the full article
    $r->print( "<table width=\"100%\"><a name=\"__${id}__\">&nbsp;</a>\n", );
    &print_html_article_menu( $r, $A, 1 );
    $r->print
      (
       "\t<tr>\n",
       "\t<td><strong><u>", &message('from'), "<u>:</strong></td>\n", 
       "\t<td bgcolor=\"$HEADER_BGCOLOR1\"><a href=\"mailto:", 
       $A->{Header}{_from_email}, "?Subject=Re:%20", $A->{Header}{_subject_html}, "\">", 
       "<span class=\"$article_from_class\">", $A->{Header}{_from_name}, "</span>", 
       "</a></td>\n",
       "\t</tr>\n", 
       "\t<tr>\n",
       "\t<td><strong><u>", &message('date'), "<u>:</strong></td>\n", 
       "\t<td bgcolor=\"$HEADER_BGCOLOR1\">", 
       "<span class=\"$article_date_class\">", $A->{Header}{date}, "</span>", 
       "</td>\n", 
       "\t</tr>\n", 
       "\t<tr>\n",
       "\t<td><strong><u>", &message('subject'), "<u>:</strong></td>\n", 
       "\t<td bgcolor=\"$HEADER_BGCOLOR1\">", 
       "<span class=\"$article_subject_class\"><strong>", $A->{Header}{_subject_html}, "</strong></span>", 
       "</td>\n", 
       "\t</tr>\n", 
      );

    if ( $fullheaders ) {

      # Print all headers
      foreach ( keys( %{$A->{Header}} )) {
        # Do not print already printed headers and private internals _headers.
        next if exists $Used_Headers_Map{$_} || $_ =~ /^_/; 
        $r->print
          (
           "\t<tr>\n", 
           "\t<td><em><u>$_</u>:</em></td>\n", 
           "\t<td bgcolor=\"$HEADER_BGCOLOR2\">", $A->{Header}{$_}, "</td>\n", 
           "\t</tr>\n", 
          );
      }
      $r->print
        (
         "\t<tr>\n",
         "\t<td colspan=\"2\"><font size=\"-1\">", 
         "[<a href=\"${Base}/read/${id}?headers=min\">", &message('nofullheaders'), "</a>]", 
         "</font></td>\n",
         "\t</tr>\n", 
        );
    } else {
      $r->print
        (
         "\t<tr>\n",
         "\t<td colspan=\"2\"><font size=\"-1\">", 
         "[<a href=\"${Base}/read/${id}?headers=max\">", &message('fullheaders'), "</a>]", 
         "</font></td>\n", 
         "\t</tr>\n", 
        );
    }
    # The body here ...
    $r->print
      (
       "\t<tr>\n", 
       "\t<td colspan=\"2\"><hr><pre><font size=\"+1\">", $A->{Body}, "</font></pre>\n", 
      );
    # The .sig ...
    if ( $A->{Signature} ) {
      if ( $showsig ) {
        $r->print( "<a href=\"${Base}/read/${id}?showsig=0\">--</a>\n" );
        $r->print( "<pre><font size=\"-1\" color=\"white\"><i>", $A->{Signature}, "</i></font></pre>\n" );
      } else {
        $r->print( "<a href=\"${Base}/read/${id}?showsig=1\"><b>--</b></a>\n" );
      }
    }

    $r->print( "<hr></td>\n\t</tr>\n" );
    &print_html_article_menu( $r, $A, 1 );
    $r->print( "</table>\n" );

  }
  $r->print( "\n<!-- /article $id -->\n" );
  return;

} # end print_html_article();



### Sub print_html_article_menu() ###
# &print_html_article_menu( request, Article, in_table ):
# - Description:
# - Arguments :
# - Return    :
###
sub print_html_article_menu ( $$\$ ) {
  my ($r, $A, $table) = @_;
  my $id = $A->{Id};
  $r->print
    (
     "\t<tr>\n", 
     "\t<td><u>Article Id</u>:&nbsp;<strong>$id</strong>:</td>\n", 
     "\t<td bgcolor=\"$MENU_BGCOLOR\">\n", 
    ) if $table;
  $r->print( "\t\t<font color=\"blue\" size=\"-1\">\n" );
  unless ( $Disabled_Actions{'read'} ) {
    if ( $A->{Header}{_prev} ) {
      $r->print( "\t\t&lt;<a href=\"${Base}/read/", $A->{Header}{_prev}, "\">", 
                 &message('prev'), "</a>&lt;\n" );
    } else {
      $r->print( "\t\t&lt;<em>", &message('prev'), "</em>&lt;\n" );
    }
  }
  $r->print( 
            "\t\t[<a href=\"${Base}/followup/${id}\">",     
            &message('followup'), "</a>]\n",
            ) unless $Disabled_Actions{'followup'};
  $r->print( 
            "\t\t[<a href=\"${Base}/list?force=1#__${id}__\">",     
            &message('list'),     "</a>]\n", 
            ) unless $Disabled_Actions{'list'};
  unless ( $Disabled_Actions{'read'} ) {
    if ( $A->{Header}{_next} ) {
      $r->print( "\t\t&gt;<a href=\"${Base}/read/", $A->{Header}{_next}, "\">", 
                 &message('next'),  "</a>&gt;\n" );
    } else {
      $r->print( "\t\t&gt;<em>", &message('next'), "</em>&gt;\n" );
    }
  }
  $r->print( "\t</font>\n" );
  $r->print
    (
     "\t</td>\n", 
     "\t</tr>\n", 
    ) if $table;
  return;

} # end print_html_article_menu();



### Sub print_html_list_menu() ###
# &print_html_list_menu( request ):
# - Description:
# - Arguments :
# - Return    :
###
sub print_html_list_menu ( $$ ) {
  my ($r, $n_arts) = @_;
  my $long      = &is_true( $Args->{long} );
  my $force     = &is_true( $Args->{force} );
  my $long_arg  = $long?"long=1":"long=0";
  my $force_arg = $force?"force=1":"force=0";

  $r->print( "\n<table width=\"100%\" align=\"center\"><tr><td width=\"20%\">" );
  if ( $force && $n_arts > 0 ) {
    $r->print( "<strong>$n_arts&nbsp;articles<strong>" );
  } elsif ( $n_arts > 0 ) {
    $r->print( "<strong>", &message( 'n_unread', $n_arts ), "</strong>" );
  } else {
    $r->print( "<font color=\"red\">", &message( 'no_unread' ), "</font>" );
  }

  $r->print( "</td><td align=\"center\" bgcolor=\"$MENU_BGCOLOR\">&nbsp;" );
  if ( $n_arts > 0 ) {
    if ( $long ) {
      $r->print( "[<a href=\"${Base}/list?long=0&${force_arg}\">", &message( 'short_format' ), "</a>]&nbsp;\n" );
    } else {
      $r->print( "[<a href=\"${Base}/list?long=1&${force_arg}\">", &message( 'long_format' ),  "</a>]&nbsp;\n" );
    }
  }
  if ( $force & $n_arts <= 0 ) {
    $r->print( "<font color=\"red\">", &message( 'no_arts' ), "<font>" );
  } elsif ( $force ) {
    $r->print( "[<a href=\"${Base}/list?force=0&${long_arg}\">", &message( 'list_new' ),     "</a>]&nbsp;\n" );
  } else {
    $r->print( "[<a href=\"${Base}/list?force=1&${long_arg}\">", &message( 'list_all' ),     "</a>]&nbsp;\n" );
  }
  if ( $n_arts > 0 ) {
    $r->print( "[<a href=\"${Base}/catchup\">Catchup</a>]&nbsp;\n" ) unless $Disabled_Actions{catchup};
  }
  $r->print( "</td>\n</tr></table>\n" );

  return;

} # end print_html_list_menu();



### Sub print_html_post_form() ###
# $ret = &print_html_post_form( args ):
# - Description:
# - Arguments :
# - Return    :
###
sub print_html_post_form ( $\$$$ ) {
  my ($r, $subject, $body, $refs) = @_;
  $r->print( 
            "<table width=\"100%\">\n", 
            "\t<form method=\"POST\" action=\"${Base}/post\">\n", 
            "\t<tr>\n", 
            "\t<td>&nbsp;</td>\n", 
            "\t<td><font size=\"-1\" color=\"red\"><strong>", &message('all_fields'), "</strong></font></td>\n", 
            "\t</tr>\n", 
            );
  $r->print( "<input type=\"hidden\" name=\"refs\" value=\"$refs\">" ) if $refs;
  # Build a choice of From
  $r->print( 
            "\t<tr>\n", 
            "\t<td width=\"5%\"><strong><u>", &message('from'), "</u>:</strong></td>\n", 
            "\t<td bgcolor=\"$HEADER_BGCOLOR2\"><select name=\"from\">", 
            );
  foreach (keys %From_Posters) {
    $r->print( "<option value=\"$_\">", $From_Posters{$_} );
  }
  $r->print( 
            "</select></td>\n", 
            "\t</tr>\n", 
            );

  # Subject & Body fields
  $r->print( 
            "\t<tr>\n", 
            "\t<td width=\"5%\"><strong><u>", &message('subject'), "</u>:</strong></td>\n", 
            "\t<td bgcolor=\"$HEADER_BGCOLOR2\">\n", 
            "\t\t<input type=\"textfield\" name=\"subject\" value=\"$subject\" size=\"60\" maxlength=\"80\">\n", 
            "\t</td>\n", 
            "\t</tr>\n", 
            "\t<tr>\n", 
            "\t<td>&nbsp;</td>\n", 
            "\t<td bgcolor=\"$BODY_BGCOLOR\">\n", 
            "\t\t<textarea name=\"body\" wrap=\"hard\" rows=\"20\" cols=\"60\">$body</textarea>\n", 
            "\t</td>\n", 
            "\t</tr>\n", 
            "\t<tr>\n", 
            "\t<td colspan=\"2\" align=\"center\"><input type=\"submit\" value=\"", 
            &message('post'), "\"><input type=\"reset\" value=\"", &message('reset'), "\"></td>\n", 
            "\t</tr>\n", 
            "\t</form></table>\n", 
            );
  return;

} # end print_html_post_form();



### Sub print_html_head() ###
# &print_html_head( request ):
# - Description:
# - Arguments :
# - Return    :
###
sub print_html_head ( $\@ ) {
  my ( $r, $no_cache, $extra_title ) = @_;
  my $title = $Title;
  $title .= ": $extra_title" if $extra_title;
  $r->content_type( 'text/html' );
  # Goood, but some more efforts are needed ...
  $r->no_cache($no_cache?1:0);
  $r->send_http_header();
  $r->print( 
            "\n\n${HTML_DTD}\n", 
            "<html>\n", 
            "<head>\n", 
            "<title>${title}</title>\n", 
             $StyleSheet?"<LINK REL=StyleSheet HREF=\"$StyleSheet\" TYPE=\"text/css\">":"<!-- no StyleSheet -->", 
             "</head>\n", 
            "<body bgcolor=\"$BODY_BGCOLOR\">\n", 
            "<a name=\"TOP\">&nbsp;</a>\n", 
            "<hr noshade>\n", 
            "<div align=\"right\" class=\"head\"><font size=\"-1\">\n", 
            "\t<a href=\"$Base\">$PKG_NAME</a>&nbsp;\@&nbsp;<a href=\"$NewsUrl\">$NewsUrl</a>\n", 
            "</font></div>\n", 
            "<h1 align=\"right\" class=\"title\"><a href=\"$Base\">${title}</a></h1>\n", 
            
           );
  $r->print( "<h3 align=\"right\">($The_GroupDescription)</h3>\n" ) if $The_GroupDescription;

  return;
} # end print_html_head();



### Sub print_html_foot() ###
# &print_html_foot( request ):
# - Description:
# - Arguments : the request
###
sub print_html_foot ( $ ) {
  my ($r) = @_;
  $r->print( 
            "<hr noshade>\n", 
            "<div align=\"right\" class=\"copyright\"><em><a href=\"$PKG_HOMEPAGE\">$PKG_COPYRIGHT</a></em></div>\n", 
            "<hr noshade>\n", 
            "</body></html>\n", 
           );
  return;
} # end print_html_foot();



### Sub print_html_menu() ###
# &print_html_menu( request [, action] ):
# - Description:
# - Arguments : the request, the current action.
###
sub print_html_menu ( $\$ ) {
  my ($r, $action) = @_;
  $action ||= $The_Action;
  $r->print( "\n<table width=\"100%\" align=\"center\"><tr><td bgcolor=\"$MENU_BGCOLOR\" align=\"center\">" );
  foreach ( keys %Actions_Map ) {
    next unless $Menu_Entries_Map{$_};
    next if $Disabled_Actions{$_};
    my $Aname = &message($_);
    $Aname = $_ =~ s/^([a-z]{1,1})/uc( $1 )/e unless $Aname;
    if ( $_ eq $action ) {
      $r->print( "<font color=\"red\">[&nbsp;${Aname}&nbsp;]</font>" );
    } else {
      $r->print( "<font color=\"blue\">[&nbsp;<a href=\"${Base}/$_\">${Aname}</a>&nbsp;]</font>" ); 
    } 
  }
  $r->print( "</td></tr></table>\n" );
  return;

} # end print_html_menu();



### Sub print_html_error() ###
# $ret = &print_html_error( args ):
# - Description:
# - Arguments :
# - Return    :
###
sub print_html_error ( $\$$$ ) {
  my ($r, $h1, $err, $msg) = @_;
  $h1  ||= &message('error');
  $r->print(
            "<h1 align=\"center\">$h1</h1>\n<p>", 
            $err?"<div align=\"center\" class=\"error\"><font color=\"red\"><strong>$err</strong></font></div><p>\n":"", 
           );
  return;
} # end print_html_error();



### Sub to_html() ###
# $ret = &to_html( args ):
# - Description:
# - Arguments :
# - Return    :
###
sub to_html ( $ ) {
  my $v = shift;
  $v =~ s/&/&amp;/g;#this should be the 1st one!!
  $v =~ s/</&lt;/g;
  $v =~ s/>/&gt;/g;
  $v =~ s/\s+/&nbsp;/g;
  $v =~ s/\"/&quot;/g;
  return $v;
} # end to_html();




# NNTP Utilities ----------------------------------------------------


### Sub nntp_connect() ###
# status = &nntp_connect( request ):
# - Description: Try hardly to connect to the nntp server.
# - Arguments  : the Apache request
# - Return     : 1=ok, 0=failure
###
sub nntp_connect ( $ ) {
  my $r = shift;
  my $already_tried = 0;
 NNTPConnect:
  unless ( $NNTP ) {
    $r->log->notice( "($$) Connecting to $NewsUrl ..." ) if $DEBUG;
    $already_tried = 1;
    # Not yet connected or disconnected
    $NNTP = new Net::NNTP( $NNTP_Server, 'Debug' => $DEBUG?1:0 );
    unless ( $NNTP ) {
      &print_nntp_error( $r, "Could not connect to NNTP Server $NNTP_Server."  );
      $NNTP = undef;
      return 0;
    }
  } elsif ( not( $NNTP->connected()) && 
            not( $already_tried )) {
    # Timed out connection
    $r->log->notice( "($$) Reconnecting old NNTP connection ..." ) if $DEBUG;
    # $NNTP->connect( ... ); # Buggy!!!
    $NNTP->quit();
    $NNTP = undef;
    goto NNTPConnect;
  } else {
    $r->log->notice( "($$) Reusing old NNTP connection ..." ) if $DEBUG;
  }
  #my $NNTP_HOST = $NNTP->sockhost();
  #my $NNTP_PORT = $NNTP->sockport();

  # Setting newsgroup && getting articles IDs
  my($n_arts, $first_art, $last_art) = ($NNTP->group( $The_Newsgroup ));
  unless ( defined $first_art && defined $last_art ) {
    unless ( $already_tried ) {
      $r->log->warn( "Could not get newsgroup $The_Newsgroup from $NNTP_Server, trying once again..." );
      # Maybe a timeout ... try again once. This should have been
      # handled above in the test for not $NNTP->connected(), but this
      # is just to be sure.
      $NNTP->quit();
      $NNTP = undef;
      # Yes !!! a goto !!
      goto NNTPConnect;
    }
    &print_nntp_error( $r, "Could not open NNTP group $The_Newsgroup from $NNTP_Server." );
    $NNTP->quit();
    $NNTP = undef;
    return 0;
  }
  $r->log->info( "($$) Connected to $NewsUrl (Articles: $first_art .. $last_art)." ) if $DEBUG;
  $Args->{last_art}  = $last_art;
  $Args->{first_art} = $first_art;
  return 1;

} # end nntp_connect();



### Sub nntp_post_article() ###
# status = &nntp_post_article( $subject, $from, $body[, $refs] ):
# - Description: Post the article to the current nntp server/group...
# - Arguments  : $subject, $from, $body [, $refs]
# - Return     : 1=success, 0=failure
###
sub nntp_post_article ( $$$\$ ) {
  my ($subject, $from, $body, $refs) = @_;
  my @article;
  push( @article, "Subject: ${subject}\n" );
  push( @article, "From: ${from}\n" );
  push( @article, "Newsgroups: ${The_Newsgroup}\n" );
  push( @article, "References: ${refs}\n" ) if $refs;
  push( @article, "Organization: ${Organization}\n" );
  push( @article, "X-NewsReader: ${PKG_NAME}\n" );
  push( @article, "X-Url: http://${SERVER_NAME}${Base}\n" );
  push( @article, "\n" );
  # Add signature
  $body .= "\n--\n\n - ${from} with ${PKG_NAME} -\n - http://${SERVER_NAME}${Base} -\n";
  push( @article, $body );
  push( @article, "\n" );
  my $status = $NNTP->post( \@article );
  if ( $status == CMD_ERROR || 
       $status == CMD_REJECT ) {
    return 0;
  }
  return 1;

} # end nntp_post_article();


### Sub nntp_get_article() ###
# $Article = &nntp_get_article( id, header-only ):
# - Description: 
# - Arguments  : Article id, get headers only
# - Return     : ref to article hash
###
sub nntp_get_article ( $\$ ) {
  my ($id, $header_only) = @_;
  my $head = $NNTP->head( $id );
  return undef unless $head;
  # We got it! Parse it to build a nice easy Perl object
  my %Article;
  foreach ( @$head ) {
    my ($k, $v) = $_ =~ /^([^:]+)\s*:\s*(.*)/;
    $k = lc( $k );
    $Article{Header}{ $k } = $v;
    if ( $k eq 'from' ) {
      $Article{Header}{_from_html} = &to_html( $v );
      my ($email, $name) = &parse_from( $v );
      $Article{Header}{_from_email} = $email || $v;
      $Article{Header}{_from_name}  = $name  || $Article{Header}{_from_html};
    } elsif ( $k eq 'subject' ) {
      $Article{Header}{_subject_html} = &to_html( $v );
    }
  }
  # Get previous article id:
  if ( exists $Article{Header}{references} ) {
    my @refs = split( '\s', $Article{Header}{references} );
    my ($prev) = $refs[$#refs] =~ /<([^>]+)>/;
    $Article{Header}{'x-followup-of'} = $prev if $prev;
  }   
  if ( $Args->{first_art} <= ($id -1)) {
    $Article{Header}{_prev} = $id -1;
  }
  # Get next article id:
  if ( $Args->{last_art} >= ($id +1)) {
    $Article{Header}{_next} = $id +1;
  }
  # Get all the article if needed
  unless ( $header_only ) {
    my $body = $NNTP->body( $id );
    my $b = '';
    if ( @$body ) {
      $b = join( '', @$body );
      # Try to extract Signature ... 
      my ($b2, $s) = $b =~ /^(.*)[\s\n]*\n+-{2,3}[ \t\r\f]*\n+(.*)/sm;
      if ( $b2 && $s ) {
        $b = $b2;
        # Made texts links in signature to clickable links
        $s =~ s/(\w+:\/\/\S+)/<a href=\"$1\" target=\"_top\">$1<\/a>/sgm;
        $s =~ s/\s((www|w3)\.[a-z0-9][a-z0-9\.]?\.[a-z]{2,3})\b/<a href=\"http:\/\/$1\/\" target=\"_top\">$1<\/a>/isgm;
        $s =~ s/\s+$//;
        $Article{Signature} = $s;
      }
    } else {
      $b = &message( 'no_body' );
    }
    # Made texts links in body to clickable links
    $b =~ s/(\w+:\/\/\S+)/<a href=\"$1\" target=\"_top\">$1<\/a>/sgm;
    $b =~ s/\s((www|w3)[-a-z_]*\.[a-z0-9][-a-z0-9_\.]?\.[a-z]{2,3})\b/<a href=\"http:\/\/$1\/\" target=\"_top\">$1<\/a>/isgm;
    $Article{Body} = $b;
  }
  $Article{Id} = $id;
  $Article{Header}{subject} = &message( 'no_subject' ) unless $Article{Header}{subject};
  return \%Article;

} # end nntp_get_article();



### Sub print_nntp_error() ###
# &print_nntp_error( request, error ):
# - Description:
# - Arguments  :
# - Return     :
###
sub print_nntp_error ( $$ ) {
  my ($r, $err) = @_;
  $r->log->warn( "${Base} NNTP Error: $err" );
  &print_html_head( $r );
  &print_html_error( $r, "NNTP Error \@ $NewsUrl", $err );
  $r->print
    (
     "<div align=\"center\"><font color=\"red\">", 
     "[<a href=\"",  $r->subprocess_env('SCRIPT_URL'), "\">", &message('try_again'), "</a>]", 
     "</font></div>\n", 
    );
  &print_html_foot( $r );
  return;
} # end print_nntp_error();




# Utilities ---------------------------------------------------------


### Sub get_args() ###
# status = &get_args( request ):
# - Description: Fill in the global hash Args. The args are processed
#   in this order: Cookies, path_info, environment variables, GET then
#   POST args, each arg overriding previous one if already defined.
# - Arguments  : the Apache request
# - Return     : 1=ok, 0=failure
###
sub get_args ( $ ) {
  my $r = shift;

  # Empty Args...
  $Args = {};

  # Get cookies vals
  my %cookies    = CGI::Cookie->parse( $r->header_in('Cookie'));
  my $catchupval = $cookies{$Catchup_Cookie_Name}->value() if $cookies{$Catchup_Cookie_Name};
  $r->log->notice( "Got cookie $Catchup_Cookie_Name: $catchupval" ) if $DEBUG;
  # See action_catchup for settings of cookies
  if ( $catchupval =~ /^(Id)=(\d+),\s*(Date)=(\d+)$/ ) {
    $Args->{catchup_id}   = $2;
    $Args->{catchup_date} = $4;
  }

  # Parse path_info to get the action and such ...
  my $pi = $r->path_info();
  $pi =~ s/^\/*//;
  $Args->{action}      = undef;
  $Args->{action_args} = undef;
  if ( $pi ) {
    my ($action, @rest)  = split( '/', $pi );
    $Args->{action}      = lc( $action ) if $action;
    $Args->{action_args} = \@rest if ( $action && @rest );
  }

  # Get misc useful environment variables. TODO This really needs
  # improvements. If anybody have a good idea on how to do it, thanks!
  my $L         = $r->subprocess_env('LANG') || $r->subprocess_env('USR_LANG') || $USR_LANG;
  $L            = lc( $L );
  $USR_LANG     = $L if ( $LANGS_OK{$L} );
  $Args->{lang} = $USR_LANG;

  # Get args from POST or GET (?args=xxx)
  #$r->log->info( "Reading POST&GET content ..." ) if $DEBUG;
  my %A = ($r->args(), $r->content());
  map{ $Args->{lc($_)} = $A{$_} } keys %A;

  # that's all folks ...
  map{ $r->log->info( "Arg \'$_\': \"", $Args->{$_}, "\"" ) } keys %{$Args} if $DEBUG;
  return 1;

} # end get_args();



### Sub get_config() ###
# status = &get_config( request ):
# - Description:  Read the configuration instructions.
# - Arguments  : the Apache request
# - Return     : 1=ok, 0=failure
###
sub get_config ( $ ) {
  my $r = shift;

  $DEBUG = &is_true( $r->dir_config( 'NNTPGatewayDebug' ));

  # Server config
  $Base = $r->location();
  # I'm not really sure I should keep this protection ...
  if ( $REQUIRED_LOCATION_BASE_RE && $Base !~ /^$REQUIRED_LOCATION_BASE_RE/o ) {
    $r->log_error( "$PKG_NAME called from $Base but only permitted from /^$REQUIRED_LOCATION_BASE_RE/" );
    return 0;
  }

  $SERVER_NAME = $r->subprocess_env('HTTP_HOST') || $r->subprocess_env('SERVER_NAME') || $SERVER_NAME;
  if ( $SERVER_NAME =~ /^([^\.]+)\.(.*)/ ) {
    $COOKIE_DOMAIN = $DOMAIN_NAME = $2;
  } else {
    $DOMAIN_NAME ||= $SERVER_NAME;
    $COOKIE_DOMAIN = undef;
  }

  # Apache Config directive - PerlSetVar -
  $The_Newsgroup        = $r->dir_config( 'NNTPGatewayNewsGroup' );
  unless ( $The_Newsgroup ) {
    # NewsGroup is a required config parameter
    $r->log_error( "Configuration directive NNTPGatewayNewsGroup should be set in <Location $Base>!" );
    return 0;
  }
  $The_GroupDescription = $r->dir_config( 'NNTPGatewayGroupDescription' ) || '&nbsp;';
  $NNTP_Server          = $r->dir_config( 'NNTPGatewayNewsServer' ) || $DEFAULT_NEWS_SERVER;
  $NewsUrl              = "news://${NNTP_Server}/${The_Newsgroup}";
  $DEFAULT_ACTION_NAME  = $r->dir_config( 'NNTPGatewayDefaultAction' ) || $DEFAULT_ACTION_NAME;
  $Catchup_Cookie_Name  = 'NNTPGatewayCatchup.' . $The_Newsgroup;
  $Organization         = $r->dir_config( 'NNTPGatewayOrganization' ) || $Organization;
  $Title                = $r->dir_config( 'NNTPGatewayTitle' ) || "NNTPGateway: $NewsUrl";
  $StyleSheet           = $r->dir_config( 'NNTPGatewayStyleSheet' ) || undef;

  # Anonymous posts configuration
  $Anonymous_Post_Allowed = &is_true( $r->dir_config( 'NNTPGatewayAnonymousPostAllowed' )) || 0;
  if ( $Anonymous_Post_Allowed ) {
    # Get a list of anonymous posters names if any, 
    # AnonymousPosters mail1=Name 1, name2=Name 2,  ...
    my $anon_names = $r->dir_config( 'NNTPGatewayAnonymousPosters' );
    $r->log->info( "AnonymousPosters: $anon_names" ) if $DEBUG;
    foreach ( split( /,/, $anon_names )) {
      my ($m, $n) = split( /=/, $_ );
      $m = lc( $m );
      $Anonymous_Posters{$m} = $n unless exists $Anonymous_Posters{$m};
    }
  } else {

    # No anonymous posters
    %Anonymous_Posters = ();

  }

  # Get the list of all disabled actions
  %Disabled_Actions = ();
  my $disabled = lc( $r->dir_config( 'NNTPGatewayDisabledActions' ));
  if ( $disabled eq 'none' ) {
    $r->log->warn( "DisabledActions: none" );
  } elsif ( $disabled ) {
    $r->log->info( "DisabledActions: \"$disabled\"" ) if $DEBUG;
    my @disabled = split( /([\s,])/, $disabled );
    foreach ( @disabled ) {
      my $a = $_;
      $Disabled_Actions{$a} = 1 if $Actions_Map{$a};
    }
  } else {
    $r->log->notice( "DisabledActions: none" );
  }

  # NYI: Get directory where to find HTML::Template files. This
  # feature is not yet implemented but hope it will be soon...
  my $tmpldir = $r->dir_config( 'NNTPGatewayTemplatesDir' ) || $DEFAULT_TEMPLATES_DIR;
  # Append server root to it
  $tmpldir = $r->server_root_relative( $tmpldir ) unless File::Spec->file_name_is_absolute( $tmpldir );
  # Canonize dir name
  $Templates_Dir = File::Spec->canonpath( $tmpldir );
  unless ( -d $Templates_Dir ) {
    #$r->log_error( "Templates dir $Templates_Dir not found!" );
    #return 0;
  }
  #$r->log->info( "Using templates from dir $Templates_Dir ..." ) if $DEBUG;
  return 1;
} # end get_config();



### Sub check_user() ###
# status = &check_user( request ):
# - Description: Check username..., via ident 1st then w/ http loggin...
# This function need still a lot of work.
# - Arguments  : the Apache request
# - Return     : 1=ok, 0=failure
###
sub check_user ( $ ) {
  my $r = shift;

  # The_User is a global... 
  # 1/ Try to check username through indent
  #    (IdentityCheck) and then with Http authentication.
  $The_User = $r->get_remote_logname() || $r->connection->user() || undef;
  if ( $The_User &&
       &is_true( $r->dir_config( 'NNTPGatewayUsersNamesCaseInsensitive' ))) {
    $The_User = lc( $The_User );
  }
  # The following list should be configurable maybe ?
  $The_User = undef if 
    ( 
     $The_User eq '-'         || 
     $The_User eq 'unknown'   || 
     $The_User eq 'anonymous' || 
     $The_User eq 'guest'     || 
     $The_User eq 'admin'     || 
     $The_User eq 'root' 
    );

  # 2/ Check username validity, by checking if a local (Unix) account
  #    exists for the user. This check is mainly for posting actions,
  #    the access protection is not handled in this module.
  my $username = (getpwnam($The_User))[6];
  # No password entry for this user consider it as anonymous
  $The_User = undef if ( !$username && !&is_true( $r->dir_config( 'NNTPGatewayNonLocalPostOk' )));

  # 3/ Check if user allowed to use this service ... And build a choice of possible
  #    From addresses.
  if ( $Anonymous_Post_Allowed ) {
    
    # Populate from posters list with some anonymous one...
    %From_Posters = %Anonymous_Posters;
    # ... and with the real user name too.
    $From_Posters{$The_User} = $username if $The_User;
    # Here I should undef $r->connection->remote_logname() and
    # $r->connection->user() and associated values in subprocess_env,
    # so that they will definitively disappear from any log files, to
    # be fair. I should ... Should I really ?
    
  } elsif (( not $The_User ) && $Post_Actions_Map{$The_Action} ) {

    # The user had not been successfully identified, and the current
    # action is to post an article, but anonymous post is not enabled
    # ... so bad luck today.
    $r->log->warn( "${Base}: From ", 
                   $r->get_remote_host(), 
                   ", posting not allowed for unidentified users." );
    &print_html_head( $r );
    &print_html_error( $r, &message('no_anon' ), undef );
    &print_html_foot( $r );
    return 0;

  } else {

    # The user had been identified and seems (...) to be valid, as
    # we're not in anonymous posting mode this is the only one poster
    # allowed.
    $From_Posters{$The_User} = $username;
  }
  return 1;

} # end check_user();



### Sub message() ###
# string = &message( msgkey [, args] ):
# - Description:
# - Arguments  : message_map key, args
# - Return     : string
###
sub message ( $\@ ) {
  my $k = lc( shift );
  my @args = @_;
  return undef unless exists $Messages_Map{$k};
  my $fmt = $Messages_Map{$k}->{$USR_LANG};
  return sprintf( $fmt, @args );
} # end message();



### Sub is_true() ###
# bool = &is_true( string ):
# - Description: Check arg is true.
# - Arguments  : any arg
# - Return     : 1|0
###
sub is_true ( $ ) {
  my $v = lc( shift );
  return 
    $v == 1 || 
      $v eq 'on' || 
        $v eq 'y' || 
          $v eq 'yes' || 
            $v eq 't' || 
              $v eq 'true' || 
                $v eq 'ok';
} # end is_true();



### Sub is_false() ###
# bool = &is_false( string ):
# - Description: Check arg is false.
# - Arguments  : any arg
# - Return     : 1|0
###
sub is_false ( $ ) {
  my $v = lc( shift );
  return 
    $v == 0 || 
      $v eq 'off' || 
        $v eq 'n' || 
          $v eq 'no' || 
            $v eq 'not';
} # end is_false();



### Sub parse_from() ###
# ($email, $name) = &parse_from( from ):
# - Description: Parse the From header
# - Arguments  : From nntp article header
# - Return     : (email, name)
###
sub parse_from ( $ ) {
  my $from = shift;
  my $addr = (Mail::Address->parse($from))[0] || return ();
  return ($addr->address(), $addr->name());
} # end parse_from();


1; 

__END__



# Documentation ----------------------------------------------------------


=head1 NAME

B<Apache::NNTPGateway> - A NNTP interface (Usenet newsgroups) for
mod_perl enabled Apache web server.


=head1 SYNOPSIS

 You must be using mod_perl, see http://perl.apache.org/ for details.

 For  the  correct work   your  apache configuration  should  contain   apache
 directives look like these:

 In httpd.conf (or any other apache configuration file):

 <Location "/path/to/newsgroup">
    SetHandler		perl-script
    PerlHandler		Apache::NNTPGateway
    PerlSetVar		NNTPGatewayNewsGroup "newsgroup"
    PerlSetVar		NNTPGateway... (see L<CONFIGURATION> Directives)
 </Location>


=head1 DESCRIPTION

 This module implements a per group interface to NNTP (Usenet) News-Groups, it
 allow users to   list,    read, post, followup   ...  articles   in a   given
 newsgroup/newsserver  depending of configuration.  This  is not a replacement
 for a real powerful newsreader client but just pretend to be a simple, useful
 mapping of some news articles into a web space.

=head2 ACTIONS

 Here is the list of all actions that can be performed on the current newsgroup.


=over 4

=item list

  List articles,   all  articles from   the current newsgroup  or  only unread
  articles if the user/client already did a B<catchup>.

=item catchup

  Mark all current articles as read. This use a Cookie.

=item last

  Read the last article available from the newsserver.

=item read

  Read article by ID.

=item followup

  Post a followup to an article.

=item post

  Post an new article to the current newsgroup.

=back


=head1 CONFIGURATION 

  Except some very few  optional adjustments in  the module source itself all
  configuration is done with B<PerlSetVar> directives in Apache configurations
  files.

=head2 Directives

 All  following features of    this PerlHandler, will   be  set in the  apache
 configuration files. For this you can use PerlSetVar apache directive.

=over 4

=item NNTPGatewayNewsGroup 

 (string, B<mandatory>)

 The newsgroup used  for  the current NNTPGateway  location. Not  setting this
 will make NNTPGateway fail.

=item NNTPGatewayGroupDescription

 (string, I<optional>)

 Short description (1 or 2 lines) of what this newsgroup is for/contain.

=item NNTPGatewayStop 

 (boolean, I<optional>)

 Tell to completely disable NNTPGateway, useful for temporary maintenance.

=item NNTPGatewayDefaultAction

 (ACTION name, I<optional>) Default value: B<last>

 Default action used when nothing specified. (see L<ACTIONS>).

=item NNTPGatewayNewsServer

 (string, I<optional>)

  When using correctly  configured perl modules B<Net::Domain>, B<Net::Config>
  on  a correctly  configured  system this should   not be changed, in  theory
  NNTPGateway could   be able to  handle  multiples  news server   but this is
  greatly nor  recommended (see L<BUGS>) unless  you really  know what you are
  doing.

=item NNTPGatewayOrganization

  (string, B<recommended>) Default value: B<The Disorganized Corp>

  Set the Organization header when posting articles.

=item NNTPGatewayTitle

  (string, I<optional>)

  Title displayed in NNTPGateway pages.

=item NNTPGatewayStyleSheet

  (string, I<optional>)

  Set the style sheet used  in NNTPGateway pages,  or none. There are some few
  classes in the  generated HTML, check  the source to use  them in your style
  sheet.

=item NNTPGatewayAnonymousPostAllowed

  (boolean, I<optional>) Default value: B<off>

  Allow anonymous posting in the current group.

=item NNTPGatewayAnonymousPosters

  (list, I<optional>) Default value: B<anonymous=Anonymous>

  A list of pair email=Name that could be used for anonymous
  posts. I'm B<Absolutely> not responsible for any abuse of this
  feature, this is up to the webmaster to control it's usage.

  Ex:
  C<PerlSetVar NNTPGatewayAnonymousPosters "anon=The Unknown Soldier,president=The Big Boss"> 

=item NNTPGatewayNonLocalPostOk

  (boolean, I<optional>) Default value: B<off>

  Allow user who do not have local (to the same web server machine -
  checked with getpwnam) login account to post articles, in B<non>
  anonymous post mode the users should have been identified themselves
  anyway (with identd or server auth).

=item NNTPGatewayUsersNamesCaseInsensitive

  (boolean, I<optional>) Default value: B<off>

  Check users names in a case insensitive manner.

=item NNTPGatewayDisabledActions

  (ACTIONS list, I<optional>) Default value: B<none> 

  List of L<ACTIONS> that are B<not> allowed to be performed by users for
  the current config. (see L<ACTIONS>).

=item NNTPGatewayTemplatesDir

  (string, L<optional>) Default value: B<lib/templates/NNTPGateway/>

  ServerRoot relative Directory where to find HTML templates files (not yet Implemented). 

=item NNTPGatewayDebug 

  (boolean, I<optional>) Default value: B<off>

  Set this to debug NNTPGateway. 

=back


=head1 SECURITY

  If   you  B<allow>  Anonymous posting  absolutely   no  security  checks are
  performed unless you protect access to the  Location this handler is located
  on, but that is not the job of this module.

  If  you B<deny>  Anonymous posting, the   handler will check B<remote_ident>
  (via Identd) or B<remote_user> and will check  if they are valid username by
  checking C<getpwnam()> (a list   of some generic  usernames such   as: root,
  anonymous  ...  are not   considered  as valid  too, even  if  they are), if
  directive B<NNTPGatewayNonLocalPostOk>  had not  been  set, if they are  not
  they are rejected, if they  are they could post and  the From header will be
  set to that username.  That is the only security  check the handler will do,
  it is up to other apaches modules to correctly protect  the Location and set
  valid usernames (enable identd or loggin via AuthNIS or anything else).

  Furthermore the webmaster could   disable the use   of some actions such  as
  post, followup ...


=head1 BUGS

 The connection to the nntp server is handled in a global variable so that the
 connection is common to all requests in the current apache child process. Due
 to that,  when the module is  used with 2  differents configs (in 2 <Location
 xxx>) setting  2 differents newsservers  and that 2 requests  are made in the
 same child with these 2 configs (or more) ... the second request could re-use
 a NNTP connection (open during the 1st request)  already open to the B<first>
 server. I do not  want to make the nntp  object a local variable, because the
 connection is a long process ... But anyway, I have some  few ideas of how to
 solve the  problem, but as  I am lazy and  my configuration do not  have this
 problem I am waiting for pressure from eventual module users ...;-)


=head1 Changes

=over 4

=item v0.9

 * Article id or subject added to title in read.
 * More CSS classes everywhere... read the sources.
 * use Apache::Log qw(); to access to log functions.
 * Makefile.PL improved to really check used modules versions.
 * Call  Net::Cmd functions in a  clean manner to make perl  5.6 happy (end of
   that Bareword "CMD_ERROR" install bug).

=item v0.8

 * Cookie domain better handled for catchup.
 * NNTPGatewayNewsGroupTest   removed.  Set  up    a  new  Location  and   set
   NNTPGatewayNewsGroup to  the test group and  NNTPGatewayDebug on to achieve
   the same functionality.
 * Some       more       directives   to       control        users   checking
   (NNTPGatewayUsersNamesCaseInsensitive, NNTPGatewayNonLocalPostOk).
 * Some handling of Cache-Control.
 * Made this module ready for my first CPAN contribution ;-)
 ** Cleaning source code.
 ** Cleaning Documentation.
 ** CPAN  Enabled distrib (Makefile.PL,   .tar.gz dist,  README file, CPAN  ID
    ...).

=item v0.7

 * The configuration directive B<NNTPGatewayCatchupCookieName> do not exists anymore.
 * Disconnections to news server start to be better handled.

=item v0.6

 First public release

=back


=head1 TODO

=over 4

=item *

 Safe sharing of the NNTP global.

=item *

 Keeping into account the If-Modified-Since, Last-Modified and so on ... stuff.

=item *

 Using an HTML Template system (maybe HTML::Template) instead of hard coded html.

=item *

 Improving the LANG selection stuff (maybe adding a new configuration directive?)

=item *

 Improving the C<check_user()> stuff for more security.

=item *

 Integrating Jie Gao threaded view of articles list.

=item *

 more stuff ...

=back


=head1 THANKS

 Thanks a lot to these people for they help:

=over 4

=item * Jie Gao <J.Gao@isu.usyd.edu.au>
 For his help to build a clean installation of the module.

=back


=head1 SEE ALSO

 perl(1), mod_perl(3), Apache(3), Net::NNTP(3), Net::Domain(3),
 Net::Config(3), rfc9771, getpwnam(3)


=head1 COPYRIGHT

 The application and accompanying modules are Copyright  CENA Toulouse.  It is
 free software and can be used, copied and  redistributed at the same terms as
 perl itself.


=head1 AUTHOR

 heddy Boubaker <boubaker@cpan.org>

 Home page:
 http://www.tls.cena.fr/~boubaker/WWW/Apache-NNTPGateway.shtml

=cut

### NNTPGateway.pm ends here  ----------------------------------------------
