# Session.pm
#
# $Id: Session.pm,v 1.6 2005/01/27 21:32:49 rsandberg Exp $
#

package CGI::AutoForm::Session;

use strict;
use CGI::AutoForm;


=head1 NAME

CGI::AutoForm::Session - Stateful CGI sessions

=head1 SYNOPSIS

 
 use CGI::AutoForm::Session;


 $session = new CGI::AutoForm::Session($query,[$user],[$dbh]);

 $form = $session->next_form();

 $form = $session->restart();

 $form = $session->jump_form();

 $form = $session->repeat_form();

 $form = $session->summary_form();

 $status = $session->status();

 $normalized_query = $session->query();

 $bool = $session->invalid_input();


=head2 Attribute Accessors/Modifiers

Get the values of these READ-ONLY attributes.

 $query         = $session->query();

Get or set the values of these attributes.

 $dbh           = $session->dbh();
 $user          = $session->user();

=head1 DESCRIPTION

A virtual base class to help implement a CGI session
across HTTP requests.

The basic idea is to define a
set of forms using CGI::AutoForm, and cache them if desired
(e.g. if using mod_perl). You then define a sequence that
the forms will appear in the session depending on form names,
user input, etc. Your CGI program propagates the session, form by form (by calling $session->next_form())
and user input is automatically verified at each stage according to the constraints
you define with CGI::AutoForm. If a validation error occurs, the form is immediately presented again.
At the end of the session, you have the option
of presenting a summary screen where the user can confirm, edit
or cancel the session. Editing previous input is allowed by jumping back to
a previous form, yet all user input remains intact
throughout the session.

Refer to CGI::AutoForm throughout this documentation.


=head1 DETAILS

This class relies on HIDDEN HTML form elements for persistence;
why not something more sophisticated like IPC so that objects
don't have to be reinstantiated? (e.g. PHP)
Because with IPC you have to concern yourself with
memory contraints from a heavily loaded web site
or possible memory leaks from (perhaps rare) aberrant signals.
HIDDEN form elements don't add or remove security concerns;
a CGI session can only be as secure as
the HTTP protocol that underlies it. If security is an issue, use
HTTPS or equivalent and be consistent for the duration of the session.

A disadvantage of this approach is that data passed back and forth
via HIDDEN fields need to be re-validated, but this should be done
with the final summary form in any case.

Enough blabber!

=head2 Subclassing

You implement a session by subclassing this module.
The following methods are expected to be overridden:

=over 4

=item C<_init>

 $success = $session->_init();

This is called during construction and allows any
class-specific initialization to occur (you can also override new() and chain up). With mod_perl
I like to use this method to create all my forms and cache
them when the very first object is created (of course, if any
definitions of the form change in the database, I have to restart apache).
Always give the form name to the contructor of form objects.

Only the form structure should ever be cached; form
objects should be void of any user-specific data. By using/overriding
next_form() and/or fetch_form() you can effectively cache forms and alter their
structure or content during session runtime. An important distinction
is made here between form structure and session-specific forms which
may be customized according to user input or have user content. For security reasons, user input should
never be cached with this class.

=item C<assign_forms>

 $success = $session->assign_forms();

If you are caching forms, the {forms} attribute must be assigned in this
method. It will be a hashref of form_name => $form object
pairs. All cached forms must be assigned a name.
If you are not caching forms, or if your forms are created completely on-the-fly,
you must override fetch_form(). See _init for a discussion of form caching.


=item C<_next_form>

 $form = $session->_next_form();

Not to be confused with next_form()
This is where you direct the session by returning a form object
according to a sequence of forms you define along with current and previous
session information in state machine fashion. A few conventions are available to help guide you.

query() returns the web server response query string structured in a form acceptable to CGI::AutoForm::prepare()
which was passed in during construction.
See also CGI::AutoForm::format_query() for an even more useful structure.

recent_form_name() - this will return the most recently submitted form name.

start_form_name() - returns the name of the form that was first used in this
session. In order for this to work this method should be called when the
start form is first returned from _next_form() e.g., include this line somewhere
in your subclass:

$self->start_form_name($this_is_the_first_form_of_this_session);

Note that recent_form_name() and start_form_name() use the name
of your subclass as a unique identifier in the unlikely event that 2 or more sessions happen to
bleed into each other. It does this in a case-insensitive manner and may cause problems if 2 classes have the same
name that differ only by case.

