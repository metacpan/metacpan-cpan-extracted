package CGI::Application::Plugin::TmplInnerOuter;
use strict;
use warnings;
require Exporter;
use Carp;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw/ Exporter /;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;
@EXPORT = (qw(
_feed_merge
_feed_vars
_feed_vars_all
_get_tmpl_default
_get_tmpl_name
_get_vars
_set_tmpl_default
_set_vars
_tmpl
_tmpl_inner
_tmpl_outer
tmpl_outer
tmpl_inner
tmpl
tmpl_main
tmpl_output
tmpl_inner_name
tmpl_inner_name_set
tmpl_set
_debug_vars
));

*_get_tmpl_name      = \&tmpl_inner_name;
*_get_tmpl_default   = \&_tmplsetget_code;
*tmpl_inner_name_set = \&tmpl_inner_name;
*_tmpl_inner         = \&tmpl_inner;
*_tmpl_outer         = \&tmpl_outer;
 *tmpl               = \&tmpl_inner;
 *tmpl_main          = \&tmpl_outer;
*_tmpl               = \&_tmplsetget_object;

*_set_vars  = \&tmpl_var;
*_get_vars  = \&tmpl_var;
*tmpl_param = \&tmpl_var;
*tmpl_set   = \&tmpl_var;

*_set_tmpl_default = \&_tmplsetget_code;
*tmpl_code =\&_tmplsetget_code;




# storage
# if you pass a 'inner' or 'outer' arg, it returns an object
sub _tmpl_master {
   my $self  = shift;

   my($name,$code,$object,$request);

   VAL: for my $val (@_){
      defined $val or next;
      my $ref = ref $val;
      if ($ref and $ref=~/template/i )){ #TODO how to test for blessed, returns name of pkg
         $object = $val;
         next VAL;
      }
      elsif ($val=~/\.\w{1,5}$/){
         $name = $val;
         next VAL;
      }
      elsif( ($val eq 'inner') or ($val eq 'outer') ){
         $request = $val;
         next VAL;
      }
      # lastly if it's defined and we dunno what it is, assume it's a template code
      $code = $val;
   }
   
   # if 'inner' or 'outer' was  here, autogen name unless defined already in obj
   
   if( $request ){
      
      # if no name arg, do we have one stored?
      if (! defined $name ){

         if( exists $self->{_tmpl_master}->{"$request\_name"} ){ # was it already set?
            $name = $self->{_tmpl_master}->{"$request\_name"};
         }

         else { # autogenerate attempt

            if ($request eq 'inner'){
               $name = $self->get_current_runmode or die('cant get current runmode');
               $name.='.html';
            }

            elsif($request eq 'outer'){
               $name = 'main.html';
            }

            else {
               die("cant autogen name.html for request $request");
            }

            $self->{_tmpl_master}->{"$request\_name"} = $name;
            #  resolved if we got here
         }

         # name is defined
         $name or die('still no name');
      }


      else { # if defined both inner/outer and name in args...
         # then save
         $self->{_tmpl_master}->{"$request\_name"} = $name;

      }
      
      $name or die('still no name!');
   }



   # name HAS to be defined.
   $name or die('missing name.ext arg');

   $self->{_tmpl_master}->{$name} ||= { code => undef, object => undef };

   if ($code){
      $self->{_tmpl_master}->{$name}->{code} = $code;
   }

   if ($object){
      $self->{_tmpl_master}->{$name}->{object} = $object;
   }


   if($request){
      # then we return an object even if none is present already
      
      $object ||= $self->{_tmpl_master}->{$name}->{object};

      unless( $object ){ #still no object, must be first instance..
         
         my $coderef;
         $code = $self->{_tmpl_master}->{$name}->{code};
         if ($code){  
            $coderef =\$code;
         }

         # might be undefined, that's ok
         require HTML::Template::Default;
         $object = HTML::Template::Default::get_tmpl($name, $coderef)
            or die("cant instace $name $request");

         $self->{_tmpl_master}->{$name}->{object} = $object;
      }

   }





   #  return object if there is one, otherwise it's undef
   return $self->{_tmpl_master}->{$name}->{object};
}
=pod

to get template

   $self->_tmpl_master('inner');
   $self->_tmpl_master('outer');


