package example_4;

use strict;    # always a good idea to include these in your
use warnings;  # modules

# ------------------------------------------------------------------
# You must have this!  Or rather, you must "use base" a module that
# inherets from CGI::Application::Framework and adhers to its
# specifications.
# ------------------------------------------------------------------
use base qw ( Example );
# ------------------------------------------------------------------

use Time::Format qw ( %time );

sub setup {

    my $self = shift;

    $self->run_modes( [ qw (
        main_view
        outer_component
        inner_component
        make_navbar
    ) ] );

}

sub main_view {

    my $self = shift;

    ### ================================================================
    ### Populate the template variables (a.k.a. TMPL_VARs) within
    ### the composed HTML::Template object
    ### ================================================================

    my %tmplvars = (); # we'll use this to accumulate tmpl_var values

    # ----------------------------------------------------------------
    # Here's a selection of various things that you can do to populate
    # simple TMPL_VARs.
    # ----------------------------------------------------------------
    $tmplvars{'load_count'}     = ++$self->session->{count};
    $tmplvars{'SELF_HREF_LINK'} = $self->make_link
	(
	 qs_args => {
	     rm => 'main_view',
	 }
	 );
    # ------------------------------------------------------------------

    ### ================================================================
    ### /end of populating HTML::Template TMPL_VARs
    ### ================================================================

    ### ================================================================
    ### All done -- output rendered template with interpolated TMPL_VARs
    ### ================================================================
    return $self->template->fill(\%tmplvars);
    ### ================================================================
}

sub outer_component {
    my $self = shift;

    my %tmplvars = ();

    $tmplvars{'time_within_include'} = $time{'yyyy/mm/dd hh:mm:ss'};

    return $self->template->fill(\%tmplvars);

}

sub inner_component {
    my $self = shift;

    my %tmplvars = ();
    $tmplvars{'inner_var'} = 'some inner value';

    return $self->template->fill(\%tmplvars);
}

1;  # most Perl .pm files end in "1;".  It's tradition.


