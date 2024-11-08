package Data::JPack::Container;
#Modules for generating a html container storing user supplied data, bootstrapping
#and loading
#
#Sub classes can override the application and bootstrap sections

use strict;
use warnings;
use feature qw<say>;
use Data::JPack;
use File::Path qw<make_path>;
use File::Spec::Functions qw<rel2abs abs2rel>;

use File::Copy;
use Time::Piece;
use List::Util qw<uniq>;
use Data::Dumper;

use version; our $VERSION = version->declare('0.01');
use Exporter("import");



our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
use constant KEY_OFFSET=>0;

use enum ("options_=".KEY_OFFSET, qw<buffer_ indent_ app_js_files_ app_css_files_ html_root_ name_ copy_mode_ title_ date_ time_ config_ pre_bootstrap_sub_ post_bootstrap_sub_ body_sub_ jpack_inline_ jpack_manifest_>);

use constant KEY_COUNT=>jpack_manifest_-options_;

use enum (qw<COPY LINK WATERMARK JPACK>);

sub default_config {
	{
		input=>{
			dir=>"./src",		#where to look for applciation files

			output=>{
				name=>"index.html",	#name of html file to create
				dir=>"./dist",		#top level dir for outputs
			}
		}
	}
}

#dispatch table on how to convert files into html container
#Could be embedded url data  or  jpack, etc
my %mime_mode_map = (
	"png"=>COPY,
	"fpack"=>JPACK
);

sub new {
	my $pack=shift//__PACKAGE__;
	my %options=@_;
	my $self=[];
	$self->[config_]=$options{config}//default_config;

	$self->[html_root_]=$options{html_root}//"./out";
	$self->[name_]=$options{name}//"index.html";
	$self->[copy_mode_]=$options{copyMode}//LINK;
	$self->[title_]=$options{title}//"JPack Container";
	$self->[date_]=$options{date}// Time::Piece->new()->strftime("%Y-%m-%d");
	$self->[time_]=$options{time}//Time::Piece->new()->strftime("%T %z");
	$self->[jpack_manifest_]="manifest.json";

	#setup hooks for  sub classes/clients
	$self->[body_sub_]=$options{on_body}//sub {};
	$self->[pre_bootstrap_sub_]=$options{on_pre_bootstrap}//sub{};
	$self->[post_bootstrap_sub_]=$options{on_post_bootstrap}//sub{};
	bless $self, $pack;
}


sub _indent {
	$_[0][indent_].=" " x 4;

}

sub _outdent {
	say STDERR "Length before outdent: ", length $_[0][indent_];
	substr $_[0][indent_], -4, 4, "";
	say STDERR "Length AFTER outdent: ", length $_[0][indent_];
}

sub bootstrap {
	#create the output dirs and copy the minimum required script files
	#if debugging, multiple entries are added. 
	#otherwise, a combined  single file?
	
	#pako.js content wrapped in self loader?
	my $self=$_[0];
	say STDERR "Bootstrapping";
	
	#make_path my $dir=$self->[html_root_]."/client/components/jpack";
	#copy "data/pako.js0.js", $dir."/pako.js0.js";
	make_path $self->[html_root_]."/data";

        ###########################################################################################
        # my $jpack=Data::JPack::jpack_encode_file('data/pako.min.js',jpack_compression=>"NONE"); #
        # open my $ofh, ">", $self->[html_root_]."/data/pako.jpack.js";                           #
        # print $ofh $jpack;                                                                      #
        # close $ofh;                                                                             #
        ###########################################################################################
	#	copy "data/pako.js0.js", $_[0]->[html_root_]."/data/";
	my @scripts=qw<
		workerpool.js
		chunkloader.js
	>;

	$self->add_to_app(map "client/components/jpack/$_", @scripts);
}

#add files to the startup/header list.
sub add_to_app {
	my $self=shift;
	#TODO:
	#	Test the type of file (js, css font, etc) and add to approprate location
	for(@_){
		push $self->[app_js_files_]->@*, $_ and next if /js$/;
		push $self->[app_css_files_]->@*, $_ and next if  /css$/;
	}

}

#data is JPack format only
#ie it must be a javascript file
sub add_to_data {

}

#combines the js files into an inline script
sub make_app{
	my $self=shift;
	#say STDERR Dumper $self->[app_js_files_];
	#ensure all app files are unique
	$self->[app_js_files_]->@*=uniq $self->[app_js_files_]->@*;

	#read all the files into 
	$self->[buffer_].= $self->[indent_]."<script>\n";
	#$self->[app_js_files_]->@*=();
	for($self->[app_js_files_]->@*){
		say STDERR  "Adding  $_ to bootstrap script";
		if( !-d -r and -e ){
			$self->[buffer_].=do {local $/; open my $fh, "<",$_; <$fh>};
			$self->[buffer_].="\n";
		}
	}

	$self->[buffer_].= $self->[indent_]."</script>\n";#(@_);e_count_]=0;
	#read all the css 
	$self->[buffer_].= $self->[indent_]."<style>\n";
	#$self->[app_js_files_]->@*=();
	for($self->[app_css_files_]->@*){
		say STDERR  "Adding  $_ to bootstrap script";
		if( !-d -r and -e ){
			$self->[buffer_].=do {local $/; open my $fh, "<",$_; <$fh>};
			$self->[buffer_].="\n";
		}
	}
	$self->[buffer_].= $self->[indent_]."</style>\n";
}

