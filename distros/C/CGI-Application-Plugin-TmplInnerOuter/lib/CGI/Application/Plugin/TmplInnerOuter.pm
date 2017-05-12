package CGI::Application::Plugin::TmplInnerOuter;
use strict;
use HTML::Template::Default 'get_tmpl';
require Exporter;
use Carp;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw/ Exporter /;
$VERSION = sprintf "%d.%02d", q$Revision: 1.13 $ =~ /(\d+)/g;
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
tmpl
tmpl_main
tmpl_output
tmpl_inner_name
tmpl_inner_name_set
tmpl_set
_debug_vars
));


*tmpl_main     = \&_tmpl_outer; # includes argument, this pulls outer, main.html template
*_tmpl_inner   = \&_tmpl; 
*tmpl          = \&_tmpl; # without argument, returns inner template

sub _tmpl_outer {
   my $self = shift;
   return $self->_tmpl('main.html');
}

sub _tmpl {
   my($self,$name) = @_;
   $name ||= $self->_get_tmpl_name;

   #$self->{_tmpl} ||= {};

   unless( $self->{_tmpl}->{$name} ) {
      my $path = $self->tmpl_path;
      $path ||= './';
      $self->tmpl_path( $path );

      my $tmpl = get_tmpl($name,$self->_get_tmpl_default($name)) 
         or warn("cant get [$name] template");
      $self->{_tmpl}->{$name} = $tmpl;       
   }
   
   return $self->{_tmpl}->{$name};
}

sub _set_tmpl_default {
   my ($self,$default,$name) = @_;
   defined $default or confess('missing template code arg');

   $name ||= $self->_get_tmpl_name;   
   #$self->{_tmpl_default} ||= {};
   $self->{_tmpl_default}->{$name} = \$default;
   return $name;
}

*tmpl_inner_name_set = \&tmpl_inner_name;

sub tmpl_inner_name {
   my ($self,$name) = @_;
   if( defined $name ){ $self->{__tmpl_inner_name} = $name }

   $self->{__tmpl_inner_name} ||= $self->get_current_runmode or die('no runmode');
   return $self->{__tmpl_inner_name};
}

sub _get_tmpl_name { $_[0]->tmpl_inner_name . '.html' }

sub _get_tmpl_default {
   my ($self,$name) = @_;
   $name ||= $self->_get_tmpl_name;
   #$self->{_tmpl_default} ||={};

   if ($name eq 'main.html' and ! defined $self->{_tmpl_default}->{'main.html'}){
      ### main.html was not defined, using default hard coded main.html template
      $self->_set_tmpl_default(
      q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" 
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
      <html>
      <head>
      <title><TMPL_VAR NAME=TITLE></title>
      <meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
      </head>
      <body>
      <TMPL_VAR NAME=BODY>
      </body>
      </html>},'main.html');
   }
   
   return $self->{_tmpl_default}->{$name};
}





*tmpl_set = \&_set_vars;
*_get_vars = \&_set_vars;
sub _set_vars {
   my $self = shift;
   #$self->{_tmpl_vars} || = {};
   #unless ( @_ ){
   #   return $self->{_tmpl_vars};
   #}
   

   my %vars = @_;  

   for ( keys %vars ){      
      my $key = $_; my $val = $vars{$key}; defined $val or next;
      $self->{_tmpl_vars}->{$key} = $val; 
   };

   #return 1;   
   $self->{_tmpl_vars}
}

sub _get_vars {
   my $self = shift;
   $self->{_tmpl_vars} ||={};
   return $self->{_tmpl_vars};
}

sub _feed_vars {
   my $self = shift;
   my $tmpl = shift;
   defined $tmpl or confess('missing arg');
   ### start
   my $vars = $self->_get_vars;
   VARS : for( keys %$vars){ 
			my $key = $_; 
         my $val = $vars->{$key};
         defined $val or next VARS;			
			$tmpl->param( $_ => $vars->{$_} );
	}
   ### ok
   return 1;
}


sub _debug_vars {
   my $self = shift; 
   my $neat_layout = shift; 
   $neat_layout ||=0;
   
   my $v = $self->_get_vars;
   my @k = sort keys %$v;
   scalar @k or return 1;   
   
   ### debug vars
   if($neat_layout){
   	map { printf STDERR " %18s : %s\n", $_, $v->{$_} } @k;			
   }
   
   else {   
      map { printf STDERR " %s'%s', ", $_, $v->{$_} } @k;
   }
   print STDERR "\n";
   return 1;
}



sub tmpl_output {
	my $self = shift;
   $self->_feed_vars_all;  
   $self->_feed_merge;   
   return $self->_tmpl_outer->output;
}


sub _feed_vars_all {
   my $self = shift;
   $self->_feed_vars( $self->_tmpl_inner );   
   $self->_feed_vars( $self->_tmpl_outer );   
   return 1;
}

sub _feed_merge {
	my $self = shift;
   $self->_tmpl_outer->param( BODY => $self->_tmpl_inner->output );
   return 1;
}

1;
