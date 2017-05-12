package AxKit::App::TABOO;

our $VERSION = '0.52';

use 5.7.3;
use strict;
use warnings;

use Session;
use Apache;
use Apache::Cookie;
use Apache::Request;
use AxKit;

sub session_config {
  my $r = shift;
  my $prefix = $r->dir_config( 'TABOOPrefix') || 'TABOO';
  my %session_config = (
			Store     => $r->dir_config( $prefix . 'DataStore' ) || 'DB_File',
			Lock      => $r->dir_config( $prefix . 'Lock' ) || 'Null',
			Generate  => $r->dir_config( $prefix . 'Generate' ) || 'MD5',
			Serialize => $r->dir_config( $prefix . 'Serialize' ) || 'Storable'
		       );
   
  # When using Postgres, a different default is needed.  
  if ($session_config{'Store'} eq 'Postgres') {
    $session_config{'Commit'} = 1;
    $session_config{'Serialize'} = $r->dir_config( $prefix . 'Serialize' ) || 'Base64'
  }

  
  # Load session-type specific parameters, comma-separated, name => value pairs
  foreach my $arg ( split( /\s*,\s*/, $r->dir_config($prefix . 'Args'))) {
    my ($key, $value) = split( /\s*=>\s*/, $arg );
    $session_config{$key} = $value;
  }

  return %session_config;
}

sub session {
  my $r = shift;
  my $req = Apache::Request->instance($r);
  my $vid = $req->param('VID');
  unless ($vid) { # Then look in the cookie
    my $cookies = Apache::Cookie->fetch;
    my $tmp = $cookies->{'VID'};
    return undef unless defined($tmp);
    $vid = $tmp->value;
    return undef unless ($vid); # No session key
  }
  AxKit::Debug(9, "User's visitor ID: $vid");
  return new Session $vid, session_config($r);
}
    

sub authlevel {
  my $session = shift;
  if (defined($session)) {
    return $session->get('authlevel');
  } else {
    return 0;
  }
}

sub loggedin {
  my $session = shift;
  if (defined($session)) {
    return $session->get('loggedin');
  } else {
    return 'guest';
  }
}

1;
__END__


=head1 NAME

AxKit::App::TABOO - Object Oriented Publishing Framework for AxKit

=head1 INTRODUCTION

AxKit::App::TABOO is a object oriented approach to creating a
publishing system on the top of AxKit, the XML Application Server. 
The two O's thus stands for Object Oriented, AB for AxKit-Based. 
I don't know what the T stands for yet, suggestions are welcome! 

This file holds only a few session and authentication functions, that
I didn't quite knew where to put. This may change.


=head1 DESIGN PHILOSOPHY

There are three main ideas that forms the basis for TABOO:

=over

=item 1. The data should be abstracted to objects so that the AxKit
things never have to deal with where and how the data are stored. 

=item 2. URIs should be sensible and human-readable, reflect what kind
of content you will see, and easy to maintain and independent of
underlying server code.

=item 3. Use providers for all the real content that's served to the
user. I like the abstraction Providers give for URIs, and so is an
excellent vehicle to achieve the above goal. Also, they provide the
cleanest separation of markup from code. 

=back

To detail this: I noticed while looking at other people's code, that
though it was a lot of interesting code, it would be rather hard to
integrate all the interesting parts into a coherent whole. That's why
I made the fundamental design choice with TABOO that all data
is to be abstracted to objects. Furthermore, everybody has their own
way of storing data, and scattered files or different databases didn't
seem right to me.

With TABOO, everything that interacts with AxKit just interacts with
the Data objects. That means, if you don't want to store things in the
PostgreSQL database my Data objects use, you could always subclass it,
rewrite the classes or whatever. You would mostly just have to rewrite
the load method. It is also the Data object's job to create XML of its
own data, save itself, etc.

The intention is to write Data objects for every kind of thing you
might want to do. From the start, there will be Slashdot-type stories
of varying length, with comments. These are ever-changing in the sense
that people can come in an add comments at any time. 

