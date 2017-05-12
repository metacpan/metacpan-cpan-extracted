package CGI::Application::Gallery;
use strict;
use warnings;
use base 'CGI::Application';
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Forward;
use CGI::Application::Plugin::Feedback ':all';
use Carp;
use Data::Page;
use File::PathInfo::Ext;
use File::Path;
use CGI::Application::Plugin::Stream 'stream_file';
use CGI::Application::Plugin::Thumbnail ':all';
#use CGI::Application::Plugin::TmplInnerOuter;
use HTML::Template::Default 'get_tmpl';

use LEOCHARRE::DEBUG;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)/g;


sub setup {
	my $self = shift;
	$self->start_mode('browse');
   $self->run_modes([qw(browse view thumbnail download view_full)]);
}


sub cgiapp_postrun {
	my $self = shift;   
   printf STDERR "===== RUNMODE %s ==================\n", $self->get_current_runmode;
   return 1;     
}


sub browse { # runmode
	my $self = shift;
   if ($self->cwr->is_file){ 
      return $self->forward('view');
   }

   my $default = q{
   <div>
	<h5>Directories</h5>
	<ul>
	<TMPL_IF REL_BACK><li><a href="?rel_path=<TMPL_VAR REL_BACK>">Parent Directory</a></li></TMPL_IF>
	<TMPL_LOOP NAME="LSD">
	<li><a href="?rel_path=<TMPL_VAR REL_PATH>"><TMPL_VAR FILENAME></a></li>
	</TMPL_LOOP>
	</ul>
	</div>


   <h1><TMPL_VAR PAGE_TITLE></h1>
	<TMPL_IF CURRENT_PAGE>
	<div>
	<p>
   <TMPL_IF PREVIOUS_PAGE><a href="?current_page=<TMPL_VAR PREVIOUS_PAGE>"><<</a><TMPL_ELSE><<</TMPL_IF>
	<TMPL_IF CURRENT_PAGE> : Page <TMPL_VAR CURRENT_PAGE> : </TMPL_IF>
	<TMPL_IF NEXT_PAGE><a href="?current_page=<TMPL_VAR NEXT_PAGE>">>></a><TMPL_ELSE>>></TMPL_IF>
	</p>
	<p>
	<a href="?entries_per_page=5">[5pp]</a> : 
	<a href="?entries_per_page=10">[10pp]</a> : 
	<a href="?entries_per_page=25">[25pp]</a> 
	</p>
	</div>
	</TMPL_IF>

	
	<div>	
	<table cellspacing="0" cellpadding="4" width="100%">
	<tr>
	<TMPL_LOOP NAME="LS"> <td><a href="?rel_path=<TMPL_VAR REL_PATH>"><img src="?rm=thumbnail&rel_path=<TMPL_VAR REL_PATH>"></a></td>
	<TMPL_IF CLOSEROW></tr>
	<tr>
	</TMPL_IF>
	</TMPL_LOOP>
	</tr></table>
	
	};
   
   my $tmpl = get_tmpl('browse.html',\$default);


	$tmpl->param( 
      rel_path => $self->cwr->rel_path,
      rel_back => $self->_rel_back,
      LS       => $self->_files_loop,
      LSD      => $self->_dirs_loop,
      PAGE_TITLE => $self->cwr->rel_path,
   );

   if( my $pp = $self->_pager_params ){
      $tmpl->param(%$pp);
   }

   my $t = $self->tmpl_outer;
   $t->param( BODY => $tmpl->output );   
	return $t->output;
}

sub _pager_params {
   my $self = shift;

	if ( $self->pager->last_page > 1 ) { # if we need paging.   
		return {
         ENTRIES_PER_PAGE  => $self->pager->entries_per_page,
		   PREVIOUS_PAGE     =>	$self->pager->previous_page,
         CURRENT_PAGE      =>	$self->pager->current_page,
		   NEXT_PAGE         =>	$self->pager->next_page,	
      };      
	}	
   return;
}

# show parent link or not, return 0 if not
sub _rel_back {
   my $self = shift;
   $self->_show_parent_link or return 0;
   return '/'.$self->cwr->rel_loc ; 	
}

sub _files_loop {
   my $self = shift;

   $self->cwr->lsf_count or return [];
	my @files_all  = grep { !/^\.|\/\./g } @{ $self->cwr->lsf } or return [];
      
   my $count = scalar @files_all;
   debug("files all $count");

   my @files = $self->pager->splice( \@files_all ) or die;   
   my $loop = $self->_ls_tmpl_loop(\@files) or die;

   return $loop;
}

sub _dirs_loop {
   my $self = shift;
   $self->cwr->lsd_count or return [];

   my @dirs = grep { !/^\.|\/\./g } @{$self->cwr->lsd};
   @dirs and scalar @dirs or return [];

   my $loop = $self->_ls_tmpl_loop( \@dirs);
   return $loop;
}


sub _ls_tmpl_loop {
   my( $self, $ls ) = @_;   
   ref $ls eq 'ARRAY' or confess;

   my $base_rel_path = $self->cwr->rel_path;
   debug("base rel path '$base_rel_path'");
   

   my @loop = ();

	my $row = 3; # per row
   my $cell= 0;

	LS: for my $filename (@$ls){

      $cell++;

		my $rel_path = $base_rel_path ."/$filename";
		
      my $closerow = 0;
		if ( $cell == $row ){
         $cell     = 0;
         $closerow = 1;
      }
		
		push @loop, {
         rel_path => $rel_path,
         filename => $filename,
         closerow => $closerow,
      };
	}
   return \@loop;
}





