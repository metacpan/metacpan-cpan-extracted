package CGI::Portal::Controls::emailpw;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Generate a random passw, update and email to user 

use strict;

use Digest::MD5 qw(md5_hex);
use CGI::Portal::Scripts::emailpw;
use CGI::Portal::Scripts;

use vars qw(@ISA $VERSION);

$VERSION = "0.12";

@ISA = qw(CGI::Portal::Scripts);

1;

sub launch {
  my $self = shift;

            # Require usr
  if ($self->{'in'}{'usr'}){

            # Get users email
    my $r = $self->{'rdb'}->exec("select $self->{'conf'}{'user_additional'}[0],$self->{'conf'}{'user_user_field'} from $self->{'conf'}{'user_table'} where $self->{'conf'}{'user_user_field'} like " . $self->{'rdb'}->escape($self->{'in'}{'usr'}) . " limit 1")->fetch;

            # Validate email
    if ($r->[0] =~ /.*@.*\./){

            # Generate a passw
      my $pw = substr(md5_hex(rand(64)), 1, 9);

            # Hash the passw
      my $enc_pw = md5_hex($pw);

            # Update
      $self->{'rdb'}->exec("update $self->{'conf'}{'user_table'} set $self->{'conf'}{'user_passw_field'}=\'$enc_pw\' where $self->{'conf'}{'user_user_field'}=" . $self->{'rdb'}->escape($r->[1]));

            # Email passw to user
      mailit($r->[0],$self->{'conf'}{'admin_email'},"Logon Info ","Please use $pw to log on, and choose a new password at your convenience.");
      $self->{'tmpl_vars'}{'result'} = "A temporary password has been emailed to you.";
    }
    elsif (! $r->[0] ){

            # No email no user
      $self->{'tmpl_vars'}{'result'} = "Unknown User";

    }else{
      $self->{'tmpl_vars'}{'result'} = "Invalid email on record, please contact us.";
    }
  }

            # Redirect
  $self->CGI::Portal::Scripts::emailpw::launch();
  return;
}

            # Emailing
sub mailit {
  my $recipient = shift;
  my $sender = shift;
  my $subject = shift;
  my $message = shift;
  open(MAIL, "|/usr/lib/sendmail -t");
  print MAIL "To: $recipient\n";
  print MAIL "From: $sender\n";
  print MAIL "Subject: $subject\n\n";
  print MAIL "$message";
  close (MAIL);
}