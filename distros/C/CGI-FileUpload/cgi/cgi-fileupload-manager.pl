#!/usr/bin/env perl
use strict;
use Carp;
use Pod::Usage;

=head1 NAME

cgi-fileupload-manager.pl - a cgi script to display past and currently uploaded files, either for the curretn user or all (admin mode)

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
use CGI::FileUpload::Manager;
use CGI;
use Time::localtime;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
#warningsToBrowser(1);

my $query=new CGI;

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

my $action=$query->param('action');
if (defined $action){
  my @keys=$query->param('key');
  if($action eq 'remove'){
    foreach (@keys){
      my $fu=CGI::FileUpload->new(key=>$_);
      $fu->remove();
    }
  }
}

my $isAdmin=$query->param('admin');
my @fus=CGI::FileUpload::Manager::ls();
print <<EOT;
<form method='POST'>
<table>
  <tr>
    <th>file</th>
    <th>date</th>
    <th>status</th>
    <th>size</th>
    <th>from</th>
EOT
if($isAdmin){
  print "    <th>id</th>\n";
}

print <<EOT;
    <th><input type='submit' value='remove' name='action'/></th>
  </td>
EOT
# TODO get creation time + set it coherent with sort
my $id=CGI::FileUpload::idcookie(query=>$query)->{id};
foreach(@fus){
  next unless $isAdmin || ($_->from_id() eq $id);
  my $status=$_->upload_status();
  print "  <tr>\n";
  print "    <td>".$_->file_orig()."</td>\n";
  print "    <td>".(ctime((stat($_->file('.properties')))[9]))."</td>\n";
  print "    <td>$status</td>\n";
  print "    <td>".(($status eq 'completed')?(-s $_->file()):'n/a')."</td>\n";
  print "    <td>".$_->from_ipaddr()."</td>\n";
  print "    <td>".$_->from_id()."</td>\n" if $isAdmin;
  print "    <td align='center'><input type='checkbox' name='key' value='".$_->key()."'/></td></tr>\n";
}
print <<EOT;
</table>
</form>
<form >
<input type='submit' value='refresh'/>
EOT
print $query->end_html;