#renders the data section of the file
#inline script containing the manifest of data to load
sub make_data {
  my $self=shift;
  $self->[buffer_].=qq|<script src="$self->[jpack_manifest_]"></script>
  |;

}
###################################################################################
# sub make_data {                                                                 #
#         my $self=shift;                                                         #
#         say STDERR "Making data with manifest:";                                #
#         say STDERR Dumper $self->[jpack_manifest_];                             #
#                                                                                 #
#         #make all paths relative to html_root                                   #
#         my @rel=                                                                #
#                 map {                                                           #
#                         my $p=$_;                                               #
#                         [map {                                                  #
#                                 abs2rel($_, $self->[html_root_])                #
#                         }                                                       #
#                         @$p                                                     #
#                         ]                                                       #
#                 }                                                               #
#                 $self->[jpack_manifest_]->@*;                                   #
#                                                                                 #
#         say STDERR Dumper \@rel;                                                #
#                                                                                 #
#         my $text="";                                                            #
#                                                                                 #
#         $text.=<<~EOF;                                                          #
#         <script>                                                                #
#         (function(chunkLoader){                                                 #
#                 chunkLoader.addToManifest([                                     #
#         EOF                                                                     #
#         #TODO: make each manifest entry an array                                #
#         $text.=join ", ", map "[".join(", ", map qq|"$_"|, $_->@*, )."]", @rel; #
#                                                                                 #
#         $text.=<<~EOF;                                                          #
#                                                                                 #
#                 ]);                                                             #
#         })(chunkLoader);                                                        #
#         </script>                                                               #
#         EOF                                                                     #
#         $self->[buffer_].=$text;                                                #
# }                                                                               #
###################################################################################

#take a js file and adding to the application

#Add file or data and convert it to jpack
#File are added to a manifest
#If file was split into multiple, a new group?
#Data is stored external to the html container
sub jpack_external {
	
	
}

#store data as jpack, but inline with  a script tag.
sub jpack_internal {

}

#Build resource cmd


sub copy_ {
	#copy file from src to destination
	#Returns the URL to the destination
}
sub link {
	#link file in src to destination
	##returns the URL to the destination
}
sub watermark {
	#watermark image or video and write new version into destination
	##returns the URL to the Destination
}
sub dataurl{
	#convert into a data url
	#returns a data url
}

sub template{
	#renders a html template tag
	#template is hidden. so use as data
	#options to include style?, id for referencing
	#returns the template string
}


#data is added after app and before any other data
sub add_inline_jpack {
	my $self=shift;
	my $data=shift;
	#encode as embedded, inline jpack and write to data section
	push $self->[jpack_inline_]->@*, jpack_encode $data;
}


sub _doctype {
	$_[0][buffer_].="<!doctype html>\n";
	return;
}
sub pre_bootstrap {
	say STDERR "Adding pako.js";
	#add pako js here
	my $self=$_[0];
	#TODO: need to set local path relative to this file
	#
	$self->[buffer_].=$self->[indent_]."<script id=\"pako\">\n";
	$self->[buffer_].=do {local $/; open my $fh, "<","client/components/jpack/pako.min.js"; <$fh>};
	$self->[buffer_].=$self->[indent_]."</script>\n";
	$self->[buffer_].="\n";

}

sub post_bootstrap {

}

sub _head {
	$_[0][buffer_].=$_[0][indent_]."<head>\n";
	$_[0]->_indent;
	$_[0]->pre_bootstrap;
	$_[0]->make_app;
	$_[0]->make_data;
	$_[0]->post_bootstrap;
	$_[0]->_outdent;
	$_[0][buffer_].=$_[0][indent_]."</head>\n";
}

sub body {

}
sub _body {
	$_[0][buffer_].=$_[0][indent_]."<body>\n";
	$_[0]->body;
	$_[0][buffer_].=$_[0][indent_]."</body>\n";
	return;
}

#ctx, buffer, offset
sub _html {

	$_[0]->_doctype;
	$_[0][buffer_].=$_[0][indent_]."<html>\n";
	$_[0]->_indent;
	$_[0]->_head;
	$_[0]->_body;
	$_[0]->_outdent;
	$_[0][buffer_].=$_[0][indent_]."</html>\n";
}

sub build {
	my $self=shift;
	mkdir $self->[html_root_] unless -e $self->[html_root_];
	$self->[buffer_]="";
	$self->[indent_]="";
	$self->bootstrap;
	$self->_html;

	open my $out , ">", $self->[html_root_]."/".$self->[name_];
	print $out $self->[buffer_];
	$self->[buffer_];
}


1;
