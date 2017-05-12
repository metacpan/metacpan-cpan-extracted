package Catalyst::Plugin::FillInForm;

use strict;
use MRO::Compat;
use HTML::FillInForm;

our $VERSION = '0.12';

=head1 NAME

Catalyst::Plugin::FillInForm - FillInForm for Catalyst

=head1 SYNOPSIS

    use Catalyst 'FillInForm'; 
    # that's it, if Catalyst::Plugin::FormValidator is being used

    # OR, manually:

    # in Controller/Root.pm; assume $c->stash->data is seeded elsewhere
    sub end : Private {
      my ( $self, $c ) = @_;
      $c->forward('MyApp::View::TT') unless $c->res->output;
      $c->fillform( $c->stash->data );
      # ....

=head1 DESCRIPTION

Fill forms automatically, based on data from a previous HTML
form. Typically (but not necessarily) used in conjunction with
L<Catalyst::Plugin::FormValidator>. This module automatically
inserts data from a previous HTML form into HTML input fields,
textarea fields, radio buttons, checkboxes, and select
tags. It is an instance of L<HTML::FillInForm>, which itself
is a subclass of L<HTML::Parser>, which it uses to parse the
HTML and insert the values into the proper form tags.

The usual application is after a user submits an HTML form
without filling out a required field, or with errors in fields
having specified constraints. FillInForm is used to
redisplay the HTML form with all the form elements containing
the submitted info. FillInForm can also be used to fill forms
with data from any source, e.g. directly from your database.

=head2 EXTENDED METHODS

=head3 finalize

Will automatically fill in forms, based on the parameters in
C<$c-E<gt>req-E<gt>parameters>, if the last form has missing
or invalid fields, and if C<Catalyst::Plugin::FormValidator>
is being used. C<finalize> is called automatically by the
Catalyst Engine; the end user will not have to call it
directly. (In fact, it should never be called directly by the
end user.)

=cut

sub finalize {
    my $c = shift;
    if ( $c->isa('Catalyst::Plugin::FormValidator') ) {
        $c->fillform
          if $c->form->has_missing
          || $c->form->has_invalid
          || $c->stash->{error};
    }
    return $c->maybe::next::method(@_);
}

=head2 METHODS

=head3 fillform

Fill a form, based on request parameters (the default) or any
other specified data hash. You would call this manually if
you're getting your data from some source other than the
parameters (e.g. if you're seeding an edit form with the
results of a database query), or if you're using some other
validation system than C<Catalyst::Plugin::FormValidator>.

    $c->fillform; # defaults to $c->req->parameters

    # OR

    $c->fillform( \%data_hash );

C<fillform> must be called after an HTML template has been
rendered. A typical way of using it is to place it immediately
after your C<forward> call to your view class, which might be
in a built-in C<end> action in your application class.

You can also hand in a hashref of additional params for
HTML::FillInForm->fill() if you like.  Explicitly providing a
\%data_hash is mandatory for this use case.

    $c->fillform( $c->req->parameters, {
       ignore_fields => [ 'pagesrc', 'pagedst' ],
       fill_password => 0,
    } );

=cut

sub fillform {
    my $c    = shift;
    my $fdat = shift || $c->request->parameters;
    my $additional_params = shift;

    # For whatever reason your response body is empty. So this fillform() will
    # accomplish nothing. Skip HTML::FillInForm to avoid annoying warnings downstream. 
    return 1 unless ($c->response->{body});

    $c->response->output(
        HTML::FillInForm->new->fill(
            scalarref => \$c->response->{body},
            fdat      => $fdat,
            %$additional_params,
        ) || ''
    );
}

=head1 NOTES

This class does not play well with Catalyst's ActionClass('RenderView')
so you may want to check your C<end> method (in Controller/Root.pm or perhaps
MyApp.pm). If it looks like this:

     sub end : ActionClass('RenderView') {}

Then you'll need to change it to something like this:

     sub end : Private {
        my ($self, $c) = @_;
        $c->forward('render');
        $c->fillform($c->req->params) unless $c->res->output;
     }

     sub render : ActionClass('RenderView') { }

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::FormValidator>, L<HTML::FillInForm>, L<Catalyst::Action::RenderView>.

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>
Marcus Ramberg, C<mramberg@cpan.org>
Jesse Sheidlower, C<jester@panix.com>
Jay Hannah, C<jay@jays.net>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
