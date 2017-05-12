package example_5;

use strict;    # always a good idea to include these in your
use warnings;  # modules

use base qw ( Example );

use Carp;

use Data::Dumper;

use CDBI::Example::example;

use Regexp::Common;

sub setup {

    my $self = shift;

    # -----------------------------------------------------------
    # See example_1.pm for its comments regarding this section --
    # they all apply equally well here.
    # -----------------------------------------------------------

    $self->run_modes(
                     [ qw (
                           show_user_table
                           add_user
                           process_add_user
                           edit_user
                           process_edit_user
                           delete_user
                           process_delete_user
                           make_navbar
                           )
                       ]
                     );
}

sub edit_user {

    my $self = shift;
    my $errs = shift;

    ### ==================================================================
    ### Now, do what it takes to populate the template variables (a.k.a.
    ### TMPL_VARs) within the composed HTML::Template object
    ### ==================================================================

    if ( length($self->query->param('uid')) ) {
        $self->session->{refuid} = $self->query->param('uid');
    }

    $self->log_confess(" Couldn't get a refuid ") unless $self->session->{refuid};

    my %tmplvars = (); # we'll use this to accumulate tmpl_var values

    my $user = CDBI::Example::example::Users->retrieve
        ( $self->session->{refuid} );
    $self->log_confess("Couldn't make a user") unless $user;

    $tmplvars{'username'} = $self->query->param('username') || $user->username;
    $tmplvars{'fullname'} = $self->query->param('fullname') || $user->fullname;
    $tmplvars{'password'} = $self->query->param('password') || $user->password;

    $tmplvars{'currently_username'} = $user->username;
    $tmplvars{'currently_fullname'} = $user->fullname;
    $tmplvars{'currently_password'} = $user->password;

    $tmplvars{'FORM_NAME'}   = 'add_user';
    $tmplvars{'FORM_METHOD'} = 'POST';
    $tmplvars{'FORM_ACTION'} = $self->query->url;
    $tmplvars{'FORM_ACTION'} .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};

    my $template = $self->template->load;
    $template->param(\%tmplvars);
    $template->param($errs) if $errs;

    ### ==================================================================
    ### /end of populating HTML::Template TMPL_VARs
    ### ==================================================================

    $template->param
        (
         webapp => $self,
         run_mode_tags => {
             COMEFROMRUNMODE => [ COMEFROM => $self->get_current_runmode ],
             CURRENTRUNMODE  => [ CURRENT  => $self->get_current_runmode ],
             SUBMITTORUNMODE => [ SUBMITTO => 'process_edit_user' ],
         }
         );

     return $template->output;
}

sub _add_edit_user_profile {

    my $self = shift;

    return {
        required => [ qw ( username fullname password ) ],
        constraints => {
            username => sub {
                my ($user) = CDBI::Example::example::Users->search
                    ( username => $self->query->param('username') );
                if ( $user ) {
                    if ( $user->uid == $self->session->{uid} ) {
                        return 0;
                    } else {
                        return 1;
                    }
                } else {
                    return 1;
                }
            }
        },
        msgs => {
            any_errors => 'some_errors',
            prefix     => 'err_',
        },
    };
}

sub process_edit_user {

    my $self = shift;

    # ------------------------------------------------------------------
    # Make sure that the form validates correct, which is partially
    # a function of whether or not the required fields are there, and
    # partially a matter of not being allowed to use the same username
    # as one that already exists in the database
    # ------------------------------------------------------------------
    my ($errs, $error_page) = $self->check_rm('edit_user',
                                              '_add_edit_user_profile');
    return $error_page if $error_page;
    # ------------------------------------------------------------------

    # ==================================================================
    # Looks like the form submission is okay, so update the $user in
    # the database
    # ==================================================================
    my $user = CDBI::Example::example::Users->retrieve
        ( $self->session->{refuid} );

    $self->log_confess(" Couldn't make a user ") unless $user;

    $user->username( $self->query->param('username') ) unless
        $user->username() eq $self->query->param('username');

    $user->fullname( $self->query->param('fullname') ) unless
        $user->fullname() eq $self->query->param('fullname');

    $user->password( $self->query->param('password') ) unless
        $user->password() eq $self->query->param('password');

    $user->update();
    # ==================================================================

    $self->session->{refuid} = undef;
    delete $self->session->{refuid};

    return $self->show_user_table();
}