It is the intention, however, that TABOO should be a framework where
one can add many very different things. 

TABOO makes extensive use of Providers. That is mostly because I like
the abstraction and direct control of URIs that Providers provide. It
makes it easy to create a framework where URIs are sensible and should
be easy to maintain for foreseeable future. Also, there is no markup
in the code, that's also rather important to make it maintainable. 

=head1 DESCRIPTION

This is what TABOO contains at this point.:

The base data object, L<AxKit::App::TABOO::Data> and a wealth of
subclasses of it, some of which is again subclassed. There are too
many to list.  They provide an abstraction layer that can manage the
data for each of the types. They can load data from a data storage,
currently a PostgreSQL data base, and they can write their data as
XML, and write it back to the database. There are also Plural
subclasses, built on the L<AxKit::App::TABOO::Data::Plurals> base
class. These classes makes it easier to work on more than one of the
above objects at a time, something that's often necessary. It also
provides some containment of complexity, taking worries off of your
head!

Then, there are three working AxKit Providers:
L<AxKit::App::TABOO::Provider::News>,
L<AxKit::App::TABOO::Provider::NewsList> and
L<AxKit::App::TABOO::Provider::Classification>, that makes use of the
above subclasses, especially Story and Comment in the first case, the
Stories in the second and a combination of those, Categories and
Articles in the last. The first provider creates a page containing an
editor-reviewed story and user-submitted comments. The second makes
lists of stories. The third creates lists of content based on
categories. By simply manipulating the URI in easy-to-understand ways,
you can load just the story, view the comments, separately, in a list
or as a thread, or get simple lists or good overviews of stories, or
lists of articles and stories in a category.

Currently, it supplies six Taglibs,
L<User|AxKit::App::TABOO::XSP::User>,
L<Story|AxKit::App::TABOO::XSP::Story>,
L<Comment|AxKit::App::TABOO::XSP::Comment>,
L<Comment|AxKit::App::TABOO::XSP::Articles>,
L<Category|AxKit::App::TABOO::XSP::Category> and
L<Category|AxKit::App::TABOO::XSP::Language>. These taglibs provide
several tags that you may use interface with the Data objects.

There is quite a lot of XSP and XSLT now that allows you to enter and edit
stories and TABOO is nearly useable as a news-site management framework.

Furthermore, there is also some user-management code, including
authentication and authorization, to allow adding new users and
editing the information of existing users. Important in this respect
are L<AxKit::App::TABOO::Handler::Login> and
L<AxKit::App::TABOO::AddXSLParams::Session> and handle the
authentication and add session information to XSLT.

It allows attaching comments to the news stories and any comment can
simply get a C</respond> appended on its URI to allow for entering a
response to it, and this is also easily done through links. It needs a
bit more polish, though.

It uses TinyMCE L<http://tinymce.moxiecode.com/> to allow WYSIWYG
entered text in textfields.

It also has some code for i18n, consisting of stylesheets that can
take all strings of text from a separate XML file and insert them in
the final product. This makes it easy to provide many translations
with TABOO, allthough a real multilingual site is not yet supported.

Pionered in 0.2 is the first code to manage more static articles,
typically background articles with rich metadata. Content can be
displayed, and that's pretty robust. Entering articles also works, but
they cannot be edited yet.

=head1 REVERSE PROXY

It is generally a very good idea to use a reverse proxy in front of a
heavyish mod_perl application, and there are a few hard-coded things
in TABOO that makes it pretty hard to run without it. It is therefore
strongly recommended that you do that.


=head1 CONFIGURATION EXAMPLE

The following is most of the author's AxKit configuration, and should
be sufficient to get the code that is currently in TABOO going. It is
admittedly a bit messy and could use some reworking. Apart from
installing TABOO, you would also need to copy the stuff in C<htdocs/>
directory in the distribution to C</var/www> or some other
DocumentRoot (and adjust the below accordingly). You will also be
expected to modify the things that are in the C<site/> directory of
the document root. The things in there are specifically examples, and
needs modifying on a per-site basis. 

