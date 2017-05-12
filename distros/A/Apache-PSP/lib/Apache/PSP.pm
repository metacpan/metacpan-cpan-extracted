package Apache::PSP;

require 5.005;

use strict;

use Template::PSP;
use Apache::Constants qw( :common );
use vars qw($VERSION);

$VERSION = 1.00;

sub handler
{
  my $r = shift(@_);
  
  # check that the file exists
  unless (-e $r->filename)
  {
    return NOT_FOUND;
  }
  
  # send success headers
  $r->content_type('text/html');
  $r->send_http_header();
  
  # return only headers for HEAD requests
  if ( $r->header_only )
  {
    return OK;
  }
  
  # generate the page code using the provided file
  my $page_code;
  eval { $page_code = Template::PSP::pspload($r->filename, undef, 1); };
  
  if ($page_code)
  {
    # execute the page generation code
    eval
    {
      &$page_code();
    };
    
    if ($@)
    {
      print qq{<font color="red"><tt>$@</tt></font>\n};
      
      # terminate this Apache process to avoid intermediate state problems
      # (temporary until a full cleanup handler is available)
      $r->child_terminate;
    }
  }
  else
  {
    # log the failure 
    $r->log_reason("Could not load page", $r->filename);
    print qq{<font color="red"><tt>Can't load page. $@</tt></font>\n};
    print qq{<p>Process $$ will be restarted.</p>\n};

    # terminate this Apache process to avoid intermediate state problems
    # (temporary until a full cleanup handler is available)
    $r->child_terminate;
  };
  
  return OK;
}

1;

__END__

=head1 NAME

Apache::PSP - mod_perl interface to Perl Server Pages

=head1 SYNOPSIS

  <Files *.psp>
  SetHandler perl-script
  PerlHandler Apache::PSP
  Options ExecCGI
  </Files>

=head1 DESCRIPTION

Apache::PSP is the mod_perl interface to the Template::PSP module. This module allows Perl Server Pages (PSP) to be used on an Apache server running mod_perl.

See the Template:PSP module for a more detailed explanation of PSP pages and their usage.

=head1 AUTHOR

Chris Radcliff, chris@globalspin.com

=head1 SEE ALSO

Template::PSP

=cut