sub add_user {

    my $self = shift;
    my $errs = shift;

    ### ==================================================================
    ### Now, do what it takes to populate the template variables (a.k.a.
    ### TMPL_VARs) within the composed HTML::Template object
    ### ==================================================================

    my %tmplvars = (); # we'll use this to accumulate tmpl_var values

    $tmplvars{'FORM_NAME'}   = 'add_user';
    $tmplvars{'FORM_METHOD'} = 'POST';
    $tmplvars{'FORM_ACTION'} = $self->query->url;
    $tmplvars{'FORM_ACTION'} .= $ENV{'PATH_INFO'} if $ENV{'PATH_INFO'};

    my $template = $self->template->load;
    $template->param(\%tmplvars);
    $template->param($errs) if $errs;

    ### ==================================================================
    ### /end of populating HTML::Template TMPL_VARs
    ### ==================================================================

    $template->output
        (
         webapp => $self,
         run_mode_tags => {
             COMEFROMRUNMODE => [ COMEFROM => $self->get_current_runmode ],
             CURRENTRUNMODE  => [ CURRENT  => $self->get_current_runmode ],
             SUBMITTORUNMODE => [ SUBMITTO => 'process_add_user' ],
         }
         );
     return $template->output;
}

sub process_add_user {

    my $self = shift;

    # ------------------------------------------------------------------
    # Make sure that the form validates correct, which is partially
    # a function of whether or not the required fields are there, and
    # partially a matter of not being allowed to use the same username
    # as one that already exists in the database
    # ------------------------------------------------------------------
    my ($errs, $error_page) = $self->check_rm('add_user',
                                              '_add_edit_user_profile');
    return $error_page if $error_page;
    # ------------------------------------------------------------------

    my $newuser = CDBI::Example::example::Users->create({
        username => $self->query->param('username'),
        fullname => $self->query->param('fullname'),
        password => $self->query->param('password'),
    });

    return $self->show_user_table();
}

sub delete_user {

    my $self = shift;

    my %tmplvars = ();

    $self->session->{'refuid'} = $self->query->param('uid');

    my $refuser = CDBI::Example::example::Users->retrieve
        (
         $self->session->{'refuid'}
         );

    $tmplvars{'username'} = $refuser->username;
    $tmplvars{'fullname'} = $refuser->fullname;

    $tmplvars{'confirm_delete_user'} = $self->make_link
        (
         qs_args => {
             rm => 'process_delete_user',
             delete_p => 'yes'
             }
         );

    $tmplvars{'reject_delete_user'} = $self->make_link
        (
         qs_args => {
             rm => 'process_delete_user',
             delete_p => 'no'
             }
         );

    return $self->template->fill(\%tmplvars);
}

sub process_delete_user {

    my $self = shift;

    if ( $self->query->param('delete_p') eq 'yes' ) {


        my $user = CDBI::Example::example::Users->retrieve
            (
             $self->session->{'refuid'}
             );
        $user->delete();

    } elsif ( $self->query->param('delete_p') eq 'no' ) {
        1;
    } else {
        $self->log_confess("Can't happen! ");
    }

    return $self->show_user_table;
}

sub show_user_table {

    my $self = shift;

    ### ==================================================================
    ### Now, do what it takes to populate the template variables (a.k.a.
    ### TMPL_VARs) within the composed HTML::Template object
    ### ==================================================================

    my %tmplvars = (); # we'll use this to accumulate tmpl_var values

    $tmplvars{'add_link'} = $self->make_link
        (
         qs_args => {
             rm  => 'add_user',
         }
         );

    my @users = CDBI::Example::example::Users->retrieve_all();

    my @user_loop_rows = ();
    foreach my $user ( @users ) {

        my %loopvars = ();

        $loopvars{'uid'}        = $user->uid;
        $loopvars{'uid_is_you'} = $user->uid == $self->session->{uid} ? 1 : 0;
        $loopvars{'username'}   = $user->username;
        $loopvars{'fullname'}   = $user->fullname;
        $loopvars{'password'}   = '******';
        $loopvars{'edit_link'} = $self->make_link
            (
             qs_args => {
                 rm  => 'edit_user',
                 uid => $user->uid,
             }
             );
        if ( scalar(@users) != 1 && ! $loopvars{'uid_is_you'} ) {
            $loopvars{'delete_link'} = $self->make_link
                (
                 qs_args => {
                     rm  => 'delete_user',
                     uid => $user->uid,
                 }
                 );
        }

        push @user_loop_rows, \%loopvars;
    }
    $tmplvars{'user_loop'} = \@user_loop_rows;
    # ----------------------------------------------------------------


    ### ==================================================================
    ### /end of populating HTML::Template TMPL_VARs
    ### ==================================================================

    return $self->template->fill(\%tmplvars);
}

1; # It's gotta be 1...