You may also want to get some of the data in the C<sql/> directory
into a database, which can be identified by the C<DBI_DSN> environment
variable (see below). Furthermore, TABOO now allows you to set a
separate username and password on a databse, and use different
databases for different virtual hosts. A combination of C<DBI_DSN>,
C<PGUSER> and C<PGPASSWORD> environment variables will achieve this.

  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # The below directives are common for all virtual hosts, if you run such

  # This stuff is needed for rewriting URIs.

  RewriteEngine on

  RewriteRule ^/user/([^/]+)$ /user/submit/user.xsp?username=$1

  RewriteRule ^/user/submit/$ /user/submit/user.xsp
  RewriteRule ^/user/submit/new$ /user/submit/new.xsp

  RewriteRule ^/news/([^/]+)/([^/]+)/comment(/?.*)/respond$ /news/comment.xsp?sectionid=$1&storyname=$2&parentcpath=$3
  RewriteRule ^/news/([^/]+)/([^/]+)/edit$ /news/submit.xsp?sectionid=$1&storyname=$2&edit=true

  RewriteRule ^/articles/([^/]+)/([^/]+)$ /articles/provider.xsp?primcat=$1&filename=$2

  RewriteRule ^/$ /index.xsp

  # Set to whereever you unpacked TinyMCE
  Alias /jscripts/tiny_mce/ /usr/share/tinymce/www/


  # This may be needed on some setups
  DirectoryIndex index.xsp index.xml


  # Some stuff should not be seen by AxKit.
  <Location ~ "/css/|favicon.ico">
    SetHandler default-handler
  </Location>


  # Here starts the the main AxKit-specific things
  PerlModule AxKit
  SetHandler AxKit

  AxHandleDirs On

  # Language modules to make XSP and XSLTransformations work
  AxAddStyleMap application/x-xsp Apache::AxKit::Language::XSP
  AxAddStyleMap text/xsl Apache::AxKit::Language::LibXSLT

  AxAddPlugin Apache::AxKit::Plugin::Passthru

  AxAddPlugin Apache::AxKit::Plugin::AddXSLParams::Request
  PerlSetVar AxAddXSLParamGroups "Request-Common HTTPHeaders"

  # If you want a different language than English, you need to
  # translate i18n.en.xml and replace nb with your language
  # code. These two directives are optional, you don't need any if you
  # want English.
  AxAddPlugin Apache::AxKit::Plugin::Param::Expr
  PerlAddVar AxParamExpr neg.lang '"nb"'

  AxAddPlugin AxKit::App::TABOO::AddXSLParams::Session


  # TABOO XSPs
  AxAddXSPTaglib AxKit::App::TABOO::XSP::User
  AxAddXSPTaglib AxKit::App::TABOO::XSP::Story
  AxAddXSPTaglib AxKit::App::TABOO::XSP::Category
  AxAddXSPTaglib AxKit::App::TABOO::XSP::Comment
  AxAddXSPTaglib AxKit::App::TABOO::XSP::Article
  AxAddXSPTaglib AxKit::App::TABOO::XSP::Language




  # Other XSPs

  AxAddXSPTaglib AxKit::XSP::QueryParam
  AxAddXSPTaglib AxKit::XSP::Sendmail

  PerlAddVar AxParamExpr cats.prefix '"/cats/"'

  PerlModule AxKit::App::TABOO::Handler::Login
  <Location /login>
     SetHandler perl-script
     PerlHandler AxKit::App::TABOO::Handler::Login
     PerlSendHeader On
  </Location>


  <Location /cats/>
  	PerlHandler AxKit
        AxContentProvider AxKit::App::TABOO::Provider::Classification
  </Location>


  # Providers for News, depending somewhat on the paths.

  <LocationMatch ^/news/[^(respond$)]*>
  	PerlHandler AxKit
        AxContentProvider AxKit::App::TABOO::Provider::NewsList
    	PerlSetVar TABOOListDefaultRecords 20
    	PerlSetVar TABOOListMaxRecords 200
  </LocationMatch>


  <Location /news/submit>
        PerlHandler AxKit
        AxContentProvider Apache::AxKit::Provider::File
  </Location>


  <LocationMatch ^/news/(.+)/(.+)/($|comment)>
        PerlHandler AxKit
        AxContentProvider AxKit::App::TABOO::Provider::News
  </LocationMatch>


  <LocationMatch ^/news/.+/(respond|edit)$>
   	PerlHandler AxKit
  	AxContentProvider Apache::AxKit::Provider::File
  </LocationMatch>


  # ////////////////////////////////


  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # These are things that may be sensible to use during development

  AxNoCache On
  # This parameter can be useful if you suspect you're getting cached 
  # copies, but it can only be set in the main Apache config.
  #MaxRequestsPerChild 1

  AxDebugLevel 10
  AxDebugTidy On
  AxTraceIntermediate /tmp/intermediate

  # ////////////////////////////////



  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # This section contains stuff that needs to be configured on a virtual host 
  # basis. It may be an idea to place in it's own file.

  # Database connection parameters
  PerlSetEnv DBI_DSN dbi:Pg:dbname=taboodemo
  PerlSetEnv PGUSER taboodemo
  PerlSetEnv PGPASSWORD hk987JKBgui

  # Set this if you want to use Akismet: http://akismet.com/
  PerlSetVar TABOOAkismetKey fooobaaaa


  # Aliases, rather than files have a full filesystem path. 
  # That's rather evil...
  Alias /news/submit /var/www/news/submit.xsp 
  Alias /categories/submit /var/www/categories/submit.xsp 

  Alias /articles/submit /var/www/articles/submit.xsp 
  Alias /articles/edit /var/www/articles/edit.xsp 


  # Authentication and authorization stuff

  PerlSetVar TABOODataStore DB_File
  PerlSetVar TABOOArgs      "FileName => /tmp/taboodemo-session"

  # /////////////////////////////