=item C<verify_callback>

 $sub = $session->verify_callback();

This will be called during query validation (C<invalid_input>) and the
return value (if not undef()) must be a reference to a subroutine (callback)
that will be passed to CGI::AutoForm::validate_query().

=head1 METHODS


=item C<new> (constructor)

 $session = new CGI::AutoForm::Session($query,[$user],[$dbh]);

Create a new session object with a structured query string (see C<CGI::AutoForm::prepare> for the structure), and optional:
$user - a username for restricted forms and $dbh - a valid database handle.

$query is immediately passed through CGI::AutoForm::normalize_query().
$user and $dbh may be convenient for subclasses.

Return undef if error.

=cut
sub new
{
    my ($caller,$query,$user,$dbh) = @_;
    my $class = ref($caller) || $caller;
    my $nq = CGI::AutoForm->normalize_query($query) if $query;
    my $self = bless({
        dbh     => $dbh,
        query   => $nq,
        user    => $user,
    },$class);

    $self->_init() || (warn("Initialization failed"),return undef);
    $self->assign_forms();
    return $self;
}

=pod

=item C<status>

 $status = $session->status([$status]);

To advise your CGI program (or mod_perl handler) the following default status indicators apply
to the form returned from next_form(). You can override them as appropriate.

'CONTINUE' - The form is a continuation in a sequence of forms.

'REPEAT' - The form is a repeat of the previous form (most likely
because it had user input validation errors).

'JUMP' - See set by calling jump_form().

'SUMMARY' - A summary of all previous forms in the session.

=cut
sub status
{
    my ($self) = @_;
    return $self->{status};
}

sub _init
{
    return 1;
}

sub _next_form
{
    0;
}

sub initialized
{
    return 1;
}

sub assign_forms
{
    my ($self) = @_;
    return $self->{forms} = {};
}

sub verify_callback
{
    my ($self) = @_;
    return undef;
}

=pod

=item C<query>

 $normalized_query = $session->query();

Return a normalized form of $query passed to the
constructor. (See CGI::AutoForm::normalize_query())

=cut
sub query
{
    my ($self) = @_;
    return $self->{query};
}

sub user
{
    my ($self,$user) = @_;
    if (defined($user))
    {
        $self->{user} = $user;
    }
    return $self->{user};
}

sub dbh
{
    my ($self,$dbh) = @_;
    if (defined($dbh))
    {
        $self->{dbh} = $dbh;
    }
    return $self->{dbh};
}

=pod

=item C<invalid_input>

 $bool = $session->invalid_input();

Validates user input via CGI::AutoForm::validate_query().
May return the same form if the input elements can't be verified with VALID_ERROR attrs set for each field in error.
Otherwise, return false if validation was successful.

=cut
sub invalid_input
{
    my ($self) = @_;
    my $query = $self->query();
    my $form = $self->fetch_form($self->recent_form_name()) || return 0; # No form to validate against
    unless ($form->validate_query($query,$self->verify_callback()))
    {
        return $form;
    }
    return 0;
}

=pod

=item C<next_form>

 $form = $session->next_form();

Validates current form submission using the query structure given in the constructor (if any).
May return the same form if the input elements can't be verified with VALID_ERROR attrs set for each field in error.
Otherwise the next form in the session is returned.

Refer to CGI::AutoForm for usage of $form.

=cut
sub next_form
{
    my $self = shift;
    my $form;
    if ($form = $self->invalid_input())
    {
##at const,const,const
        $self->{status} = 'REPEAT';
    }
    else
    {
        $form = $self->_next_form(@_) || return undef;
##at const,const,const
        $self->{status} = 'CONTINUE' unless defined($self->{status});
    }
    return $self->export_form($form);
}

sub fen_prefix
{
    my $self = shift;
    my $class = uc(ref($self));
    $class =~ s/\:\:/_/g;
##at table/group names cannot be named __SSDAT this is a reserved group name!!
    return "__SSDAT.$class";
}

sub export_form
{
    my ($self,$form) = @_;
    my $query = $self->query();
    my $i = 1;
    my $form_exists;
    my $name = $form->name();
    my $fen_pre = $self->fen_prefix();
    while (exists($query->{"$fen_pre.FORM$i"}))
    {
        $form_exists && (delete($query->{"$fen_pre.FORM$i"}),next);
        $form_exists++ if $query->{"$fen_pre.FORM$i"} eq $name;
    }
    continue
    {
        $i++;
    }
    $query->{"$fen_pre.FORM$i"} = $name unless $form_exists;
    $self->recent_form_name($form);
    #$form->prepare($query);
    $self->{form} = $form;
    return $form;
}