set default template code and filename without loading

   $self->_tmpl_master('


=cut




sub _tmpl_name {
   my($self,$val,$name) = @_;
   $self->{_tmpl_name} ||= {};
   if(defined $val and ! defined $name){
      if($val eq 'inner'){
         $self->{_tmpl_name}->{$val} ||= $self->get_current_runmode .'.html';
         return $self->{_tmpl_name}->{$val};
      }
      elsif($val eq 'outer'){
         $self->{_tmpl_name}->{$val} = 'main.html';
         return $self->{_tmpl_name}->{$val};
      }
      else {
         return $self->{_tmpl_name}->{$val}; # might be undef, most likely
      }
   }
   elsif( defined $val and defined $name){
      $self->{_tmpl_name}->{$val} = $name;
      return $name;
   }
   croak('missing args');
}
# tmpl_name( inner => 'this.html' ); # sets
# tmpl_name( inner ); # gets

sub tmpl_inner_name {
   my($self,$val) = @_;
   return $self->_tmpl_name('inner', $val); # val can be undef
}

sub tmpl_outer_name {
   my($self,$val) = @_;
   return $self->_tmpl_name('outer', $val); # val can be undef
}

sub tmpl_outer {
   my ($self,$tmpl) = @_;
   my $name = $self->tmpl_outer_name;
   if(defined $tmpl ){
      return $self->_tmplsetget_object($name, $tmpl);
   }
   return $self->_tmplsetget_object($name);
}



sub tmpl_inner {
   my ($self,$tmpl) = @_;
   my $name = $self->tmpl_inner_name;
   if(defined $tmpl ){
      return $self->_tmplsetget_object($name, $tmpl);
   }
   return $self->_tmplsetget_object($name);
}

sub tmpl_inner_name {
   my($self,$name)= @_;
   if(defined $name){
      $name=~/\.[a-z]{3,5$/i or $name.='.html';

      $self->{_tmpl_inner_name} = $name;
      return $name;
   }
   unless( $self->{_tmpl_inner_name} ){
      my $rm = $self->get_current_runmode or die('cant get current runmode');
      $self->{_tmpl_inner_name} = "$rm.html";
   }
   return $self->{_tmpl_inner_name};
}

sub tmpl_outer_name {
   my($self,$name)= @_;
   if(defined $name){
      $name=~/\.[a-z]{3,5$/i or $name.='.html';

      $self->{_tmpl_outer_name} = $name;
      return $name;
   }
   unless( $self->{_tmpl_outer_name} ){
      $self->{_tmpl_outer_name} = "main.html";
   }
   return $self->{_tmpl_outer_name};
}



sub _tmplsetget_object {
   my($self,$name,$object) = @_;

   $name ||= $self->tmpl_inner_name; # or outer?

   if(defined $object){
      $self->{_tmplsetget}->{$name} = $object;
      return $object;
   }

   elsif ( defined $name ){
      
      if( my $tmpl = $self->{_tmplsetget}->{$name} ){
         return $tmpl;
      }

      my $default_code = $self->_tmplsetget_code($name);
      if ((! defined $default_code ) and ($self->tmpl_outer_name eq $name) ){
         $default_code = $self->_tmplsetget_code('main.html', __main_html());
      }

      require HTML::Template::Default;

      if ( my $tmpl = HTML::Template::Default::get_tmpl($name, $default_code) ){
         $self->{_tmplsetget}->{$name} = $tmpl;
         return $tmpl;
      }
      else {
         die("cant instance $name template");
      }
   }

   croak('no name or object provided.');
}

sub _tmplsetget_code {
   my $self = shift;

   my($code,$name);

   for my $val (@_){
      if( defined $val){
         if ($val=~/^\w+\.html$/){{
            $name = $val;
         }
         else {
            $code =$val;
         }
      }
   }
   $name ||= $self->tmpl_outer_name;

   if(defined $code){
      $self->{_tmplsetget_code}->{$name} = $code;
      return $code;
   }
   elsif ( defined $name ){
      
      if( my $code = $self->{_tmplsetget_code}->{$name} ){
         return $code;
      }
      else {
           return; #it's ok to return undef code, it just insists for a file template on disk
      }
   }
   croak('no name or code provided');
}



sub __main_html {
   my $self = shift; 
  
  return  q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" 
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <html>
      <head>
      <title><TMPL_VAR NAME=TITLE></title>
      <meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
      </head>
      <body>
      <TMPL_VAR NAME=BODY>
      </body>
      </html>};
}

sub tmpl_output {
	my $self = shift;
   $self->_feed_vars_all;  
   $self->_feed_merge;   
   return $self->tmpl_outer->output;
}

sub _feed_vars_all {
   my $self = shift;
   $self->_feed_vars( $self->tmpl_inner );   
   $self->_feed_vars( $self->tmpl_outer );   
   return 1;
}

sub _feed_merge {
	my $self = shift;
   $self->tmpl_outer->param( BODY => $self->tmpl_inner->output );
   return 1;
}


sub tmpl_var {
   my $self = shift;
   $self->{_tmpl_vars} ||={};

   if ( @_ ){
      my %vars = @_;
      for ( keys %vars ){      
         my $key = $_; 
         my $val = $vars{$key}; 
         defined $val or next;
         $self->{_tmpl_vars}->{$key} = $val; 
      };
   }
   $self->{_tmpl_vars};
}


sub _feed_vars {
   my $self = shift;
   my $tmpl = shift;
   defined $tmpl or confess('missing arg');
   debug('start');
   my $vars = $self->tmpl_var;
   VARS : for( keys %$vars){ 
			my $key = $_; 
         my $val = $vars->{$key};
         defined $val or next VARS;			
			$tmpl->param( $_ => $vars->{$_} );
	}
   debug("ok\n");
   return 1;
}


sub _debug_vars {
   my $self = shift; 
   my $neat_layout = shift; 
   $neat_layout ||=0;
   
   my $v = $self->tmpl_var;
   my @k = sort keys %$v;
   scalar @k or return 1;   
   
   debug();
   if($neat_layout){
   	map { printf STDERR " %18s : %s\n", $_, $v->{$_} } @k;			
   }
   
   else {   
      map { printf STDERR " %s'%s', ", $_, $v->{$_} } @k;
   }
   print STDERR "\n";
   return 1;
}


sub debug { print STDERR "@_\n" }

1;

__END__


=pod

=head1 NAME

CGI::Application::Plugin::TmplInnerOuter

=head1 SYNOPSIS

   use CGI::Application::Plugin::TmplInnerOuter;

=head1 DESCRIPTION

GOAL 1: INNER OUTER CONCEPT
   Have 1 main template, into which the other templates for each runmode are inserted
   I dont want to have to stick TMPL_INCLUDE for a header and footer
   So for runmode 'daisy', i want to use daisy.html but also main.html into which daisy.html goes.

GOAL 2: HARD CODED TEMPLATES WITH OPTION TO OVERRIDE
   I want to define a template hard coded, and offer the option to override by the user- by simply
   making the template exist where we suspect to find it.
   This is done with HTML::Template::Default

GOAL 3:
   Provide a means via which we store all parameters that will go into the template later, and at the last
   state output to browser.


=head2 OUTER

The outer template should hold the things that are present in every page, in every runmode view.
Your header, logout buttons, navigation, footer etc.

First you can to define your main template.

main.html:

   <html>
   <head>
   <title><TMPL_VAR TITLE></title>
   </head>
   <body>
   
   <TNPL_VAR NAME=BODY>
   
   </body>
   </html>

This can either be saved as 'main.html' or it can be Set Hard Coded.
If you set it hard coded into your app, if the main.html file exists, it overrides the hard coded version.
This is how you can include your template code in your modules but still let people override them.

How you would Set Hard Coded, main.html:

  my $code =   q{<html>
   <head>
   <title><TMPL_VAR TITLE></title>
   </head>
   <body>
   
   <TMPL_VAR NAME=BODY>
   
   </body>
   </html>}; 

   $self->tmpl_outer


The very basic template shown above for main is already included.
You can override it as shown above.
This means you can safely code whatever inside guts, and change the look and feel of the app
radically by creating a main.html file on disk, and doing what you want with it!

=head2 INNER

Then you have to set an inner template, this is the template relevant to your current runmode.
If your runmode is 'continue' then template sought is 'continue.html'
When setting a default inner template, the name argument does not need be provided.

   sub continue : Runmode {
      my $self = shift;
      $self->_set_tmpl_default( q{<h1>Would you like to continue?</h1>} );

      return $self->tmpl_output;
   }

Another example; your runmode being 'jimmy'.. this is what you would do:

   sub Jimmy : Runmode {
      my $self = shift;
      my $default = q{<p> I said: <TMPL_VAR BLABLA> </p>};
      
      $self->_set_tmpl_default($default);      
      

      
      $self->_set_vars(   BLABLA => 'This is what I said.' );
      # or
      $self->tmpl->param( BLABLA => 'This is what I said.' );

      return $self->tmpl_output;
   }

If you have Jimmy.html file in TMPL_PATH, then it is used as the inner template, regardless if you hard code it.

=cut


=head1 METHODS

All methods are exported.

=cut

=head2 tmpl_inner_name() and tmpl_inner_name_set()

name of inner template name, by default we use the current runmode, if you pass string 'this' to set, 
will look for this.html for the inner template

=head2 _set_tmpl_default()

argument is your html template code.
this is what would go in HTML::Template::Default::get_tmpl();

optional argument is a name of the template, such as 'main.html'.
If you do not specifiy a page name, it is assumed you are setting the inner template's default code.
The runmode appended by .html is the page name.

To set outer (main) template:

   $self->_set_tmpl_default( $maincode, 'main.html' );

=head2 tmpl(), _inner_tmpl(), _tmpl()

returns inner template HTML::Template object. 
You can use this, but I suggest you instead set variables via _set_vars()
tmpl_output() will later insert them, and insert the inner template output into the main template.

_tmpl_inner() also returns inner template, so would _tmpl() with no arguments.

=head2 tmpl_main(), _outer_tmpl(), _tmpl('main.html')

returns outer template HTML::Template object.
So would _tmpl_outer() and _tmpl('main.html')


=head2 _get_tmpl_name()

if your runmode is goop, this returns goop.html


=cut




=head1 METHODS FOR HTML TEMPLATE VARIABLES

these are exported, you do not have to use them

=head2 _set_vars(), tmpl_set()

argument is hash
sets variables that later will be inserted into templates
tmpl_set() is an alias for _set_vars()

instead of use tmpl->param( KEY => VAL ) ... use...

   $self->_set_vars( 
      USER  => 'Joe',
      TODAY => time_format('yyyy/mm/dd', time)
   );
   
And then

   $self->_feed_vars( $tmpl);

It is NOT presently supported to pass undefined values, if you do, they
are silently ignored.

   $self->_feed_vars( PARAM => undef );


=head2 _get_vars()

returns hash ref of vars set with _set_vars()
this is what is injected into teh templates, both of them.

=head2 _feed_vars()

argument is HTML::Template object
feeds vars into template

   $self->_feed_vars($tmpl_object);
   $self->_feed_vars($self->tmpl);
   $self->_feed_vars($self->tmpl_main);

=head2 _debug_vars()

print to STDERR all vars that will be fed, sorted
optional arg is boolean to print in an orderly fashion

=head1 OUTPUT

=head2 tmpl_output()

combines the inner and outer templates, feeds variables, returns output.
this should be the last thing called by every runmode
You may want to override the default output method, to insert other things into it.

=head3 Example 1:

   sub show_cactus : Runmode {
      my $self = shift;      
      
      my $html = q{
       <h1><TMPL_VAR TITLE></h1>
       <p>your html template code.</p>
       <small><TMLP_VAR MESSAGE></small>
      };

      $self->_set_tmpl_default($html);   
      
      $self->_set_vars( 
         TITLE => 'This is the title, sure.'
         MESSAGE => 'Ok, this is text.',
      );

      $self->_feed_vars($self->tmpl);
      $self->_feed_vars($self->tmpl_main);

      # every runmode that shows output should use this:
      return $self->tmpl_output;
      
   }

=head3 Example 2:

The next example does the same exact thing, imagining you have a show_cactus.html template on disk,
in TMPL_PATH (see L<CGI::Application>).

   sub show_cactus : Runmode {
      my $self = shift;      
            
      $self->_set_vars( 
         TITLE => 'This is the title, sure.'
         MESSAGE => 'Ok, this is text.',
      );
      
      return $self->tmpl_output;      
   }

The arguments to _set_vars are fed to both the inner template (show_cactus.html) 
and the outer template (main.html).
All of the code of the inner template will be inserted into the <TMPL_VAR BODY> tag of the
outer template. So, your inner template should not have html start and end tags, body tags etc.


=head2 Overriding default tmpl_output()

The default out simply feeds output to the inner and outer templates.
At any point in the application from any method you can call _set_vars() to preset variables
that will be sent to both inner and outer templates (harmless with this system).
Maybe you have a navigation loop for example that you want to insert just at the last moment.

If so.. here is one example:

   no warnings 'redefine';
   
   sub tmpl_output {
   	     my $self = shift;
      
           $self->_set_vars( NAVIGATION_LOOP => $self->my_navigation_loop_method );
      
           $self->_feed_vars_all;  
           $self->_feed_merge;
           $self->_debug_vars();  # prints to STDERR all the vars
           $self->_debug_vars(1); # prints to STDERR all the vars, in an orderly fashion

           return $self->tmpl_outer->output;
      
      # or return $self->tmpl_main->output;
      
      # or return $self->_tmpl('main.html')->output;     
   }

This way all runmodes returning tmpl_output() don't need to change anything about them.

=head2 _feed_vars_all()

takes no argument
feeds any vars set with _set_vars() into both inner and outer templates
returns true.

=head2 _feed_merge()

inserts output of inner template into outer template.
(inserts output of runmode template into main template.)
returns true.




=head1 EXAMPLE USAGE

For a great example of this module in action please see L<CGI::Application::Gallery>.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO

HTML::Template
HTML::Template::Default
CGI::Application
LEOCHARRE::DEBUG

