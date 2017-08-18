package Catalyst::Helper::View::SemanticUI;

our $VERSION = '0.0001';
$VERSION = eval $VERSION;

use strict;
use warnings;
use File::Spec;
use Path::Class qw/dir file/;
use File::ShareDir qw/dist_dir/;

sub get_sharedir_file {
    my ($self, @filename) = @_;
    my $dist_dir;
    if (exists $ENV{CATALYST_DEVEL_SHAREDIR}) {
        $dist_dir = $ENV{CATALYST_DEVEL_SHAREDIR};
    }
    elsif (-d "inc/.author" && -f "lib/Catalyst/Helper/View/SemanticUI.pm"
            ) { # Can't use sharedir if we're in a checkout
                # this feels horrible, better ideas?
        $dist_dir = 'share';
    }
    else {
        $dist_dir = dist_dir('Catalyst-Helper-View-SemanticUI');
    }
    my $file = file( $dist_dir, @filename);
    Carp::confess("Cannot find $file") unless -r $file;
    my $contents = $file->slurp(iomode =>  "<:raw");
    return $contents;
}

sub mk_compclass {
    my ( $self, $helper, @args ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
    $self->mk_templates( $helper, @args );
    $helper->{root} = dir( $helper->{base}, 'root' );
    $helper->mk_dir( $helper->{root} );
    $helper->{static} = dir( $helper->{root}, 'static' );
    $helper->mk_dir( $helper->{static} );
    $helper->{images} = dir( $helper->{static}, 'images' );
    $helper->mk_dir( $helper->{images} );
    $self->_mk_images($helper);
}

sub mk_templates {
    my ( $self, $helper ) = @_;
    my $base = $helper->{base},;
    my $ldir = File::Spec->catfile( $base, 'root', 'lib' );
    my $sdir = File::Spec->catfile( $base, 'root', 'src' );
    my $jsdir = File::Spec->catfile( $base, 'root', 'static', 'js' );
    my $cssdir = File::Spec->catfile( $base, 'root', 'static', 'css' );

    $helper->mk_dir($ldir);
    $helper->mk_dir($sdir);
    $helper->mk_dir($jsdir);
    $helper->mk_dir($cssdir);

    my $dir = File::Spec->catfile( $ldir, 'config' );
    $helper->mk_dir($dir);

    foreach my $file (qw( main url )) {
        $helper->render_file( "config_$file",
            File::Spec->catfile( $dir, $file ) );
    }

    $dir = File::Spec->catfile( $ldir, 'site' );
    $helper->mk_dir($dir);

    foreach my $file (qw( wrapper layout html header footer )) {
        $helper->render_file( "site_$file",
            File::Spec->catfile( $dir, $file ) );
    }

    foreach my $file (qw( welcome.tt2 message.tt2 error.tt2 ttsite.css signin.tt2 )) {
        $helper->render_file( $file, File::Spec->catfile( $sdir, $file ) );
    }
    
    my $jsMinifier = 0;
    eval {
    	$SIG{__DIE__} = 'IGNORE';
    	if(require 'JavaScript::Minifier::XS') {
    	    $jsMinifier = 1;
    	}
    	elsif(require 'JavaScript::Minifier') {
    	    $jsMinifier = 2;
    	}

    };
    
    foreach my $file (qw( respondjs.min.js )) {
    	my $jsfile = File::Spec->catfile( $jsdir, $file );
        $helper->render_file( $file, $jsfile );
        
        if(substr($jsfile, -3) eq '.js' && substr($jsfile, -7) ne '.min.js') {
            my $minJSFile = substr($jsfile, 0, -3) . '.min.js';

            if($jsMinifier) {
                my $minJSRef  = file($minJSFile);
                my $jsfileRef = file($jsfile);
                my $MINIFIEDJS = $minJSRef->open('w');
                my $contents = $jsfileRef->slurp(iomode =>  "<:raw");

                if($jsMinifier == 1) {
                    print $MINIFIEDJS JavaScript::Minifier::XS::minify($contents);
                }
        
                elsif($jsMinifier == 2) {
                    JavaScript::Minifier::minify(
                        input=>$contents,
                        output=>$MINIFIEDJS,
                        stripDebug=>1,
                    );
                }
                $MINIFIEDJS->close;
            }
            else {
                unlink($minJSFile);
                symlink($jsfile, $minJSFile);
            }
            
            my $gzipJSFile = $jsfile . '.gz';
            system("gzip -9c $minJSFile > $gzipJSFile");
        }
    }
    
    foreach my $file (qw( )) {
        $helper->render_file( $file, File::Spec->catfile( $cssdir, $file ) );
    }
}

sub _mk_images {
    my $self   = shift;
    my $helper = shift;
    my $images = $helper->{images};
    my @images =
      qw/catalyst_logo/;
    for my $name (@images) {
        my $image = $self->get_sharedir_file("root", "static", "images", "$name.png.bin");
	rename file( $images, "$name.png" ), file( $images, "$name.png" ).'.orig';
        $helper->mk_file( file( $images, "$name.png" ), $image );
    }
}


=head1 NAME

Catalyst::Helper::View::SemanticUI - Helper for Semantic UI and TT view which builds a skeleton web site

=head1 SYNOPSIS

# use the helper to create the view module and templates

    $ script/myapp_create.pl view HTML SemanticUI

# add something like the following actions to your main application module

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'message.tt2';
        $c->stash->{message}  ||= $c->req->param('message') || 'No message';
    }

    sub index : Path : Args(0) {
        my ( $self, $c ) = @_;
        $c->stash->{template} = 'welcome.tt2';
    }

    sub end : Private { # Or use Catalyst::Action::RenderView
        my ( $self, $c ) = @_;
        $c->forward( $c->view('HTML') );
    }

