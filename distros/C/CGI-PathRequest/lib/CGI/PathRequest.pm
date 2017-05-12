package CGI::PathRequest;
use strict;
use warnings;
use File::MMagic;
use base 'File::PathInfo::Ext';
use Carp;
use CGI;
use HTML::Entities;
use vars qw/$VERSION $DEBUG/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.19 $ =~ /(\d+)/g;
$DEBUG = 0;
sub DEBUG : lvalue { $DEBUG }

sub new {
	my ($class, $self) = (shift, shift);
	if (defined $self and ref $self ne 'HASH'){
		$self = __PACKAGE__->SUPER::new($self);		
	}
	
	$self								||= {};	
	$self->{param_name}		   ||= 'rel_path';	
	$self->{default}			   ||= undef; # what is the default	   
	$self->{tainted_request}   and ( $self->{rel_path} = $self->{tainted_request} );    
	$self->{rel_path}			   ||= undef;		
	$self->{excerpt_size}		||= 255; # chars if excerpt is called for	
	$self->{status}				= [];
	$self->{request_made}		= 0; # was a request received

	$self->{tainted_request} 
      and carp('warning: argument tainted_path to CGI::PathRequest is deprecated.'); 
	$self->{default} 
      and carp("use of 'default' to CGI::PathRequest is deprecated"); 	

	bless $self, $class;	


   if ($self->_arg){
      ### settiong
	   $self->set( $self->_arg ) or return; #or $self->{data}->{exists} = 0;
   }   

   ### ok
	return $self;
}

sub exists {
	my $self = shift;
	if (defined $self->{data}->{exists}){
		return $self->{data}->{exists};
	}	
	( -e $self->abs_path ) ? ( $self->{data}->{exists} = 1) : ($self->{data}->{exists} = 0);		
	return $self->{data}->{exists};
}




# run once!?
sub _arg {
	my $self = shift;
	
	unless ( defined $self->{_arg} ){
		### getting _arg
		my $argument = undef;
	
		if (defined $self->{rel_path}){
			#### from constructor
			$self->{request_method} = 'constructor argument';
			
			$argument = $self->{rel_path};
		}		

		
		elsif ( my $fromcgi = $self->_get_rel_path_from_cgi ){
			#### from cgi
			$self->{request_method} = 'from cgi';
			$argument= $fromcgi;
		}

		else {
			#### none
			$self->{request_method} = 'none';		
		}
	
	#	if( $argument ){
		#	$argument=~s/^\///; # hack			
	#	}
		
		#$argument ||= $self->DOCUMENT_ROOT;	
		#### $argument

      defined $argument or return; 
		$self->DOCUMENT_ROOT or die("DOCUMENT_ROOT not defined?"); 
		if ( -e $self->DOCUMENT_ROOT .'/'.$argument ){
			$argument = $self->DOCUMENT_ROOT .'/'.$argument;
		}
		
      
		$self->{_arg} = $argument;		
	}			
	
	return $self->{_arg};	
}

# NETWORK METHODS ...... cgi and host etc. www. etc etc

sub _network {
	my $self = shift;

	unless (defined $self->{_data}->{_network}){

		my $data = { server_name => undef };

		if (defined $self->{SERVER_NAME}){
			$data->{server_name} = $self->{SERVER_NAME};		
		}

		elsif (defined $ENV{SERVER_NAME}){
			$data->{server_name} = $ENV{SERVER_NAME};		
		}

		elsif ($self->get_cgi->server_name)  {
			$data->{server_name} = $self->get_cgi->server_name;
		}

		if ( $data->{server_name} ) { # we can get server name

			if ($self->get_cgi->https){	
				$data->{www} = 'https://'.$data->{server_name};
			}
			else {
				$data->{www} = 'http://'.$data->{server_name};				
			}

			# how we see from the net
			$data->{url} = $data->{www} .'/'.$self->rel_path;

		}
		
		$self->{_data}->{_network} = $data;
	}
	
	return $self->{_data}->{_network};	
}

sub server_name {
	my $self = shift;
	#return $self->get_cgi->server_name;
	return $self->_network->{server_name};
}	

sub url {
	my $self = shift;
	return $self->_network->{url};
}

sub www {
	my $self = shift;
	return $self->_network->{www};
}

sub get_cgi {
	my $self = shift;
	$self->{ cgi }	||= new CGI;	
	return $self->{cgi};	
}





















# test existancem, type, etc
# will attempt to default IF DOES NOT EXIST
sub _extended {
	my $self = shift;

	croak($self->errstr) if $self->errstr;

	if (defined $self->{_data}->{_extended}){
		return $self->{_data}->{_extended};
	}


	my $data = {};
	

	# TODO: presently not doing anything for other file types, pipes, etc
		
	if ($self->is_dir){
		$data->{filetype}='d';		
	}
	elsif ($self->is_file){
		$data->{filetype}='f';	
	}
	else {
		warn "filetype for $$data{abs_path} is not d or f, unsupported.";
	}

	$data->{is_root} = ( $self->is_DOCUMENT_ROOT ? 1 : 0 );

	$data->{filename_pretty}= $self->filename_only or die('filename_only returns nothing?'.$self->abs_path);	
	$data->{filename_pretty}=~s/_/ /sg;	
	$data->{filename_pretty} = join '', map {ucfirst lc} split (/(?=\s)/, $data->{filename_pretty}); # http://perlmonks.org/?node_id=471292

	$data->{alt} = $data->{filename_pretty};
	$data->{is_html} = $self->is_html;
	$self->{_data}->{_extended} = $data;	

	return $self->{_data}->{_extended};
}

