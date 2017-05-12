package CGI::Scriptpaths;
use strict;
use Carp;
use warnings;
use Exporter;

use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;
@ISA = qw/ Exporter /;
@EXPORT_OK = qw(
abs_cgibin
script_abs_loc
script_abs_path
script_ext
script_filename
script_filename_only
script_rel_loc
script_rel_path
script_is_in_cgibin
script_is_in_DOCUMENT_ROOT
DOCUMENT_ROOT
);
%EXPORT_TAGS = (
   all => \@EXPORT_OK,
);

$CGI::Scriptpaths::DEBUG =0;

sub DEBUG : lvalue { $CGI::Scriptpaths::DEBUG }
sub debug { 
   DEBUG() or return 1; 
   print STDERR __PACKAGE__." @_\n"; 
   return 1; 
}


sub script_abs_loc {
   return _script_abs_loc();
}
sub script_abs_path {
   return _script_abs_path();
}

sub script_rel_path {

   if ( my $docroot = DOCUMENT_ROOT() and my $abs = script_abs_path() ){
      if ( $abs=~s/^$docroot// ){
         return $abs;
      }
      debug('cant get rel path with docroot and abs path set');    
   }

   my $rel = _script_rel_path_last_resort();
   $rel=~s/^\/+//;  
   return "/$rel";
}

sub _script_rel_path_last_resort {
  # my @caller = caller(1);
   #@caller
  # debug("caller @caller \n");
   my $rel = $ENV{SCRIPT_NAME};
   $rel ||= $0;
   defined $rel or return;
        
   if ($rel=~/^\// ){
      # then we cant determine it, because it's absolute      
      debug("path starts with slash [$rel], must be absolute, we cannot determine rel path");
   }
   return "/$rel";
}

sub script_rel_loc {
   my $docroot = DOCUMENT_ROOT() or return;
   my $abs = script_abs_loc() or return;
   $abs=~s/^$docroot// or return;
   return $abs;  
}

sub script_filename {
   my $abs = script_abs_path() or return;
   $abs=~s/^.+\/+//;
   return $abs;   
}

sub script_filename_only {
   my($filename,$ext) = _script_filename() or return;
   return $filename;
}

sub script_ext {
   my($filename,$ext) = _script_filename() or return;   
   defined $ext and defined $filename or return;
   return $ext;
}

sub DOCUMENT_ROOT {
   return _get_docroot();
}

sub abs_cgibin{
   return _get_cgibin();
}

sub script_is_in_cgibin {
   my $abs_script = script_abs_path() or return;
   my $parent     = abs_cgibin() or return;

   require Cwd::Ext;   
   Cwd::Ext::abs_path_is_in($abs_script,$parent) or return 0;
   return 1;   
}

sub script_is_in_DOCUMENT_ROOT {
   my $abs_script = script_abs_path() or return;
   my $parent     = DOCUMENT_ROOT() or return;

   require Cwd::Ext;   
   Cwd::Ext::abs_path_is_in($abs_script,$parent) or return 0;
   return 1; 
}



# priv

sub _script_filename {
   my $filename = script_filename() or return;

   my ($name,$ext);
   
   if( $filename=~/^([^\/]+)\.(\w+)$/){
      ($name,$ext) = ($1,$2);      
   }
   
   else {
      $name = $filename;
      $ext = undef;
   }
   return ($name,$ext);
}

sub _get_docroot {   

   defined $ENV{DOCUMENT_ROOT} and return $ENV{DOCUMENT_ROOT};   

   my $abs_dir = _script_abs_loc();   
   _dir_looks_like_docroot($abs_dir) and return $abs_dir;
   
   
   my @try = ( $abs_dir );
   while ( $abs_dir=~s/\/[^\/]+$// ){
      push @try, $abs_dir;      
   }

   for my $abs_dir (@try){
      my $docroot = _get_docroot_inside($abs_dir) or next;
      return $docroot;
   }
   warn("cannot figure out DOCUMENT_ROOT, ENV is not set");
   return;  
}

sub _get_cgibin {   

   my $abs_dir = _script_abs_loc();   
   _dir_looks_like_cgibin($abs_dir) and return $abs_dir;
   
   
   my @try = ( $abs_dir );
   while ( $abs_dir=~s/\/[^\/]+$// ){
      push @try, $abs_dir;      
   }

   for my $abs_dir (@try){
      my $docroot = _get_cgibin_inside($abs_dir) or next;
      return $docroot;
   }
   warn("cannot figure out abs cgi-bin");
   return;  
}


