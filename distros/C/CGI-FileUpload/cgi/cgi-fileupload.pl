#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

cgi-fileupload.pl - a cgi script upload a file on the server

=cut


$|=1;		        #  flush immediately;

BEGIN{
 eval{
   require DefEnv;
   DefEnv::read();
  };
}

END{
}

use CGI::FileUpload;
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
warningsToBrowser(1);

my $query=new CGI;

my $action=$query->param('action');
unless (defined $action){
  print $query->header;
  #TODO css with border in table and bit better...
  my $css;
  if(open (FH, "<cgi-upload.css")){
    local $/;
    $css=<FH>;
    close FH;
  }
  print $query->start_html(-title => 'CGI::FileUpload manager',
			   -STYLE => {-verbatim => $css},
			  );

  print CGI::FileUpload::formString();
  print <<EOT;
visit the <a href="cgi-fileupload-manager.pl">upload manager</a>
EOT
  print $query->end_html;
}else{
  if($action eq 'upload'){
    my %h;
    $h{key}=$query->param('key') if $query->param('key');
    $h{suffix}=$query->param('suffix') if $query->param('suffix');
    my $fu=new CGI::FileUpload(%h);
    $fu->upload(query=>$query);
  }else{
    die "unknonw action [$action]";
  }
}
