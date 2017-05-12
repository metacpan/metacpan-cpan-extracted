#!/usr/bin/perl -I.

use CGI::UploadEngine;
use Template;
require "upload_cfg.pl";
require "upload_html.pl";

# Handle CGI variables
parse_form_data();

my $token  = $FORM_DATA{token};
my $other  = $FORM_DATA{other};

# Create an upload object
my $upload = CGI::UploadEngine->new({ db => 'files', user => 'files', pass => 'tmie' });

# Retrieve file hash_ref
my $file   = $upload->upload_retrieve({ token => $token });

# Set the view template
my $tmpl = 'upload/handler_eg.tt2';

# Set the template variables
my $vars = { path_name   => $file->{file_path} . '/' . $file->{file_name},
	     other       => $other };

# Process the template
my $result;
my $template = Template->new({ INCLUDE_PATH => $tmpl_incl });
   $template->process( $tmpl, $vars, \$result );

# Print the page
header();
print $result;
footer();

exit;

