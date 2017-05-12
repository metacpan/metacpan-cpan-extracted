package CGI::UploadEngine;
use Class::Std;
use Class::Std::Utils;
use DBIx::MySperql qw(DBConnect SQLExec $dbh);
use YAML::Any qw(LoadFile);

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.9.3');

our $token_length = 60;
our @token_chars  = ('a'..'z','A'..'Z','0'..'9','_');
our $config_file  = '/var/www/.uploadengine';

{
        my %db_of      :ATTR( :get<db>       :set<db>       :default<''>          :init_arg<db> );
        my %host_of    :ATTR( :get<host>     :set<host>     :default<'localhost'> :init_arg<host> );
        my %user_of    :ATTR( :get<user>     :set<user>     :default<''>          :init_arg<user> );
        my %pass_of    :ATTR( :get<pass>     :set<pass>     :default<''>          :init_arg<pass> );
        my %config_of  :ATTR( :get<config>   :set<config>   :default<''>          :init_arg<config> );
        my %verbose_of :ATTR( :get<verbose>  :set<verbose>  :default<'0'>        );

        sub verbose { my ( $self ) = @_; return $self->get_verbose(); }

        sub START {
                my ($self, $ident, $arg_ref) = @_;

		# Loads the YAML configuration file
		warn "CONFIG: $config_file";
		my $config = LoadFile($config_file);

		# Set verbose
		if ( $config->{verbose} ) { $self->set_verbose( 1 ); }

		# Report config if verbose
		if ( $self->verbose() ) { foreach my $key ( keys %$config ) { warn "CONFIG: $key -> " . $config->{$key}; } }

		# Store the file descriptor in member variable
		$self->set_config($config);
		
		# Check to see if database info was passed
		if ( $self->get_db() ne '' and $self->get_user() ne '' and $self->get_pass() ne '') {
			$dbh = DBConnect( database => $self->get_db(), 
					  host     => $self->get_host(), 
					  user     => $self->get_user(), 
					  pass     => $self->get_pass() );
		# If not then use the database info from the config file
		} else {
			$dbh = DBConnect( database => $self->get_config()->{database},
					  host     => $self->get_config()->{host}, 
					  user     => $self->get_config()->{user}, 
					  pass     => $self->get_config()->{pass} );
	
			# Set configured connection parameters
			$self->set_db( $config->{database} );
			$self->set_host( $config->{host} );
			$self->set_user( $config->{user} );
			$self->set_pass( $config->{pass} );
		}

                return;
        }

        sub upload_prepare {
                my ( $self, $arg_ref ) = @_;

		my $file_path        = defined $arg_ref->{file_path} ? $arg_ref->{file_path} : '/tmp';
		my $max_size         = defined $arg_ref->{max_size} ? $arg_ref->{max_size} : 5000000;
		my $min_size         = defined $arg_ref->{min_size} ? $arg_ref->{min_size} : 1;
		my $allowed_types    = defined $arg_ref->{allowed_types} ? $arg_ref->{allowed_types} : '';
		my $disallowed_types = defined $arg_ref->{disallowed_types} ? $arg_ref->{disallowed_types} : '';

		# Save the file_path and token
		my $token = $self->_generate_token();
		my $sql   = "insert into upload_files ( ";
		   $sql  .= 'file_path, attempt_token, max_size, min_size, allowed_types, disallowed_types, created ';
		   $sql  .= ') values ("';
		   $sql  .= $file_path . '", "';
		   $sql  .= $token . '", ';
		   $sql  .= $max_size . ', ';
		   $sql  .= $min_size . ', "';
                   $sql  .= $allowed_types . '", "';
		   $sql  .= $disallowed_types . '", now() )';
		SQLExec( $sql ) or die("failed to write file parameters to database");
        
                return $self->_generate_html({ token => $token });
        }

        sub upload_validate {
                my ( $self, $arg_ref ) = @_;
		my $token  = defined $arg_ref->{token} ? $arg_ref->{token} : '';

		# Save the file_path and token and the parameters given in upload_prepare back to controller
		my $sql  = "select file_path,";
		   $sql .= "max_size,";
		   $sql .= "min_size, ";
		   $sql .= "allowed_types,";
		   $sql .= "disallowed_types,";
		   $sql .= "created from upload_files ";
		   $sql .= "where attempt_token = '$token'";
		my ( $file_path, $max_size, $min_size, $allowed_types, $disallowed_types, $created) = SQLExec( $sql, '@' ) or die("ERROR: failed to exec sql statement");

		# Check to make sure variables from database are valid
       		( length( $file_path ) > 0 ) or die( "ERROR: file_path is blank" );
       		( length( $max_size ) > 0 )  or die( "ERROR: max_size is blank" );
       		( length( $min_size ) > 0 )  or die( "ERROR: min_size is blank" );
       		( length( $created ) != 0 )  or die( "ERROR: created is blank" );
                return { file_path        => $file_path, 
			 max_size         => $max_size, 
			 min_size         => $min_size,
			 allowed_types    => $allowed_types, 
			 disallowed_types => $disallowed_types, 
			 created          => $created };
        }

        sub upload_success {
                my ( $self, $arg_ref ) = @_;

		my $attempt_token = defined $arg_ref->{token} ? $arg_ref->{token} : '';
		my $file_name     = defined $arg_ref->{file_name} ? $arg_ref->{file_name} : '';
		my $file_size     = defined $arg_ref->{file_size} ? $arg_ref->{file_size} : '';

		# Check to make sure there isn't already a success token for htis attempt token
		my $sql = "select success_token from upload_files where attempt_token='$attempt_token'";
		my ( $success_token ) = SQLExec( $sql,'@' ); # and die("could not execute sql command: $sql");
		if ( $success_token ) { die( "ERROR: success_token already exists for attempt_token: $attempt_token" ); }

		# Create success token
		$success_token = $self->_generate_token();

		# Save the file_path and token and file size
		$sql = "update upload_files set success_token = '$success_token', file_name = '$file_name', file_size='$file_size' where attempt_token = '$attempt_token'";
		SQLExec( $sql ) or die( "could not execute sql command: $sql" );
        
                return $success_token;
        }
	
        sub upload_retrieve {
                my ( $self, $arg_ref ) = @_;
		my $token  = defined $arg_ref->{token} ? $arg_ref->{token} : '';

		# Save the file_path and token
		my $sql = "select file_path, file_name, file_size, max_size, min_size, allowed_types, disallowed_types, created from upload_files where success_token = '$token'";
		my ( $file_path, $file_name, $file_size, $max_size, $min_size, $allowed_types, $disallowed_types, $created ) = SQLExec( $sql, '@' ) or die("could not execute sql command: $sql");
        
                return { file_path => $file_path, file_name => $file_name, file_size=> $file_size, max_size=>$max_size, min_size=>$min_size, allowed_types=>$allowed_types, disallowed_types=>$disallowed_types, created => $created };
        }

	sub _generate_token {
		my ( $self, $arg_ref ) = @_;
		my $token;

		# Random string created from global package variables
		foreach (1..$token_length) { $token .= $token_chars[rand @token_chars]; }

		return $token;
	}

	sub _generate_html {
		my ( $self, $arg_ref ) = @_;
		my $token              = defined $arg_ref->{token} ? $arg_ref->{token} : '';
		my $root_url           = $self->get_config()->{root_url};
		my $action             = $root_url . 'upload';
		my $success_message    = $self->get_config()->{success_message};
		my $error_image        = $self->get_config()->{error_image};

		my $html = <<END_OF_HTML;

<script type="text/javascript">
Ext.onReady(function() {
var file_upload_box =  Ext.get('auto_file');
var auto_file_form  =  document.forms[0];
var action          = document.forms[0].action;
var encoding        = document.forms[0].encoding;
var file_id;

document.forms[0].action   = '$action';
document.forms[0].encoding = 'multipart/form-data';

   file_upload_box.addListener('change', function(el) {

        Ext.Ajax.request({
                form: auto_file_form,
                success: function(response, opts) {
                                if(!response.responseText.match(/ERROR: /)){ 
					file_id = Ext.util.JSON.decode(response.responseText).success;
					Ext.fly(file_upload_box).remove();
					Ext.fly(file_control).insertHtml('afterBegin', '$success_message');
                                
					var token   =  document.getElementById('token');
					token.value = file_id;
					document.forms[0].action   = action;
					document.forms[0].encoding = encoding;
				}else{
					//we have an error.
					Ext.fly(file_upload_box).remove();
					//if possible decode the JSON
					try{
						file_id = Ext.util.JSON.decode(response.responseText).success;
						Ext.fly(file_control).insertHtml('afterBegin', '$error_image'+file_id);
					}catch(e){
						//JSON decode failed so use responseText
						Ext.fly(file_control).insertHtml('afterBegin', '$error_image'+response.responseText);
					}
				}
                        },
                failure: function(response, opts) {
                                alert('server-side failure with status code ' + response.status);
                        }
         });

   });
});
</script>
<div name='file_control' id='file_control'> 
<input type='file' size='50' name='auto_file' id='auto_file'>
<input type='hidden' name='token' id='token' value='$token'>
</div>

END_OF_HTML
		return $html;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

CGI::UploadEngine - File Upload Engine for Multi-App Web Server


=head1 VERSION

This document describes CGI::UploadEngine version 0.9.3


=head1 DESCRIPTION

The main design goal of CGI::UploadEngine (CGI::UE) has been to enable developers 
to use file upload select boxes in a regular HTML I<form> without 
needing to handle I<multi-part> forms (or making any number of rookie mistakes). This 
is accomplished by I<injecting> the necessary code into the developers template to 
submit the form twice; once to upload the file, and a second time to submit the rest 
of the data along with an acknowledgement I<token>. This means that the 
"B<Upload Engine>" (UE) handles all of the html and javascript necessary to upload, 
validate (and optionally limit) file type, size, and destination directory. 

The UE includes the four main methods of CGI::UE and a I<mysql> table. The 
two middle methods are meant to be implemented in a "B<Core>" controller/script that 
handles the actual file upload.  B<This package currently only includes working code 
for a Catalyst supported Core.> If you do not have Catalyst, please get it, wait for 
an update, or send us your working CGI Core to include in the next update. 

CGI::UE can be installed with I<make>, but the UE Core should be installed by a 
I<server administrator> (currently with Catalyst) for the benefit of I<developers> 
on their server (either developing with Catalyst or "doing it old school"). The 
developers will use both the first and last CGI::UE methods and the installed UE Core 
to painlessly create forms that can handle both file and field data, even in 
"old school" CGI scripts.


=head1 SYNOPSIS

Normally, file select boxes have to be in a form with a special I<multi-part> 
attribute which can significantly complicate handling other values in the same form. 
By handling the file upload with AJAX, we can replace the file select 
box with a simple (hidden) text field (with our "B<success token>" pre-filled) that 
reduces file uploading to just another dynamic field to be filled in a template. 


    <form action="[% action_url %]" method="POST">
    <table cellspacing="2" cellpadding="0" width="600">
          <tr>
               <td> Select file </td>
               <td> [% file_upload %] </td>
          </tr>
          <tr>
               <td> Your fields here </td>
               <td> <input type="text" name="other" id="other" value=""> </td>
          </tr>
          <tr>
               <td> &nbsp; </td>
               <td> <input type="submit"> </td>
          </tr>
    </table>
    </form>


With the template in hand, we only need to inject the UE "B<Package>". The 
Package contains all of the HTML and most of the JavaScript necessary to upload 
the file to your specified directory. (Additional JavaScript is used from the 
Ext library.)

However, additional work is required to make a controller/script. Below is text 
of I<form_eg.cgi>, which is included in the CGI::UE package.  Notice it uses Template 
Toolkit (TT). It also requires a script level configuration file, template file, and 
library file. 

    use CGI::UploadEngine;
    use Template;
    require "upload_cfg.pl";
    require "upload_html.pl";
    
    # Create an upload object
    my $upload = CGI::UploadEngine->new();

    # Set the view template
    my $tmpl = "upload/form_eg.tt2";
    
    # Set the template variables
    my $vars = { action_url  => $root_url . "cgi-bin/handler_eg.cgi",
                 file_upload => $upload->upload_prepare({ file_path => "/tmp" }) };
    
    # Process the template
    my $result;
    my $template = Template->new({ INCLUDE_PATH => $tmpl_incl });
       $template->process( $tmpl, $vars, \$result );
    
    # Print the page
    header();
    print $result;
    footer();
  
In the above script, the functions I<header()> and I<footer()> are from the 
library file I<upload_html.pl> (as is I<parse_form_data()> in the script 
below). (Try reading the short configuration file.) 

Note: Page layout could be handled through TT. You could grab the CGI form data 
another way. Database passwords should be in file X. Bleep blurp bleep. In short, 
these CGI scripts are working samples of developer software, not final software.

Once the I<end user> selects a file, it is submitted via AJAX. On I<success>, the 
form is altered. The file upload box is removed and replaced with a regular text box 
containing the returned success token. As a developer, you will need to 
I<retrieve> the file info using the token to discover the file-path-name and 
other pertinant facts.

Below is text of I<handler_eg.cgi>, which is also included in the package. 

    use CGI::UploadEngine;
    use Template;
    require "upload_cfg.pl";
    require "upload_html.pl";
    
    # Handle CGI variables
    parse_form_data();
    
    my $token  = $FORM_DATA{token};
    my $other  = $FORM_DATA{other};
    
    # Create an upload object
    my $upload = CGI::UploadEngine->new();

    # Retrieve file hash_ref
    my $file   = $upload->upload_retrieve({ token => $token });
    
    # Set the view template
    my $tmpl = "upload/handler_eg.tt2";
    
    # Set the template variables
    my $vars = { path_name   => $file->{file_path} . "/" . $file->{file_name},
                 other       => $other };
    
    # Process the template
    my $result;
    my $template = Template->new({ INCLUDE_PATH => $tmpl_incl });
       $template->process( $tmpl, $vars, \$result );
    
    # Print the page
    header();
    print $result;
    footer();

The sample script prints the values on a page. That is probably not what you will 
do with it. Notice however that "other" form values are passed along with the 
token, which is used to retrieve file information in a perl I<hash reference>.


=head1 INTERFACE 

CGI::UE has four public methods (besides I<new()>). The first and last are 
"B<developer methods>", and are used by the person who wants to create a form 
mixing a file select box with other more common elements like text input, 
I<textarea>s, radio buttons, or a normal select box. The middle methods are 
"B<Core methods>", and are accessed via a running URL pre-installed by the 
I<server administrator>.

=head2 Developer Methods

Besides mastering these calls, developers must include the JavaScript library 
reference in the page header. CGI::UE uses the Ext library for cross-browser 
support.

=over 4

=item * new()

Create a new CGI::UE object.

    # Create an upload object
    my $upload = CGI::UploadEngine->new();

The returned object is used to access the next four methods.


=item * upload_prepare()

The destination directory and file limits are passed to the engine using 
I<upload_prepare()>, which returns a text string containing two HTML form 
elements and javascript. 

    my $injection = $upload->upload_prepare({ file_path => '/tmp' }) };

If you have a template with your caption and a cell for the file upload box:

          <tr>
               <td> Select file </td>
               <td> [% file_upload %] </td>
          </tr>

You would fill it by assigning the results of I<upload_prepare()> to the 
I<file_upload> key:

    # Set the template variables
    my $vars = { action_url  => $root_url . "cgi-bin/handler_eg.cgi",
                 file_upload => $upload->upload_prepare({ file_path => "/tmp" }) };
    
Example results of a generated Package are shown below.


=item * upload_retrieve()

However you retrieve the CGI variable, it is named "token". 

    # Handle CGI variables
    parse_form_data();

    my $token  = $FORM_DATA{token};

Use the token to retrieve a I<hash reference> with relevant results.

    # Retrieve file hash_ref
    my $file   = $upload->upload_retrieve({ token => $token });

    my $vars = { path_name   => $file->{file_path} . '/' . $file->{file_name} };

Use the file information to further your nefarious schemes.

=back


=head2 Core Methods

So far unmentioned is the fact that the Package injected into the template 
includes an "B<attempt token>". When a file is selected by an I<end user>, 
the JavaScript submits the attempt token along with the file to the server 
UE Core via AJAX. The Package includes the correct URL for UE Core, and swaps 
the Core URL with your URL before submitting the form for the first time. On 
success, your URL is replaced along with new HTML code that includes the 
success token.


=over 4

=item * upload_validate()

    $file_obj  = $upload->upload_validate({ token => $token });

A Core implementation first calls I<upload_validate()> with the attempt token. The 
returned file object has relevant details for the Core to validate the file and save 
it to the appropriate directory.

=item * upload_success()

    $success  = $upload->upload_success({ token     => $token, 
                                          file_name => $file_name, 
                                          file_size => $file_size}); 

If the file is valid and uploads I<without fail>, the Core updates the name and size, 
and returns a success token.

=back

=head2 Token Generation

Tokens are generated simply using alphanumerics and underscore, through rand().

    our $token_length = 60;
    our @token_chars  = ("a".."z","A".."Z","0".."9","_");

    # Random string created from global package variables
    foreach (1..$token_length) { $token .= $token_chars[rand @token_chars]; }


=head2 Injected Package Example

The following is included as an accessible reference, and is not meant to be copied 
or used directly. The code below was generated by the private method 
I<_generate_html()>. 

          <tr>
               <td> Select file </td>
               <td> 
    <script type="text/javascript"> 
    Ext.onReady(function() {
    var file_upload_box =  Ext.get("auto_file");
    var auto_file_form  =  document.forms[0];
    var action          = document.forms[0].action;
    var encoding        = document.forms[0].encoding;
    var file_id;
     
    document.forms[0].action   = "http://DOMAIN/upload";
    document.forms[0].encoding = "multipart/form-data";
     
       file_upload_box.addListener("change", function(el) {
     
            Ext.Ajax.request({
                    form: auto_file_form,
                    success: function(response, opts) {
                                    if(!response.responseText.match(/ERROR: /)){ 
    					file_id = Ext.util.JSON.decode(response.responseText).success;
    					Ext.fly(file_upload_box).remove();
    					Ext.fly(file_control).insertHtml("afterBegin", "<img src="http://DOMAIN/images/checked.jpg"> File Uploaded");
                                    
    					var token   =  document.getElementById("token");
    					token.value = file_id;
    					document.forms[0].action   = action;
    					document.forms[0].encoding = encoding;
    				}else{
    					//we have an error.
    					Ext.fly(file_upload_box).remove();
    					//if possible decode the JSON
    					try{
    						file_id = Ext.util.JSON.decode(response.responseText).success;
    						Ext.fly(file_control).insertHtml("afterBegin", "<img src="http://DOMAIN/images/alert.jpg">"+file_id);
    					}catch(e){
    						//JSON decode failed so use responseText
    						Ext.fly(file_control).insertHtml("afterBegin", "<img src="http://DOMAIN/images/alert.jpg">"+response.responseText);
    					}
    				}
                            },
                    failure: function(response, opts) {
                                    alert("server-side failure with status code " + response.status);
                            }
             });
     
       });
    });
    </script>
    <div name="file_control" id="file_control"> 
    <input type="file" size="50" name="auto_file" id="auto_file">
    <input type="hidden" name="token" id="token" value="xGgbwIKjcM_SJ75uAvwwg4f3OtpQjcrULSmiUuXnSqYaFeZ8LoVxJUgrVg9a">
    </div>
               </td> 
          </tr>

The elements are wrapped in a I<div> named "B<file_control>", which is used as the 
anchor to replace the elements with the success token.

=head1 DIAGNOSTICS

=over

These errors are meant to appear on the upload page if an upload was not successful. If you get one of these as an exception, then it was not caught correctly.

=item C<<"ERROR: Failed to copy '%s1' to '%s2': %s3">>

This error occurs when the uploaded file could not be copied. It is most likely a file system issue.

%s1 - file name
%s2 - target location
%s3 - error string

=item C<<"ERROR: file size $file_size is smaller than min size $min_size">>

The size of the file that was to be uploaded was smaller than the minimum size set in the configuration file or passed to IOSea::Upload::upload_prepare.

=item C<<"ERROR: file size $file_size is larger than max size $max_size">>

The size of the file that was to be uploaded was larger than the minimum size set in the configuration file or passed to IOSea::Upload::upload_prepare.

=item C<<"ERROR: file type $type not allowed. Allowed types are: $allowed_types">>

The type of the file that was to be uploaded was not listed in the allowed types set in the configuration file or passed to IOSea::Upload::upload_prepare.

=item C<<"ERROR: file type $type is forbidden. Forbidden types are: $disallowed_types">>

The type of the file that was to be uploaded was listed in the forbidden types set in the configuration file or passed to IOSea::Upload::upload_prepare.

=item C<<"ERROR: request upload failed">>

The catalyst request failed




=item C<<"could not determine db name from arguments">>

The database name was not in the parameter hash used to initialize an IOSea::Upload object or in the config file.

=item C<<"could not determine host from arguments">>

The host was not in the parameter hash used to initialize an IOSea::Upload object or in the config file.

=item C<<"could not determine user from arguments">>

The user was not in the parameter hash used to initialize an IOSea::Upload object or in the config file.

=item C<<"could not determine pass from arguments">>

The password was not in the parameter hash used to initialize an IOSea::Upload object or in the config file.

=item C<<"no file_path could be determined for upload_prepare">>

The file path was not in the parameter hash passed to IOSea::Upload::upload_prepare or in the config file.

=item C<<"no max_size could be determined for upload_prepare">>

The max size was not in the parameter hash passed to IOSea::Upload::upload_prepare or in the config file.

=item C<<"no min_size could be determined for upload_prepare">>

The min size was not in the parameter hash passed to IOSea::Upload::upload_prepare or in the config file.

=item C<<"failed to write file parameters to database">>

The SQL call to insert file parameters into the database failed.

=item C<<"ERROR: failed to exec sql statement">>

An SQL call failed or returned no results.

=item C<<"ERROR: file_path is blank">>

The file path retrieved from the database in IOSea::Upload::upload_validate was blank.

=item C<<"ERROR: max_size is blank">>

The max size retrieved from the database in IOSea::Upload::upload_validate was blank.

=item C<<"ERROR: min_size is blank">>

The min size retrieved from the database in IOSea::Upload::upload_validate was blank.

=item C<<"ERROR: created is blank">>

The created field retrieved from the database in IOSea::Upload::upload_validate was blank.

=item C<<"ERROR: success_token already exists for attempt_token: $attempt_token">>

In IOSea::Upload::upload_success, there is already a success token corresponding to the current attempt token. This indicates that this is a duplicate attempt at uploading. Possibly caused by dubiously altered HTML code.

=item C<<"could not determine root_url from config hash">>

In IOSea::Upload::_generate_html, the root url was not in the config hash. Likely because it was not correctly specified in the config file.

=item C<<"config hash not defined in _generate_html()">>

In IOSea::Upload::_generate_html, the config hash was not set. This is likely because it is missing, incorrectly formatted, or the path to it is wrong in the controller Upload.pm or UploadEG.pm
=back


=head1 CONFIGURATION AND ENVIRONMENT

CGI::UploadEngine is not CPAN "install" friendly and requires significant 
configuration, but all files and directions are included in this section.

There is a custom perl install script (with I<bash> execs). It might not work for 
your system, so the steps required are described below. B<Please read the directions 
first so you will understand what the script is asking from you.>

Download, unzip, and expand the archve. All the commands below should be run from the 
root package directory, I<ls -lh> should look (mostly) like this:

    drwxr-xr-x 2 root root 4096 Oct 28 04:05 cgi-bin
    -rw-r--r-- 1 root root   96 Oct 26 02:11 Changes
    drwxr-xr-x 2 root root 4096 Oct 28 04:28 Controller
    drwxr-xr-x 2 root root 4096 Oct 26 15:43 images
    -rwxr-xr-x 1 root root 5677 Oct 26 15:58 install
    drwxr-xr-x 3 root root 4096 Oct 26 02:11 lib
    -rw-r--r-- 1 root root  535 Oct 26 02:11 Makefile.PL
    -rw-r--r-- 1 root root   72 Oct 26 22:10 MANIFEST
    -rw-r--r-- 1 root root 1096 Oct 26 02:55 README
    drwxr-xr-x 3 root root 4096 Oct 26 02:47 root
    drwxr-xr-x 2 root root 4096 Oct 26 02:53 scripts
    drwxr-xr-x 2 root root 4096 Oct 26 02:47 sql
    drwxr-xr-x 2 root root 4096 Oct 26 02:47 t
    -rw-r--r-- 1 root root  162 Oct 26 02:51 uploadengine

=head2 Manual Installation

The following commands are what the install script attempts to accomplish. After 
you read through the steps, try the install script before trying to follow the steps 
manually. 

If you are attempting manual installation, note that these commands were developed 
in I<bash> shell. If you are unsure what shell you are using, go ahead and start bash 
now:

    bash


=over 4

=item * Initialize Variables

It will save a few steps if we get this out of the way first. The 
variables in question here are all related to target directories and server 
information. Values below are typical (for a Catalyst project I<MBC>), but yours 
may be different.

    UE_APACHE_ROOT=/var/www;                                     export UE_APACHE_ROOT;
    UE_CGI_DIR=$APACHE_ROOT/cgi-bin;                             export UE_CGI_DIR;
    UE_IMAGE_DIR=$APACHE_ROOT/html/images;                       export UE_IMAGE_DIR;
    UE_EXT_PATH=$APACHE_ROOT/html/js/ext-core/ext-core-debug.js; export UE_EXT_PATH;

    UE_CAT_PROJ=MBC;                                             export UE_DOMAIN;
    UE_CONTROLLER_DIR=/var/www/catalyst/MBC/lib/MBC/Controller;  export UE_CONTROLLER_DIR;
    UE_TMPL_DIR=/var/www/catalyst/MBC/root/src;                  export UE_TMPL_DIR;

    UE_DOMAIN=bioinformatics.ualr.edu;                           export UE_DOMAIN;
    UE_ROOT_URL=http://$UE_DOMAIN/catalyst;                      export UE_ROOT_URL;
    UE_EXT_URL=http://$UE_DOMAIN/js/ext-core/ext-core-debug.js;  export UE_EXT_URL;

=item * Install CGI::UE config

This configuration file allows server level settings for failure icon, success 
message, root URL, allowed file types, and future features. It has to be in a 
directory that is readable by Apache, and the path is currently hard-coded in 
CGI::UE. 

=over 4

=item * Copy script to apache root directory

The script name is prepended with a period to "hide" it.

    cp uploadengine $UE_APACHE_ROOT/.uploadengine

=item * Update config path in CGI::UE module

    sed 's#APACHE_ROOT#$UE_APACHE_ROOT#g';

=back

=item * Install CGI::UE Module

After the apache root directory is updated, install the module:

    perl Makefile.PL
    make install clean
    rm -f Makefile.old
    perl t/00.load.t


=item * Install UE Database

The UE only requires a single table, but a new, separate database is recommended. The 
installation script will ask for your password in order to create the necessary mysql 
resource. To install manually, first create the database, here named I<files>:

    mysqladmin -p create files

The create the table:

    mysql -p files <sql/upload.sql

The I<-p> switch makes each program prompt you for the password. You will also need 
to create a user and password on the database for CGI::UE to use. The database name, 
user, and pass will need to match the values in I<cgi-bin/upload_cfg.pl>.

B<Note: Do *NOT* use the example password "I<tmie>"below. *DO* use an new, independent user such as "I<files>".>

    mysql -p files -e "grant all privileges on files.* to 'files'\@'localhost' identified by 'tmie'";

=item * Install CGI::UE Core

As mentioned above, the only Core currently provided is a Catalyst module, and 
therefore requires a working Catalyst project. 

=over 4

=item * Copy template

This template defines the response from the Core to the AJAX file upload.

    cp root/src/upload.tt2 $UE_TMPL_DIR/upload.tt2

=item * Rename controller namespace

    sed 's#UE_CAT_PROJ#$UE_CAT_PROJ#g';

=item * Copy controller

    cp Controller/Upload.pm $UE_CONTROLLER_DIR/Upload.pm

=item * Restart apache

The installation script does not restart apache at all, but if you are installing 
manually, we recommend a restart at this point to test that CGI::UE is installed well 
enough to I<use>.

=back


=item * Install Sample Developer App

Two types of sample apps are included: Catalyst controllers and "old school" CGI 
scripts. You might install both, but you should install at least one to test the 
installation.

In each case, there are two actions: form_eg and handler_eg. The first creates a 
sample form with a file select box and one other text box using the I<upload_prepare()> 
method. The second uses I<upload_retrieve()> to get the results from the engine. The 
scripts are shown above in the Synopsis. The controllers perform equivilant actions 
under Catalyst.

=over 4

=item * Install CGI scripts

The CGI scripts need several support files: templates for each action, a 
configuration file with web server details, and a library file that 
handles HTTP responses and HTML layout.


=over 4

=item * Install the javascript file

For security reasons, the jasvascript path needs to be from your server.

=item * Update javascript path in config file

The javascript file is 

=item * Update URLs in config file

The domain

    sed 's#APACHE_ROOT#$UE_APACHE_ROOT#g';

=back


=item * Install Catalyst controllers

    cp Controller/Upload.pm $UE_CONTROLLER_DIR/Upload.pm

=item * Restart apache

The installation script does not restart apache at all, but if you are installing 
manually and chose to install the sample controllers, we recommend a restart at this 
point to test that the Controllers will load.


=back



=back


=head2 Installation Script

To install, type:

    bash
    perl installUE



=head1 DEPENDENCIES

  Class::Std


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-cgi-uploadengine@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHORS

    Roger A Hall  C<< <rogerhall@cpan.org> >>
    Michael A Bauer  C<< <mbkodos@cpan.org> >>
    Kyle D Bolton  C<< <kdbolton@ualr.edu> >>
    Aleksandra A Markovets  C<< <aamarkovets@ualr.edu> >>


=head1 LICENSE AND COPYRIGHT

Copyleft (c) 2011, Roger A Hall C<< <rogerhall@cpan.org> >>. All rights pre-served.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
