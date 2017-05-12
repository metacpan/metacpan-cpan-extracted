package example_3;

use strict;    # always a good idea to include these in your
use warnings;  # modules


use base qw ( Example );

sub setup {

    my $self = shift;

    $self->run_modes( [ qw ( navbar) ] );
}

sub navbar {
    my $self = shift;

    my %tmplvars = ();

    my $url = $self->query->url(-full=>1);
    $url .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};

    $url =~ s/example_(\d+[a-z]?)/example_1/g;
    $tmplvars{'EXAMPLE_1'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'main_display',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_2a/g;
    $tmplvars{'EXAMPLE_2'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'main_display_mutt',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_3/g;
    $tmplvars{'EXAMPLE_3'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'navbar',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_4/g;
    $tmplvars{'EXAMPLE_4'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'main_view',
	 }
	 );

    $url =~ s/example_(\d+[a-z]?)/example_5/g;
    $tmplvars{'EXAMPLE_5'} = $self->make_link
	(
	 url => $url,
	 qs_args => {
	     rm => 'show_user_table',
	 }
	 );

    return $self->template->fill(\%tmplvars);

}


1; # It's gotta be 1...
