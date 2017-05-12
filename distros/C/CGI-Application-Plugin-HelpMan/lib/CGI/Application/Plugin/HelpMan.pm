package CGI::Application::Plugin::HelpMan;
use strict;
use warnings;
#use base 'CGI::Application';
use LEOCHARRE::DEBUG;
use Carp;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw/ Exporter /;
@EXPORT_OK = (qw(
__abs_path_doc_to_html
__find_abs
__string_looks_like_command
__term_to_command
__term_to_namespace
_doc_html
_term_abs_path
hm_abs_tmp
hm_doc_body
hm_doc_title
hm_found_term_abs
hm_found_term_doc
hm_found_term_query
hm_set_term
hm_term_get
hm_help_title
hm_help_body
_hm_reset_data
_set_term_as_caller

));
%EXPORT_TAGS = (
   ALL => \@EXPORT_OK,
   basic => \@EXPORT_OK,
   all => \@EXPORT_OK,
);
$VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)/g;

# 1) is there something to look for?
sub hm_found_term_query {
   my $self = shift;
   $self->hm_term_get or return 0;
   return 1;
}

# 2) can we resolve it to disk?
sub hm_found_term_abs {
   my $self = shift;
   $self->_term_abs_path or return 0;
   return 1;
}

sub _term_abs_path {
   my $self = shift;
   $self->{_hm_data_}->{_term_abs_path} ||= __find_abs($self->hm_term_get) or return;   
   return $self->{_hm_data_}->{_term_abs_path}
}

# 3) does it have doc?
sub hm_found_term_doc {
   my $self = shift;
   $self->_doc_html or return 0;
   return 1;
}

# body text for template
sub hm_doc_body {
   my $self = shift;
   my $html = $self->_doc_html or return 0;
   if( $html=~m/<body[^<>]*>(.+)<\/body>/si ){
      my $body = $1;
   
      # sometimes Pod::Html will output even when there's no doc.
      my $length = length($html);      
      debug("length $length\n");
      # if less then 500, report nothing.
      $length > 500 or return 0;      
      return $body;
   }
   return 0;
}

# title text for template
sub hm_doc_title {
   my $self = shift;
   my $title;
   
   my $html = $self->_doc_html or return 0;

   
   if( $html=~m/<title[^<>]*>(.+)<\/title>/si ){
      $title = $1;
      debug("[$title]via html\n");
      return $title;
      
   }
   elsif( $self->hm_term_get ){
      my $namespace = __term_to_namespace($self->hm_term_get);
      debug("[$namespace] via term to namespace\n");      
      return $namespace;
   }
   
   return 0;   
}

sub hm_abs_tmp {
   my $self = shift;
   my $d = $self->param('abs_tmp');
   $d ||= '/tmp';
   return $d;
}

# force set the term 
sub hm_set_term {
   my $self = shift;
   my $term = shift;
   defined $term or confess('missing arg');
   $self->{_hm_data_}->{_man_searchterm} = $term;
   return 1;
}

# term from query string, then from namespace of caller, your cgi app
sub hm_term_get {
   my $self = shift;
   
   unless( $self->{_hm_data_}->{_man_searchterm} ){
   
      # first try from query
      my $term = $self->query->param('query');
      
      # then from caller
      $term ||= caller; # was using caller(1), wrong.
      $self->{_hm_data_}->{_man_searchterm} = $term;
      debug(" term is [$term]\n");
   }
   return $self->{_hm_data_}->{_man_searchterm};
}






# # private methods....

sub _doc_html {
   my $self = shift;
   unless(defined $self->{_hm_data_}->{_abs_path_htmlcode}){

      unless( $self->_term_abs_path ){
         warn("no abs path for term");
         $self->{_hm_data_}->{_abs_path_htmlcode} = 0;
         return 0;
      }
      my $help_runmode_name = $self->get_current_runmode;
      $help_runmode_name ||=undef;
      $self->{_hm_data_}->{_abs_path_htmlcode} = 
         __abs_path_doc_to_html(
            $self->_term_abs_path, $self->hm_abs_tmp, $help_runmode_name );
         
      $self->{_hm_data_}->{_abs_path_htmlcode} ||=0;   
   }

   return $self->{_hm_data_}->{_abs_path_htmlcode};
}


# GET TITLE AND BODY FOR THE CALLER, NOT A QUERY

sub hm_help_body {
   my $self = shift;
   $self->_set_term_as_caller;
   return $self->hm_doc_body;   
}

sub hm_help_title {
   my $self = shift;
   $self->_set_term_as_caller;  
   
   return $self->hm_doc_title;
}

sub _set_term_as_caller {
   my $self = shift;
   
   my $caller = caller(1); 
   $caller or confess('caller should return');
   
   unless( $self->hm_term_get eq $caller ){
      $self->_hm_reset_data;
      $self->hm_set_term($caller);
   }
   
   return 1;  
}


sub _hm_reset_data {
   my $self = shift;
   $self->{_hm_data_} =undef;
   return 1;
}


#######################################################################

# THE FOLLOWING SUBS ARE NOT OO

##############################
# get html