=head1 DESCRIPTION

This helper module creates a TT View module.  It goes further than
Catalyst::Helper::View::TT in that it additionally creates a simple
set of templates to get you started with your web site presentation
using Semantic UI from a CDN (Content Delivery Network).

It creates the templates in F<root/> directory underneath your
main project directory.  In here two further subdirectories are
created: F<root/src> which contains the main page templates, and F<root/lib>
containing a library of other template components (header, footer,
etc.) that the page templates use.

The view module that the helper creates is automatically configured
to locate these templates.

It sets character encoding to utf-8 and it delivers HTML5 pages.

=head2 Default Rendering

To render a template the following process is applied:

The configuration template F<root/lib/config/main> is rendered. This is
controlled by the C<PRE_PROCESS> configuration variable set in the controller
generated by Catalyst::Helper::View::SemanticUI. Additionally, templates referenced by
the C<PROCESS> directive will then be rendered.

Next, the template defined by the C<WRAPPER> config variable is called. The default
wrapper template is located in F<root/lib/site/wrapper>. The wrapper template
passes files with C<.css/.js/.txt> extensions through as text OR processes
the templates defined after the C<WRAPPER> directive: C<site/html> and C<site/layout>.

Based on the default value of the C<WRAPPER> directive in F<root/lib/site/wrapper>,
the following templates are processed in order:

=over 4

=item * F<root/src/your_template.tt2>

=item * F<root/lib/site/footer>

=item * F<root/lib/site/header>

=item * F<root/lib/site/sidemenu>

=item * F<root/lib/site/layout>

=item * F<root/lib/site/html>

=back

Finally, the rendered content is returned to the bowser.

=head1 METHODS

=head2 mk_compclass

Generates the component class.

=head2 mk_templates

Generates the templates.

=cut

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View::TT>, L<Catalyst::Helper>,
L<Catalyst::Helper::View::TT>
L<SemanticUI|https://semantic-ui.com/> 

=head1 AUTHORS

Ferruccio Zamuner <nonsolosoft@diff.org>

Following have contributed to Catalyst::Helper::View::Bootstrap:

Juan Paredes
Colin Keith <colinmkeith@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    INCLUDE_PATH => [
        [% app %]->path_to( 'root', 'src' ),
        [% app %]->path_to( 'root', 'lib' )
    ],
    PRE_PROCESS  => 'config/main',
    WRAPPER      => 'site/wrapper',
    ERROR        => 'error.tt2',
    TIMER        => 0,
    ENCODING     => 'utf8',
    render_die   => 1,
});

=head1 NAME

