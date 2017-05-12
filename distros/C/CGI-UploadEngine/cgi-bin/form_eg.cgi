#!/usr/bin/perl -I.

use CGI::UploadEngine;
use YAML::Any qw(LoadFile);
use Template;
require "upload_html.pl";

my $config_loc;

my $config = LoadFile($config_loc);
my $db     = $config->{db};
my $host   = $config->{host};
my $user   = $config->{user};
my $pass   = $config->{pass};

# Create an upload object
my $upload = CGI::UploadEngine->new({ db => $db, host => $host, user => $user, pass => $pass });

#TODO: need to write new paths for this or something? not sure how it works
# Set the view template
my $tmpl = 'upload/form_eg.tt2';

# Set the template variables
my $vars = { action_url  => $root_url . 'cgi-bin/handler_eg.cgi',
	     file_upload => $upload->upload_prepare({ file_path => '/tmp' }) };

# Process the template
my $result;
my $template = Template->new({ INCLUDE_PATH => $tmpl_incl });
   $template->process( $tmpl, $vars, \$result );

# Print the page
header();
print $result;
footer();

exit;

