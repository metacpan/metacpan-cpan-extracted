package CGI::Portal::Sessions;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Authentication and Session class

use strict;

use Digest::MD5 qw(md5_hex);

use vars qw($VERSION);

$VERSION = "0.12";

1;

sub new {
  my ($class, $i) = @_;
  bless $i, $class;
  return $i;
}

            # Verify password or session
sub authenticate_user {
  my $self = shift;

            # User is logging in
  if ($self->{'in'}{'user'} && $self->{'in'}{'password'}){

            # Get users stored password hash
    my $users = $self->{'rdb'}->exec("select $self->{'conf'}{'user_user_field'},$self->{'conf'}{'user_passw_field'} from $self->{'conf'}{'user_table'} where $self->{'conf'}{'user_user_field'} like " . $self->{'rdb'}->escape($self->{'in'}{'user'}))->fetch;

            # Compare password hashes
    if (md5_hex($self->{'in'}{'password'}) eq $users->[1]){

            # Assign user to object
      $self->{'user'} = $users->[0];

            # Start session
      $self->start_session($users->[0]);

            # Clean sessions
      $self->clean_sessions();
      return;
    }
  }elsif (my $sid = getcookie('sid')){

            # Session expiration
    my $exps = time() - $self->{'conf'}{'session_length'};

            # Get session start
    my $sessions = $self->{'rdb'}->exec("select $self->{'conf'}{'session_user_field'},$self->{'conf'}{'session_start_field'} from $self->{'conf'}{'session_table'} where $self->{'conf'}{'session_sid_field'}=" . $self->{'rdb'}->escape($sid))->fetch;

            # Session not expired
    if ($sessions->[0] && $sessions->[1] >= $exps){

            # Assign user to object
      $self->{'user'} = $sessions->[0];

            # Renew session
      $self->renew_session($self->{'user'});
      return;
    }
  }

            # Assign tmpl
  $self->assign_tmpl("Sessions.html");
}

            # Create a session
sub start_session {
  my ($self, $user) = @_;
  my $current_time = time();

            # Generate a session id
  my $sid;
  my $cids;
  while ($cids->[0] || ! $sid) {
    $sid = md5_hex($$ , time() , rand(8888) );
    $cids = $self->{'rdb'}->exec("select $self->{'conf'}{'session_index_field'} from $self->{'conf'}{'session_table'} where $self->{'conf'}{'session_sid_field'} = $sid limit 1")->fetch;
  }

            # Get current session index
  my $cc = $self->{'rdb'}->exec("select $self->{'conf'}{'session_index_field'} from $self->{'conf'}{'session_table'} order by $self->{'conf'}{'session_index_field'} desc limit 1")->fetch;
  my $c = $cc->[0]+1;

            # Insert session and prepare cookie
  $self->{'rdb'}->exec("insert into $self->{'conf'}{'session_table'} ($self->{'conf'}{'session_index_field'},$self->{'conf'}{'session_sid_field'},$self->{'conf'}{'session_user_field'},$self->{'conf'}{'session_start_field'}) values (" . $self->{'rdb'}->escape($c, $sid, $user, $current_time) . ")");
  $self->{'cookies'} .= "Set-Cookie: sid=$sid; path=/\n";
}

            # Update session start
sub renew_session {
  my $self = shift;
  my $sid = getcookie('sid');
  my $current_time = time();
  $self->{'rdb'}->exec("update $self->{'conf'}{'session_table'} set $self->{'conf'}{'session_start_field'}=$current_time where $self->{'conf'}{'session_sid_field'}=" . $self->{'rdb'}->escape($sid));
}

            # Remove session
sub logoff {
  my $self = shift;
  my $sid = getcookie('sid');
  $self->{'rdb'}->exec("delete from $self->{'conf'}{'session_table'} where $self->{'conf'}{'session_sid_field'}=" . $self->{'rdb'}->escape($sid));
  $self->{'user'} = "";
}

            # Remove expired sessions
sub clean_sessions {
  my $self = shift;
  my $exps = time() - $self->{'conf'}{'session_length'};
  $self->{'rdb'}->exec("delete from $self->{'conf'}{'session_table'} where $self->{'conf'}{'session_start_field'} < $exps");
}

            # Assign template output to object out
sub assign_tmpl {
  my ($self, $i) = @_;

            # Read template
  my $template = HTML::Template->new(die_on_bad_params => 0, filename => "$self->{'conf'}{'template_dir'}$i");
  $self->{'tmpl_vars'}{'SCRIPT_NAME'} = $ENV{'SCRIPT_NAME'};

            # Assign vars to template
  $template->param(%{$self->{'tmpl_vars'}});

            # Assign template output to object out
  $self->{'out'} = $template->output;
}

sub getcookie {
  my $cookiename = shift;
  my $cookie;
  my $value;
  if ($ENV{'HTTP_COOKIE'}) {
    foreach (split(/; /,$ENV{'HTTP_COOKIE'})) {
      ($cookie,$value) = split(/=/);
      if ($cookiename eq $cookie) {
        return $value;
      }
    }
  }
}