sub is_html {
	my $self = shift;
	$self->is_text or return 0;	
	$self->ext=~/s?html?$/i or return 0;
	return 1;
}

sub is_root {
	my $self = shift;
	return $self->_extended->{is_root};	
}

sub filename_pretty {
	my $self = shift;
	return $self->_extended->{filename_prety};
}
sub alt  { 
  my $self = shift;
  return $self->_extended->{alt};	
}

sub filetype  { 
  my $self = shift;
	
  return $self->_extended->{filetype};	
}


# mime type etc, maybe should be in File::PathInfo.. ?? hmmmm
sub _more {
	my $self = shift;
	
	croak($self->errstr) if $self->errstr;	

	unless (defined $self->{_data}->{_extended_more} ){
	
		my $mime_type = undef;;
		unless ($self->is_dir){		
			my $m = new File::MMagic;	
			$mime_type = $m->checktype_filename( $self->abs_path );
		}	
		

		my $data = {		
		 	is_image			=> ( $self->is_file ? ( $mime_type=~m/image/ or 0 ) : 0 ),				
			mime_type		=> $mime_type,
		};
		
		$self->{_data}->{_extended_more} = $data;
	}

	return $self->{_data}->{_extended_more};
}

sub is_image  { 
 my $self = shift;
 return $self->_more->{is_image};
}

sub mime_type  { 
 my $self = shift;
 return $self->_more->{mime_type};
}



# content and excerpt
sub _guts {
	my $self = shift;

	croak($self->errstr) if $self->errstr;	

	$self->is_text or return {}; # TODO: is this right?
	
	
	unless( defined $self->{_data}->{_guts} ){
		my $guts = {};
	
		my $slurp;
		{
			local (*INPUT, $/);
			open (INPUT, $self->abs_path);
			$slurp = <INPUT>;
			close INPUT;
		}
		$guts->{content} = $slurp;
		$guts->{content} ||= undef;		

	
		if( $guts->{content} ){

			$self->{excerpt_size} ||= 255;
			my $limit = $self->{excerpt_size};
			
			$guts->{excerpt} = $guts->{content};
			$guts->{excerpt}=~s/\<[^<>]+\>/ /sg; # take out html
			
			$guts->{excerpt}=~s/^(.{1,$limit}).+/$1\.\.\./s;
			
			$guts->{excerpt_encoded} = encode_entities($guts->{excerpt});
			
		}
		$self->{_data}->{_guts} = $guts;
		
	}

	return $self->{_data}->{_guts};
}

sub get_content {
	my $self = shift;
	return $self->_guts->{content};
}

sub get_excerpt { 
	my $self = shift;
	return $self->_guts->{excerpt};
}

# made decision not to do this 'by default' with the whole content to be more frugal
sub get_content_encoded {
	my $self = shift;
	my $out = encode_entities( $self->_guts->{content} );
	return $out;
}

sub get_excerpt_encoded { 
	my $self = shift;
	return $self->_guts->{excerpt_encoded};	
}













# LS METHODS 


# must be loaded
sub _ls {
	my $self = shift;
	$self->is_dir or warn $self->abs_path ."is not a dir" and return {};	
	

	unless ( defined $self->{_data}->{_ls} ){
		my $data={};

		opendir(DIR, $self->abs_path) 
			or croak("$! - cant open dir ".$self->abs_path.", check permissions?");
		my @ls = sort grep { !/^\.+$/ } readdir DIR;
		closedir DIR;

		
		my @lsd = grep { -d $self->abs_path."/$_" } @ls; 
		my @lsf = grep { -f $self->abs_path."/$_" } @ls; 

		$data->{ls}  = \@ls;
		$data->{lsd} = \@lsd;
		$data->{lsf} = \@lsf;
		
		$data->{ls_count}  = scalar @ls;
		$data->{lsd_count} = scalar @lsd;
		$data->{lsf_count} = scalar @lsf;		

		$self->{_data}->{_ls} = $data;
	}

	return $self->{_data}->{_ls};
}

sub ls {
	my $self = shift;
	return $self->_ls->{ls};	
}

sub lsd {
	my $self = shift;
	return $self->_ls->{lsd};	
}

sub lsf {
	my $self = shift;
	return $self->_ls->{lsf};	
}

sub ls_count {
	my $self = shift;
	return $self->_ls->{ls_count};	
}

sub lsd_count {
	my $self = shift;
	return $self->_ls->{lsd_count};	
}