sub __abs_path_doc_to_html {
   my ($abs,$tmp,$runmode) = @_; defined $abs and defined $tmp or confess('missing args');
   debug("$abs\n");     

   $runmode ||= 'help_view';
   debug("runomde = $runmode");
   # can we write to this place, the tmp place? # TODO $self->hm_abs_tmp ?
   chdir $tmp or confess("$!, cant chdir to $tmp"); # if you dont... breaks. because perl2html ne4eds to write a tmp file
      
   require Pod::Html;
   require File::Slurp;

   my $out = $tmp.'/helpman_temp_'. (int rand(600000));  
   debug("$out\n");
   
	Pod::Html::pod2html($abs,      
      "--outfile=$out",
     # "--verbose",
    # '--css=http://search.cpan.org/s/style.css'
      "--htmlroot=?rm=$runmode".'&query=', # WORKS for LINKING
      ); 
   #TODO needs work up there.
   
   my $html = File::Slurp::slurp($out) or warn("could not slurp $out");

  # debug("\n\n$html\n\n"); NO
   
   return $html;  
}


#####################################
# find on disk

sub __find_abs {
   my $term = shift; $term or confess('missing arg');
   
   my $as_command = __term_to_command($term);   
   my $as_namespace = __term_to_namespace($term);   

   my $abs;

   require Pod::Simple::Search;
   my $pss = Pod::Simple::Search->new;   
   if( $abs = $pss->find($as_namespace) ){
      debug("via namespace: [$as_namespace] -> $abs\n");
      return $abs;   
   }
   elsif ( defined $as_command ){
      require File::Which;
      $abs = File::Which::which($as_command) or return;     
      debug("via command: [$as_command] -> $abs\n");
      
      require Cwd;      
      Cwd::abs_path( $abs ) or warn("cant resolve $abs") and return;      
      return $abs;      
   }
   return;
}

sub __term_to_command {
   my $term = shift; defined $term or return;
   $term=~s/^\s+|\s$//g;
   __string_looks_like_command($term) or return;
   return $term;
}

sub __string_looks_like_command {
   my $string = shift; $string or return;
   $string=~/^[a-z]+[\w\-]+[a-zA-Z]+$/ or return 0;
   return 1;
}

#turn some silly string into a namespace
sub __term_to_namespace {
   my $term = shift ; defined $term or confess('no term arg');
   debug($term);
	$term=~s/^\W|\W$//g;
		
	$term=~s/\/+/::/g;

	$term=~s/\.html?$|\.pm$|\.pl$//g;
   debug(": $term\n");
   return $term;
}



1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::HelpMan - man lookup and help doc for your cgi app

=head1 DESCRIPTION

I believe that your cgi application should not be an API, it should be a web interface to an API.
Just like a script should be a command line interface to an API.
Thus documentation in your cgi app should be for the user, not a programmer.

If you are of the sentiment your pod documentation in your cgi app should be the docs used for the end
user, then this module is for you.


=head1 TEMPORARY DIRECTORY

Pod::Html needs a temp dir that it can read/write to for tmp files.
By default it is /tmp
If you want otherwise:

   my $app = new CGIAPPusingthis(
      PARAMS => { abs_tmp => '/tmp' }
   );

=head1 METHODS

None are exported by default, you can import all with the export tag ':all'.
You can do 

   use CGI::Application::Plugin::HelpMan ':all';

=head2 hm_abs_tmp()

Pod::Html needs a temp dir to write to. See L<TEMPORARY DIRECTORY>

=head2 hm_doc_body()

returns body of the html that Pod::Html spat out.

=head2 hm_doc_title()

returns title of the html that Pod::Html spat out.
could be undef

=head2 hm_found_term_abs()

returns boolean

=head2 hm_found_term_doc()

=head2 hm_found_term_query()

=head2 hm_set_term()

force term

=head2 hm_term_get()

returns term string


=head1 PRIVATE METHODS

None are exported by default, you can import all public and private methods
with the export tag ':all'.

=head2 _doc_html()

returns what Pod::Html spat out.

=head2 _term_abs_path()

returns the absolute path the search resolved to for the code (pod) file



=head1 SUBROUTINES

The following subs are not OO. They can be imported into your code explicitly
or with the tag ':ALL'.

=head2 __abs_path_doc_to_html()

argument is abs path to file
tries to get html doc with Pod::Html

=head2 __find_abs()

argument is a string
tries to resolve to disk via File::Which and Pod::Simple::Search

=head2 __string_looks_like_command()

argument is string, returns boolean - if it looks like a unix command

=head2 __term_to_command()

argument is string, tries to see if it looks like a unix command, returns command string
or undef

=head2 __term_to_namespace()

argument is string
tries to clean up into a perl namespace


=head1 CREATING A HELP RUNMODE

Imagine you have your cgi app.. "My::App1".

Inside App1.pm, make sure your pod doccumentation is present.

Then your app needs a help runmode..

   sub rm_help {
      my $self = shift;
   
      my $return = sprintf "<h1>%s</h1> %s", $self->hm_help_title, $self->hm_help_body;   
      return $return;      
   }  

That's it.

For a more interesting example, complete with lookup, etc.. see L<CGI::Application::HelpMan>.


If that fails try

      sub rm_help {
      my $self = shift;
      $self->hm_set_term('Your::Package');
   
      my $return = sprintf "<h1>%s</h1> %s", $self->hm_help_title, $self->hm_help_body;   
      return $return;      
   }  


=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO

L<CGI::Application>
L<LEOCHARRE::DEBUG>

=cut