[% class %] - Catalyst TT SemanticUI View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__config_main__
[% USE Date;
   year = Date.format(Date.now, '%Y');
-%]
[%~ TAGS star -%]
[%~ # config/main
   #
   # This is the main configuration template which is processed before
   # any other page, by virtue of it being defined as a PRE_PROCESS
   # template.  This is the place to define any extra template variables,
   # macros, load plugins, and perform any other template setup.

   IF Catalyst.debug;
     # define a debug() macro directed to Catalyst's log
     MACRO debug(message) CALL Catalyst.log.debug(message);
   END;

   # define a data structure to hold sitewide data
   site = {
     title     => 'Catalyst::View::SemanticUI Example Page',
     copyright => '[* year *] Your Name Here',
   };

   # load up any other configuration items
   PROCESS config/url;

   # set defaults for variables, etc.
   DEFAULT
     message = 'There is no message';

-%]
__config_url__
[%~ TAGS star -%]
[%~ base = Catalyst.req.base;

   site.url = {
     base    = base
     home    = "${base}welcome"
     message = "${base}message"
   }
-%]
__site_wrapper__
[%~ TAGS star -%]
[%~ IF template.name.match('\.(css|js|txt|pdf|doc|docx)');
     debug("Passing page through as text: $template.name");
     content;
   ELSE;
     debug("Applying HTML page layout wrappers to $template.name\n");
     content WRAPPER site/html + site/layout;
   END;
-%]
__site_html__
[%~ TAGS star ~%]
<!DOCTYPE HTML>
<html>
 <head>
  <meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>[% template.title or site.title %]</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

[% IF Catalyst.debug; %]
  <!-- Latest compiled and mininied JavaScript -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.2.13/semantic.css">
[% ELSE; %]
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.2.13/semantic.min.css">
[% END; %]

  <style type="text/css">
    [% PROCESS ttsite.css %]
    body {
    padding-top: 0
    }
    .ui.top.attached.menu {
       margin-bottom: 1em;
    }
[% semanticui.page_css %]
  </style>
 </head>
 <body>
[% content %]

[% IF Catalyst.debug; %]
<script
  src="https://code.jquery.com/jquery-3.1.1.min.js"
  integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8="
  crossorigin="anonymous"></script>

  <script src="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.2.13/semantic.js" crossorigin="anonymous"></script>
[% ELSE %]
<script
  src="https://code.jquery.com/jquery-3.1.1.min.js"
  integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8="
  crossorigin="anonymous"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.2.13/semantic.min.js" crossorigin="anonymous"></script>
[% END %]

<script>
[% semanticui.page_js %]
</script>
 </body>
</html>
__site_layout__
[% TAGS star -%]
[%- UNLESS page.noheader %][% PROCESS site/header %][% END -%]

[% content %]

[%- UNLESS page.nofooter %][% PROCESS site/footer %][% END -%]
__site_header__
[%~ TAGS star -%]
<!-- BEGIN site/header -->
<div class="ui large inverted top attached menu" role="navigation">
  <div class="header item active">
    <a class="header-brand" href="#">[% template.title or site.title %]</a>
  </div>
  <div class="right menu">
    <div class="item">
      <a class="ui button">Log in</a>
    </div>
    <div class="item">
      <a class="ui primary button">Sign Up</a>
    </div>
  </div><!--/.right menu -->
</div><!--/. ui menu -->
<!-- END site/header -->
__site_footer__
[%~ TAGS star -%]
<!-- BEGIN site/footer -->
 <footer class="ui inverted menu" role natigation>
    <div class="item" id="copyright">
      &copy; <a href="#">[% site.copyright %]</a>
    </div>
    <div class="item" id="contact">
      You can write to <a href="mailto:nonsolosoft@diff.org">Catalyst::Helper::View::SemanticUI's author</a> if you have any question about it.
    </div>
 </footer>
<!-- END site/footer -->
__welcome.tt2__
[%~ TAGS star -%]
[% META title = 'Catalyst/SemanticUI TT View' -%]
[%- semanticui.page_css = BLOCK %]
i.icon {
-webkit-transition: width 2s, height 2s, background-color 2s, -webkit-transform 2s;
transition: width 2s, height 2s, background-color 2s, transform 1s, font-size 1s;
}

i.icon:hover {
    -webkit-transform: rotate(359deg);
    transform: rotate(359deg);
    color: blue;
    font-size: 150%;
}

i.icon.rocket:hover {
    -webkit-transform: rotate(-50deg);
    transform: rotate(-30deg);
    color: red;
}
[% END -%]

