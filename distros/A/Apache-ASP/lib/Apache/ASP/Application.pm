
package Apache::ASP::Application;

use Apache::ASP::State;
use Apache::ASP::Collection;

use strict;
no strict qw(refs);
use vars qw(@ISA);
@ISA = qw(Apache::ASP::Collection Apache::ASP::State);
use Fcntl qw(:flock O_RDWR O_CREAT );

sub new {
    my($asp) = @_;
    my(%self);

    unless(
	   tie(
	       %self,'Apache::ASP::State', $asp, 
	       'application', 'server', 
	       )
	   )
    {
	$asp->Error("can't tie to application state");
	return;
    }

    bless \%self;
}

sub Lock { shift->SUPER::LOCK };
sub UnLock { shift->SUPER::UNLOCK };

sub SessionCount {
    my $asp = tied(%{$_[0]})->{asp};
    if($asp->{session_count}) {
	$asp->{Internal}{SessionCount};
    } else {
	undef;
    }
}

sub GetSession {
    my($self, $id) = @_;
    my $asp = tied(%$self)->{'asp'};
    unless(defined $id and $id) {
	$asp->Warn("session id not defined");
	return;
    }
    unless(length($id) >= 8) {
	$asp->Warn("session id must be of at least 8 in length");
	return;
    }

    if($asp->{Session} and $asp->{Session}->SessionID() eq $id) {
	return $asp->{Session};
    } else {
	my $new_session = Apache::ASP::Session::new($asp, $id, O_RDWR, 'NOERR');
	if($new_session) {
	    if ($asp->{get_session_last}) {
		my $session_obj = tied %{$asp->{get_session_last}};
		$asp->{dbg} && $asp->Debug("freeing last session $asp->{get_session_last} $session_obj");
		$session_obj && $session_obj->DESTROY;
	    }
	    $asp->{get_session_last} = $new_session;
	    $asp->RegisterCleanup(sub {
				      my $session_obj = tied %$new_session;
				      $session_obj && $session_obj->DESTROY;
				  });
	}
	$new_session;
    }
}

1;