sub thumbnail { # runmode
	my $self = shift; 

   my $rel = $self->query->param('rel_path')
      or debug('no rel')
      and return;

   $self->set_abs_image( $self->abs_document_root.'/'.$rel );
  
   #$self->get_abs_image('rel_path') or return;      
   $self->abs_thumbnail or return;    
   $self->thumbnail_header_add;

   $self->stream_file( $self->abs_thumbnail ) 
      or warn("thumbnail runmode: could not stream thumb ".$self->abs_thumbnail);
   #return 1;
}






sub view { # runmode
	my $self = shift;
   if ($self->cwr->is_dir){ 
      return $self->forward('browse');
   }

   my $default = q{
      <p><a href="?rm=browse&rel_path=<TMPL_VAR REL_BACK>">back</a></p>
      <h1><TMPL_VAR REL_PATH></h1>
      <p><img src="?rm=thumbnail&rel_path=<TMPL_VAR REL_PATH>&thumbnail_restriction=350x350"></p>
      <p><a href="?rm=view_full">full size</a> | <a href="?rm=view_full">download</a></p>
   };  

   my $tmpl = get_tmpl('view.html',\$default);

	$tmpl->param(
	   rel_path => '/'.$self->cwr->rel_path,
      rel_back => $self->_rel_back,
   );

   my $t = $self->tmpl_outer;
   $t->param( BODY => $tmpl->output );   
	return $t->output;
}



sub view_full { # runmode
	my $self = shift;
   if ($self->cwr->is_dir){ 
      return $self->forward('browse');
   }

   my $default = q{<a href="<TMPL_VAR REL_BACK>" title="back"><img src="?rm=download"></a>};  

   my $tmpl = get_tmpl('view.html',\$default);

	$tmpl->param(
	   rel_path => '/'.$self->cwr->rel_path,
      rel_back => '?rm=view',
   );

   my $t = $self->tmpl_outer;
   $t->param( BODY => $tmpl->output );   
	return $t->output;
}



sub download {
   my $self = shift;
   
   my $abs_path = $self->session->param('abs_path')
      or die('no file chosen');
   
   -f $abs_path or die('not file');

   my $filename = $abs_path;
   $filename=~s/^.+\/+//;

   require File::Type;
   my $m = File::Type->new;
   my $mime = $m->mime_type($abs_path);

   $self->header_add(
      '-type' => $mime,
      '-attachment' => $filename
    );
  
   if ( $self->stream_file( $abs_path ) ){
      return
   }
   die("could not stream file ".$abs_path);
}


# support subs



sub tmpl_outer {
   my $self = shift;

   my $default = q{
   <html>
   <body>
   <div>
   <TMPL_LOOP FEEDBACK>
   <p><small><TMPL_VAR FEEDBACK></small</p>
   </TMPL_LOOP>
   </div>
   
   <div>
   <TMPL_VAR BODY>
   </div>
   </body>
   </html>};

   my $tmpl = get_tmpl('main.html',\$default);
   
   $tmpl->param( FEEDBACK => $self->get_feedback_prepped );
   return $tmpl;
}




sub _show_parent_link {
   my $self = shift;
   return ( $self->cwr->is_DOCUMENT_ROOT ? 0 : 1 );
}





sub cwr { # current working resource
	my $self = shift;

	unless( $self->{cwr} ){
      my $abs = $self->abs_path;

      my $f = File::PathInfo::Ext->new( $abs );
      unless( $f ){
         $self->session->delete;
         die("not on disk $abs");
      }
      $f->DOCUMENT_ROOT_set($self->abs_document_root);
      $self->{cwr} = $f;
   }
         
	return $self->{cwr};
}
sub abs_path {
   my $self = shift;
   
   my $abs;

   # regardless, we want it in the session
   if( $abs = $self->_abs_from_query ){
      # to session
      $self->session->param(abs_path => $abs);
   }
   else { 
      $abs = $self->_abs_from_session;
   }
   return $abs;
}
sub _abs_from_query {
   my $self = shift;
   my $rel = $self->query->param('rel_path');
   defined $rel or debug('nothing in rel_path') and return;
   debug('got rel from q');
   if ( defined $rel and $rel eq ''  ){ # if def by empty string.. reset
      debug('empty string');
         return $self->abs_document_root;
   }
   debug("had $rel");
   return Cwd::abs_path( $self->abs_document_root . '/'. $rel ); # TODO make sure this is within docroot
}
sub _abs_from_session {
   my $self = shift;
   $self->session->param('abs_path') 
      or $self->session->param( 'abs_path' => $self->abs_document_root );
      debug('session.. '.$self->session->param('abs_path'));
   return $self->session->param('abs_path');
}







*_abs_path_default = \&abs_document_root;
sub abs_document_root {
   my $self = shift;
   unless( $self->{abs_document_root_resolved} ){
      my $a = $self->param( 'abs_document_root' ) or croak('missing abs_document_root param to constructor');
      require Cwd;
      my $r = Cwd::abs_path($a) or die("can't resolve '$a' to path");
      $self->{abs_document_root_resolved} = $r;
   }
   return $self->{abs_document_root_resolved};
}

sub _rel_path_default {
   return '/';
}




# PAGER

sub pager {
	my $self = shift;
	$self->cwr->is_dir or croak('why call paging(), this is not a dir.');
	unless($self->{pager}){
	
		$self->{pager} = new Data::Page(

         $self->cwr->lsf_count, 
         $self->user_pref( entries_per_page => 10 ), 
         $self->user_pref( current_page => 1 )
      );			
	}
	return $self->{pager};
}

sub user_pref {
   my ( $self, $param_name, $default ) = @_;
   
   my $val = $self->query->param($param_name);
   if( defined $val and $val eq '' ){
      $self->session->param( $param_name => $default );
   }
   
   elsif( $val ){
      $self->session->param( $param_name => $val );
   }

   return $self->session->param($param_name);
}
 


1;