<div class="ui container grid">
<div class="row">
    <div class="column sixteen wide">
      <h1 class="ui header">Welcome to Catalyst world!
      <div class="sub header">Catalyst makes it easier to build better Web apps more quickly and with less code</div></h1>
    </div>
    <div class="column sixteen wide">
      <div class="ui message">
	<img class="ui small right floated image" src="/static/images/catalyst_logo.png" alt="Catalyst Logo">
	<p>Yay!  You're looking at a page generated by the Catalyst::View::TT 
	  plugin module and <a href="http://semantic-ui.com/">Semantic UI</a> using a simple Helper to produce the schema that you can look in root/lib/site and root/src/welcome.tt2.<br>
	  You can use the power of <a href="http://www.template-toolkit.org/">Template Toolkit 2</a> and the look and features of Semantic UI CSS framework.</p>
	
	<p>This is a template for a simple marketing or informational website. It includes a large callout called a jumbotron and three supporting pieces of content. Use it as a starting point to create something more unique.</p>
	<p><a href="http://www.catalystframework.org/" class="ui blue button" role="button">Learn more &raquo;</a></p>
	
      </div>
    </div>
  </div>
</div>[%# ui grid container (from lib/site/layout) %]

<div class="ui container stackable grid">
  <div class="row">
    <div class="ui five top attached steps">
      <div class="step">
	<i class="users icon"></i>
	<div class="content">
	  <div class="title">Wonderful community</div>
	  <div class="description">IRC Chat, mailing list and you can learn</div>
	</div>
      </div>
      <div class="step">
	<i class="cubes icon"></i>
	<div class="content">
	  <div class="title">Full features</div>
	  <div class="description">There are a lot of ready components, Models and Views</div>
	</div>
      </div>
      <div class="step">
	<i class="book icon"></i>
	<div class="content">
      <div class="title">Good documentation</div>
      <div class="description">Site, wiki, manuals and books</div>
	</div>
      </div>
      <div class="step">
	<i class="rocket icon"></i>
	<div class="content">
	  <div class="title">Powerfull, solid, fast</div>
	  <div class="description">You can experiment by yuorself</div>
	</div>
      </div>
      <div class="step">
	<i class="trophy icon"></i>
	<div class="content">
	  <div class="title">You win</div>
	  <div class="description">Get your revenue</div>
	</div>
      </div>
    </div>
  </div>
  <div class="row">
  </div>
  <div class="five wide column">
    <h2>Template Toolkit</h2>
    <p>The Template Toolkit is a fast, flexible and highly extensible template processing system. It is Free (in both senses: free beer and free speech), Open Source software and runs on virtually every modern operating system known to man. It is mature, reliable and well documented, and is used to generate content for countless web sites ranging from the very small to the very large.</p>
    <p><a class="ui button default" href="http://www.template-toolkit.org/" role="button">View details &raquo;</a></p>
  </div>
  <div class="five wide column">
    <h2>Semantic UI</h2>
    <p>Semantic is a development framework that helps create beautiful, responsive layouts using human-friendly HTML.<br>
      Semantic UI treats words and classes as exchangeable concepts.<br>
      Classes use syntax from natural languages like noun/modifier relationships, word order, and plurality to link concepts intuitively.</p>
    <p><a class="ui button basic" href="http://semantic-ui.com/" role="button">View details &raquo;</a></p>
  </div>
  <div class="four wide column">
    <h2>jQuery or Dojo</h2>
    <p>jQuery is common, but DojoToolkit is powerful and clean, stable and asynchronous. I would like to substitute jQuery with Dojo 2.0 as soon as it'll be released in 2017.</p>
    <p><a class="ui button basic" href="http://dojotoolkit.org/" role="button">View details &raquo;</a></p>
  </div>
</div>

</div> [%# ui container grid %]
<!-- END of welcome -->
__message.tt2__
[%~ TAGS star -%]
[% META title = 'Catalyst/TT View!' %]
<p>
  Yay!  You're looking at a page generated by the Catalyst::View::TT
  plugin module and Semantic UI.
</p>
<p>
  We have a message for you: <span class="message">[% message %]</span>.
</p>
<p>
  Why not try updating the message?  Go on, it's really exciting, honest!
</p>
<form action="[% site.url.message %]"
      method="POST" enctype="application/x-www-form-urlencoded">
 <input type="text" name="message" value="[% message %]" />
 <input type="submit" name="submit" value=" Update Message "/>
</form>
__error.tt2__
[% TAGS star -%]
[% META title = 'Catalyst/TT Error' %]
<p>
  An error has occurred.  We're terribly sorry about that, but it's
  one of those things that happens from time to time.  Let's just
  hope the developers test everything properly before release...
</p>
<p>
  Here's the error message, on the off-chance that it means something
  to you: <span class="error">[% error %]</span>
</p>
__signin.tt2__
[% TAGS star -%]
[% META title = 'Login' %]
[% # From: https://semantic-ui.com/examples/login.html %]

[% semanticui.page_css = BLOCK %]
    body {
      background-color: #DADADA;
    }
    body > .grid {
      height: 100%;
    }
    .image {
      margin-top: -100px;
    }
    .column {
      max-width: 450px;
    }
[% END %]

[% semanticui.page_js = BLOCK %]
$(document)
    .ready(function() {
      $('.ui.form')
        .form({
          fields: {
            email: {
              identifier  : 'email',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter your e-mail'
                },
                {
                  type   : 'email',
                  prompt : 'Please enter a valid e-mail'
                }
              ]
            },
            password: {
              identifier  : 'password',
              rules: [
                {
                  type   : 'empty',
                  prompt : 'Please enter your password'
                },
                {
                  type   : 'length[6]',
                  prompt : 'Your password must be at least 6 characters'
                }
              ]
            }
          }
        })
      ;
    })
  ;
[% END %]

<div class="ui middle aligned center aligned grid">
  <div class="column">
    <h2 class="ui teal image header">
      <img src="assets/images/logo.png" class="image">
      <div class="content">
        Log-in to your account
      </div>
    </h2>
    <form class="ui large form">
      <div class="ui stacked segment">
        <div class="field">
          <div class="ui left icon input">
            <i class="user icon"></i>
            <input type="text" name="email" placeholder="E-mail address">
          </div>
        </div>
        <div class="field">
          <div class="ui left icon input">
            <i class="lock icon"></i>
            <input type="password" name="password" placeholder="Password">
          </div>
        </div>
        <div class="ui fluid large teal submit button">Login</div>
      </div>

      <div class="ui error message"></div>

    </form>

    <div class="ui message">
      New to us? <a href="#">Sign Up</a>
    </div>
  </div>
</div>

__ttsite.css__
[% TAGS star %]
body {
  padding-top: 20px;
  padding-bottom: 40px;
}
.sidebar-nav {
  padding: 9px 0;
}

.error {
  color: #F11;
}
__respondjs.min.js__
/*! Respond.js v1.4.2: min/max-width media query polyfill * Copyright 2013 Scott Jehl
 * Licensed under https://github.com/scottjehl/Respond/blob/master/LICENSE-MIT
 *  */

!function(a){"use strict";a.matchMedia=a.matchMedia||function(a){var b,c=a.documentElement,d=c.firstElementChild||c.firstChild,e=a.createElement("body"),f=a.createElement("div");return f.id="mq-test-1",f.style.cssText="position:absolute;top:-100em",e.style.background="none",e.appendChild(f),function(a){return f.innerHTML='&shy;<style media="'+a+'"> #mq-test-1 { width: 42px; }</style>',c.insertBefore(e,d),b=42===f.offsetWidth,c.removeChild(e),{matches:b,media:a}}}(a.document)}(this),function(a){"use strict";function b(){u(!0)}var c={};a.respond=c,c.update=function(){};var d=[],e=function(){var b=!1;try{b=new a.XMLHttpRequest}catch(c){b=new a.ActiveXObject("Microsoft.XMLHTTP")}return function(){return b}}(),f=function(a,b){var c=e();c&&(c.open("GET",a,!0),c.onreadystatechange=function(){4!==c.readyState||200!==c.status&&304!==c.status||b(c.responseText)},4!==c.readyState&&c.send(null))};if(c.ajax=f,c.queue=d,c.regex={media:/@media[^\{]+\{([^\{\}]*\{[^\}\{]*\})+/gi,keyframes:/@(?:\-(?:o|moz|webkit)\-)?keyframes[^\{]+\{(?:[^\{\}]*\{[^\}\{]*\})+[^\}]*\}/gi,urls:/(url\()['"]?([^\/\)'"][^:\)'"]+)['"]?(\))/g,findStyles:/@media *([^\{]+)\{([\S\s]+?)$/,only:/(only\s+)?([a-zA-Z]+)\s?/,minw:/\([\s]*min\-width\s*:[\s]*([\s]*[0-9\.]+)(px|em)[\s]*\)/,maxw:/\([\s]*max\-width\s*:[\s]*([\s]*[0-9\.]+)(px|em)[\s]*\)/},c.mediaQueriesSupported=a.matchMedia&&null!==a.matchMedia("only all")&&a.matchMedia("only all").matches,!c.mediaQueriesSupported){var g,h,i,j=a.document,k=j.documentElement,l=[],m=[],n=[],o={},p=30,q=j.getElementsByTagName("head")[0]||k,r=j.getElementsByTagName("base")[0],s=q.getElementsByTagName("link"),t=function(){var a,b=j.createElement("div"),c=j.body,d=k.style.fontSize,e=c&&c.style.fontSize,f=!1;return b.style.cssText="position:absolute;font-size:1em;width:1em",c||(c=f=j.createElement("body"),c.style.background="none"),k.style.fontSize="100%",c.style.fontSize="100%",c.appendChild(b),f&&k.insertBefore(c,k.firstChild),a=b.offsetWidth,f?k.removeChild(c):c.removeChild(b),k.style.fontSize=d,e&&(c.style.fontSize=e),a=i=parseFloat(a)},u=function(b){var c="clientWidth",d=k[c],e="CSS1Compat"===j.compatMode&&d||j.body[c]||d,f={},o=s[s.length-1],r=(new Date).getTime();if(b&&g&&p>r-g)return a.clearTimeout(h),h=a.setTimeout(u,p),void 0;g=r;for(var v in l)if(l.hasOwnProperty(v)){var w=l[v],x=w.minw,y=w.maxw,z=null===x,A=null===y,B="em";x&&(x=parseFloat(x)*(x.indexOf(B)>-1?i||t():1)),y&&(y=parseFloat(y)*(y.indexOf(B)>-1?i||t():1)),w.hasquery&&(z&&A||!(z||e>=x)||!(A||y>=e))||(f[w.media]||(f[w.media]=[]),f[w.media].push(m[w.rules]))}for(var C in n)n.hasOwnProperty(C)&&n[C]&&n[C].parentNode===q&&q.removeChild(n[C]);n.length=0;for(var D in f)if(f.hasOwnProperty(D)){var E=j.createElement("style"),F=f[D].join("\n");E.type="text/css",E.media=D,q.insertBefore(E,o.nextSibling),E.styleSheet?E.styleSheet.cssText=F:E.appendChild(j.createTextNode(F)),n.push(E)}},v=function(a,b,d){var e=a.replace(c.regex.keyframes,"").match(c.regex.media),f=e&&e.length||0;b=b.substring(0,b.lastIndexOf("/"));var g=function(a){return a.replace(c.regex.urls,"$1"+b+"$2$3")},h=!f&&d;b.length&&(b+="/"),h&&(f=1);for(var i=0;f>i;i++){var j,k,n,o;h?(j=d,m.push(g(a))):(j=e[i].match(c.regex.findStyles)&&RegExp.$1,m.push(RegExp.$2&&g(RegExp.$2))),n=j.split(","),o=n.length;for(var p=0;o>p;p++)k=n[p],l.push({media:k.split("(")[0].match(c.regex.only)&&RegExp.$2||"all",rules:m.length-1,hasquery:k.indexOf("(")>-1,minw:k.match(c.regex.minw)&&parseFloat(RegExp.$1)+(RegExp.$2||""),maxw:k.match(c.regex.maxw)&&parseFloat(RegExp.$1)+(RegExp.$2||"")})}u()},w=function(){if(d.length){var b=d.shift();f(b.href,function(c){v(c,b.href,b.media),o[b.href]=!0,a.setTimeout(function(){w()},0)})}},x=function(){for(var b=0;b<s.length;b++){var c=s[b],e=c.href,f=c.media,g=c.rel&&"stylesheet"===c.rel.toLowerCase();e&&g&&!o[e]&&(c.styleSheet&&c.styleSheet.rawCssText?(v(c.styleSheet.rawCssText,e,f),o[e]=!0):(!/^([a-zA-Z:]*\/\/)/.test(e)&&!r||e.replace(RegExp.$1,"").split("/")[0]===a.location.host)&&("//"===e.substring(0,2)&&(e=a.location.protocol+e),d.push({href:e,media:f})))}w()};x(),c.update=x,c.getEmValue=t,a.addEventListener?a.addEventListener("resize",b,!1):a.attachEvent&&a.attachEvent("onresize",b)}}(this);