This should get you the authentication and authorization code you
need, set up XSP and the taglibs you need. Note that the order of the
Locations matter. The second of them is rather hackish, it doesn't
feel good, but it was the way I it working...



=head1 TODO

Because this is a POD, I'm stopping with my lofty visions here
(there's more of that in the README). This is a beta of TABOO,
and it seems to do what it is intended to, namely be a site where
multiple users can post news stories, and comment them. That's
something that has been done before, of course, but not within the
design goals stated above.

The Article code needs work still, manipulate articles better, but I
have actually put what I have in production, and it works!

Also, I need some kind of gallery code soonish.

Finally note that things that are there are B<not stable>! Names may
change, parameters may be different, and I may decide to do things
differently, depending on how this projects evolves, what new things I
learn (this is very much a learning process for me), and what kind of
feedback hackers provide.

TABOO also has had some code for a webshop, but since it has fallen
behind the rest of the development, it has been removed from the
distribution as of 0.08_1. It is however trivial to merge back in, and
some of the code is quite OK, and not very hard to update to follow
the rest of framework. TABOO will make a great webshop platform...!


=head1 SUPPORT

There is now a taboo-dev mailing list that can be subscribed to at
http://lists.kjernsmo.net/mailman/listinfo/taboo-dev

=head1 BUGS

There are surely some... Please report any you find through CPAN RT:
http://rt.cpan.org/NoAuth/Bugs.html?Dist=AxKit-App-TABOO .

=head1 SUBVERSION REPOSITORY

TABOO is currently maintained in a Subversion repository. The trunk
can be checked out anonymously using e.g.:

  svn checkout http://svn.kjernsmo.net/TABOO/trunk TABOO  

It is also available using svn+ssh for committers.


=head1 AUTHOR

Kjetil Kjernsmo, E<lt>kjetilk@cpan.orgE<gt>

=head1 SEE ALSO

L<AxKit>, L<AxKit::App::TABOO::Data>, L<AxKit::App::TABOO::Provider::News>.

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2003-2007 Kjetil Kjernsmo. This program is free
software; you can redistribute it and/or modify it under the same
terms as Perl itself.


=cut