# have a property of fields be cacheable and cache a record only if ALL fields are cacheable
# actually, in general only search forms should never be cached
##at user_masks should be unique

=pod

=item C<restart>

 $form = $session->restart();

Return the very first form of this session with all user input intact.

=cut
sub restart
{
    my ($self) = @_;
    my $form = $self->fetch_form($self->start_form_name());
    $self->{status} = 'CONTINUE';
    return $self->export_form($form);
}

=pod

=item C<jump_form>

 $form = $session->jump_form();

Jump back to a form previously encountered in this session with all user input intact.

=cut
sub jump_form
{
    my ($self,$form_name) = @_;
    my $form = $self->fetch_form($form_name);
##at const,const,const
    $self->{status} = 'JUMP';
    return $self->export_form($form);
}

=pod

=item C<repeat_form>

 $form = $session->repeat_form();

Return the most recently submitted form with all user input intact.

=cut
sub repeat_form
{
    my ($self) = @_;
    my $form = $self->fetch_form($self->recent_form_name());
##at const,const,const
    $self->{status} = 'REPEAT';
    return $self->export_form($form);
}

=pod

=item C<fetch_form>

  $form = $session->fetch_form($form_name);

Return the $form object indentified with $form_name.

=cut
sub fetch_form
{
    my ($self,$form_name) = @_;
    my $form = $self->{forms}{$form_name} || return undef;
    return $form->clone($self->dbh(),$form_name);
}

sub start_form_no
{
    my ($self) = @_;
    my $query = $self->query();
    my $i = 1;
    my $start_name = $self->start_form_name();
    my $fen_pre = $self->fen_prefix();
    while (exists($query->{"$fen_pre.FORM$i"}))
    {
        return $i if $query->{"$fen_pre.FORM$i"} eq $start_name;
        $i++;
    }
    return undef;
}

=pod

=item C<prepare_form>

  $form = $session->prepare_form($form);

Call the C<prepare> method on $form passing in
$session->{query}.

=cut
sub prepare_form
{
    my ($self,$form) = @_;
    return $form->prepare($self->{query});
}

sub start_form_name
{
    my ($self,$form) = @_;
    my $fen_pre = $self->fen_prefix();
    my $form_key = "$fen_pre._SESSION_START";
    if (defined($form))
    {
        return ($self->{query}{$form_key} = $form->name());
    }
    return $self->{query}{$form_key};
}

sub recent_form_name
{
    my ($self,$form) = @_;
    my $fen_pre = $self->fen_prefix();
    my $form_key = "$fen_pre._CURRENT_FORM";
    if (defined($form))
    {
        return ($self->{query}{$form_key} = $form->name());
    }
    return $self->{query}{$form_key};
}

=pod

=item C<summary_form>

 $form = $session->summary_form();

Return a form that contains all data groups of every form
submitted in this session. This could be lengthy so you may want to
customize the default layout of CGI::AutoForm.

The form data will be readonly but all data will be available on submission
through hidden fields. Typically the user will have the chance to reject
the data and the session would continue at the beginning by calling restart().

NOTE: Data from the summary form should be re-validated.

=cut
sub summary_form
{
    my ($self) = @_;
    my $query = $self->query();
    my $i = $self->start_form_no() || (warn("No start to this session?!?"),return undef);
    my $form = new CGI::AutoForm(undef,'SUMMARY');
    $form->readonly(1);
    my $fen_pre = $self->fen_prefix();
    while (exists($query->{"$fen_pre.FORM$i"}))
    {
        next if $query->{"$fen_pre.FORM$i"} eq 'SUMMARY';
        my $sub_form = $self->fetch_form($query->{"$fen_pre.FORM$i"});
        foreach my $gr (@{$sub_form->{group_list}})
        {
            $form->push_group($gr);
        }
    }
    continue
    {
        $i++;
    }
    $self->{status} = 'SUMMARY';
    return $form;
}

1;

__END__

=head1 BUGS

No known bugs.

=head1 SEE ALSO

L<CGI::AutoForm>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2007 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

