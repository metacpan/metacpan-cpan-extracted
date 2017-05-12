package example_2b;

use strict;    # always a good idea to include these in your
use warnings;  # modules

use base qw ( Example );

sub setup {

    my $self = shift;

    $self->run_modes( [ qw ( main_display_jeff ) ] );
}

sub main_display_jeff {

    my $self = shift;

    my %tmplvars = ();

    $tmplvars{'load_count_just_here'  } = ++$self->session->{count_jeff};
    $tmplvars{'load_count_for_session'} = ++$self->session->{count_session};

    $tmplvars{'SELF_HREF_LINK'} = $self->make_link
	(
	 qs_args => {
	     rm => 'main_display_jeff',
	 }
	 );

    # -------------------------------------------------------------
    # It is a bit of a production to create a URL that matches the
    # same specifications as what the link HMAC confirmation
    # routine in the "_checksum_okay" subroutine in Framework.pm
    # expects.  You must specify a "url" parameter to the
    # $self->make_link method.  The url must be fully-qualified,
    # i.e. if you want to submit to "a.pl" then you have to
    # include everything that $self->query->url is going to
    # pick up on, for instance something along the lines of
    #   https://foo.bar.com:8000/1/2/3/4/a.pl" (for as much of that
    # applies in your circumstance).  Using various aspects of the
    # $self->query->url method from CGI.pm will probably come in
    # handy to you for this.
    #
    # In my example here, I want to go from 'example_5b.pl' to
    # 'example_5a.pl', which means going from
    #     http://localhost/mvcwebcgi/example_5/example_5b.pl
    # to
    #     http://localhost/mvcwebcgi/example_5/example_5a.pl
    # In the pursuit of this,
    #     $self->query->url(-base=>1)
    # gives the "http://localhost" part,
    #     $self->query->url(-absolute=>1)
    # gives "/mvcwebcgi/example_5/example_5b.pl", and then I use
    # substr to chop off the "example_5b.pl", and then I append
    # "example_5a.pl".
    #
    # Note that I have to specify a known run-mode within
    # example_5a.pm that this is being submit to.
    # -------------------------------------------------------------

    my $url = $self->query->url(-full=>1);
    $url .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};
    $url =~ s/example_2b/example_2a/g;

    $tmplvars{'MUTT_HREF_LINK'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'main_display_mutt',
	 }
	 );
    # -------------------------------------------------------------

    return $self->template->fill(\%tmplvars);
}

1; # It's gotta be 1...
