package Apache::App::Mercury::UserManager::Demo;

require 5.004;
use strict;

use base qw(Apache::App::Mercury::Base);

sub initialize {
    my ($self, $wm) = @_;
    # grab ref to Apache request and CGI objects from parent
    $self->{r} = $wm->{r} if ref $wm->{r};
    $self->{q} = $wm->{q} if ref $wm->{q};
}

sub cleanup {
    foreach (qw(q r)) {	delete $_[0]->{$_} }
}

use constant USERS    => [ qw(homer marge bart lisa maggie) ];
use constant USERINFO => { homer => { user  => 'homer',
				      fname => 'Homer',
				      mname => 'T',
				      lname => 'Simpson',
				      e_mail => 'homer@simpsons.com',
				    },
			   marge => { user  => 'marge',
				      fname => 'Marge',
				      mname => 'N',
				      lname => 'Simpson',
				      e_mail => 'marge@simpsons.com',
				    },
			   bart => { user  => 'bart',
				     fname => 'Bart',
				     mname => 'P',
				     lname => 'Simpson',
				     e_mail => 'bart@simpsons.com',
				   },
			   lisa => { user  => 'lisa',
				     fname => 'Lisa',
				     mname => 'A',
				     lname => 'Simpson',
				     e_mail => 'lisa@simpsons.com',
				   },
			   maggie => { user  => 'maggie',
				       fname => 'Maggie',
				       mname => 'B',
				       lname => 'Simpson',
				       e_mail => 'maggie@simpsons.com',
				     },
			 };

sub userprofile {
    my ($self, $param) = @_;
    my $user = $self->{q}->param('user');
#    return $user if ($param eq 'user');
    return USERINFO->{$user}->{fname}." ".USERINFO->{$user}->{lname}
      if ($param eq 'user_desc');
    return USERINFO->{$user}->{$param};
}

sub get_userinfo {
    my ($self, @users) = @_;
    return map { USERINFO->{$_} } @users;
}

sub user_preferences {
    my ($self, $user) = @_;
    return ('user' => $user,
	    'custom_mailboxes' => [],
	    'mail_filters' => { trans => 'inbox' },
	    'mail_auto_forward' =>
	    { forward_low_security => 'none',
	      forward_medium_security => 'none',
	      forward_high_security => 'none' });
}

sub mailboxes {
    my ($self, $user, @update_boxes) = @_;
    return () unless @update_boxes;
    return 1;
}

sub mail_trans_filter {
    my ($self, $trans_box) = @_;
    return 'inbox' unless $trans_box;
    return 1;
}

sub auto_forward {
    my ($self, $level, $fwd_type) = @_;
    return 'none' unless $fwd_type;
    return 1;
}


1;