sub lsf_count {
	my $self = shift;
	return $self->_ls->{lsf_count};	
}

sub is_empty_dir {
	my $self = shift;
	$self->is_dir or return;
	$self->ls_count or return 1;
	return 0;
}




# HTML::Template METHODS

sub nav_prepped { 
	my $self = shift;

	unless ( defined $self->{_data}->{nav_loop} ){
	
		my $onetime=0;

		my @nav_loop=();	

		my $r = $self; # start by self

	
		
		until ( $r->is_DOCUMENT_ROOT){
	
			# 1 step
			my $element = {
				rel_path => $r->rel_path,
				abs_path => $r->abs_path,
				rel_loc => $r->rel_loc,
				abs_loc => $r->abs_loc,
				filename => $r->filename,  
				filetype => ($r->is_dir ? 'd' : 'f' ),
				ext => $r->ext,
			};

         {
            no warnings;
			   # if we dont eliminate unset ones, HTML::Template will produce errors
			   for (keys %{$element}){            
				   $element->{$_}=~/\w/ or delete $element->{$_};
			   }
         };
			
			unless ($onetime) {
				$element->{'last'} = 1;
				$onetime=1;
			} # indicate this is first element, i know 
			# it says last.. thing is we reeverse it for html template.. so that.. anyway.
		
			push @nav_loop, $element;
			my $abs_next = $r->abs_loc;
 			$r = new File::PathInfo;
			$r->set($abs_next);
			
			
		}	

		#### @nav_loop

		$self->{_data}->{nav_loop} = [ reverse @nav_loop ];         
      # TODO: I keep getting errors here when the array length is 0- errors from
      # HTML Template

	}
	
	
	return $self->{_data}->{nav_loop};
}





sub lsd_prepped {
	my $self = shift;
	$self->is_dir or return;
	if ( scalar @{$self->lsd} ){
		my $prepped = [];

		for (@{$self->lsd}){
			push @{$prepped}, { 
					filename => $_,
					rel_path => $self->rel_path."/$_",
					rel_loc => $self->rel_path,
					abs_path =>$self->abs_path."/$_",
					abs_loc => $self->abs_path,
					filetype => 'd',
					is_dir => 1,
					is_file => 0,
					is_root => 0,
			};
		}
		return $prepped;
	}	
	return [];
}

sub lsf_prepped {
	my $self = shift;
	$self->is_dir or return;
	if (scalar @{$self->lsf}){
		my $prepped = [];

		for (@{$self->lsf}){
			push @{$prepped}, { 
				filename => $_,
				rel_path => $self->rel_path."/$_",
				rel_loc => $self->rel_path,
				abs_path =>$self->abs_path."/$_",
				abs_loc => $self->abs_path,
				filetype => 'f',
				is_dir => 0,
				is_file => 1,
				is_root => 0,
			};
		}
		return $prepped;
	}	
	return [];
}

sub ls_prepped {
	my $self = shift;
	$self->is_dir or return;

	if (scalar @{$self->ls}){
		my $prepped = [];
		push @{$prepped}, @{$self->lsd_prepped};
		push @{$prepped}, @{$self->lsf_prepped};
		return $prepped;
	}	

	return [];
}


## ALL DATA METHODS

sub get_datahash_prepped {
	my $self = shift;
	my $data = $self->get_datahash;
	my $prepped;
	for (keys %{$data}) {
		if(ref $data->{$_} ){ next;}
		defined $data->{$_} or next;
		$data->{$_}=~/\w/ or next;
		$prepped->{$_} = $data->{$_};
	}

	return $prepped;
}
	


# WHOLE HASH
	
sub get_datahash{
	my $self = shift;

	my $data = $self->SUPER::get_datahash;
	
	for (keys %{$self->_network}){
		if (defined $self->_network->{$_}){
			$data->{$_} = $self->_network->{$_};
		}
	}
	
	for (keys %{$self->_guts}){
		if (defined $self->_guts->{$_}){
			$data->{$_} = $self->_guts->{$_};
		}
	}

	for (keys %{$self->_extended}){
		if (defined $self->_extended->{$_}){
			$data->{$_} = $self->_extended->{$_};
		}
	}

	for (keys %{$self->_more}){
		if (defined $self->_more->{$_}){
			$data->{$_} = $self->_more->{$_};
		}
	}

	return $data; 
}




sub elements {
	my $self = shift;
	my @elements = sort keys %{$self->get_datahash};
	return \@elements;
}












# obscure way of getting pathrequest from cgi...
sub _get_rel_path_from_cgi {
	my $self = shift;

	my $req = $self->get_cgi->param($self->{param_name}) or return;

	my $wasfullurl = 0;
	if ($req=~s/^https\:\/\/|^http\:\/\///){
		$wasfullurl++;  
	}
	if ($req=~s/^www\.//){
		$wasfullurl++;
	}
	
	if (my $server = $self->get_cgi->server_name){
		$req=~s/^$server//;
	}
	
	if ($wasfullurl and !$req){
		return '/';	
	}
	
	$req or return;	
	return $req;	
}



	
1;