sub _dir_looks_like_docroot {
   my $abs = shift;
   $abs=~/\/public_html$|\/htdocs{0,1}$|\/html$/ or return 0;
   return 1;
}
sub _dir_looks_like_cgibin {
   my $abs = shift;
   $abs=~/\/cgi\-bin$|\/cgi$/ or return 0;
   return 1;
}

sub _get_docroot_inside {
   my $abs_dir = shift;
   debug("$abs_dir\n");

   for(qw(public_html htdocs html)){
      my $try ="$abs_dir/$_";
      -d $try and return $try;     
   }
   return;
}

sub _get_cgibin_inside {
   my $abs_dir = shift;
   debug("$abs_dir\n");

   for(qw(cgi-bin cgi)){
      my $try ="$abs_dir/$_";
      -d $try and return $try;     
   }
   return;
}



sub _script_abs_path {
   my $abs = $0;

   unless( defined $abs ){
      defined $ENV{SCRIPT_NAME} or confess("cant get abs loc of script");
      $abs = $ENV{SCRIPT_NAME};
   }
   
   unless( $abs=~/^\//){
      require Cwd;
      $abs = Cwd::cwd().'/'.$abs;
   }
   return $abs;
}


sub _script_abs_loc {
   my $abs = _script_abs_path();
   $abs=~s/\/+[^\/]+$//;
   return $abs;
}



1;

__END__

=pod

=head1 NAME

CGI::Scriptpaths - find web relevant paths even without ENV set

=head1 SYNOPSIS

   use CGI::Scriptpaths ':all';

   $CGI::Scriptpaths::DEBUG = 1;

   my $abs_path            = script_abs_path();
   my $abs_loc             = script_abs_loc();
   my $filename            = script_filename();
   my $filename_only       = script_filename_only();
   my $script_extension    = script_ext();
   my $form_action         = script_rel_path();
   my $script_dir          = script_rel_loc();
   my $docroot             = DOCUMENT_ROOT();
   my $cgibin              = abs_cgibin(;)
   

=head1 DESCRIPTION

Sometimes you need to find where the document root is, and maybe DOCUMENT ROOT is not set
Sometimes you want to get some info about the script, like it's abs path, it's rel path
so a form knows how to point to itself.

This uses some tricks to find those things even if environment variables are not set.

=head2 WHY

Even outside a cgi environment, a script usinng this can find its way around.
For example in this fs hierarchy:

   /home/user/
   /home/user/public_html
   /home/user/cgi-bin
   /home/user/cgi-bin/a/script.cgi

Even without DOCUMENT_ROOT set, script.cgi knows that document root is /home/user/public_html.
Valid dir names are also htdocs and html.
So, in this following fs hierarchy, it will also know to find document root:

   /home/user/
   /home/user/html
   /home/user/html/script.cgi   
   /home/user/cgi-bin

The way it works, is it steps backwards and looks for these directories.



=head1 SUBS

None of these are exported by default.

=head2 script_abs_path()

returns script's absolute location
on failure warns and returns undef

=head2 script_abs_loc()

returns script's abs path to the directory it resides in
on failure warns and returns undef

=head2 script_filename()

returns the script's filename

=head2 script_filename_only()

returns the script's filename without ext (if there was one)

=head2 script_ext()

returns script's ext (without dot) if there is one
returns undef if none

=head2 abs_cgibin()

tries to find path to cgi-bin
may warn and return undef

=head2 DOCUMENT_ROOT()

assumes this is a website and returns document root
if $ENV{DOCUMENT_ROOT} is not set, it tries to test and guess for it
on failure returns undef

=head2 script_rel_path()

returns script's relative path to DOCUMENT_ROOT()
warns and returns undef on failure

=head2 script_rel_loc()

returns the path of the directory the script resides in, relative to DOCUMENT_ROOT()
warns and returns undef on failure

=head2 script_is_in_DOCUMENT_ROOT()

returns boolean
returns undef if DOCUMENT_ROOT() can't return value.

=head2 script_is_in_cgibin()

returns boolean
returns undef if abs_cgibin() can't return value.

=head1 DEBUG

   $CGI::Scriptpaths::DEBUG  = 1;

=head1 BUGS

Please contact AUTHOR.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO 

Cwd::Ext
Cwd

=cut


