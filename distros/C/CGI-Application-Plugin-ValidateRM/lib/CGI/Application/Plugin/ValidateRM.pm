package CGI::Application::Plugin::ValidateRM;
use base ('Exporter','AutoLoader');
use HTML::FillInForm;
use Data::FormValidator;
use strict;

our @EXPORT = qw(
    &dfv_results
    &dfv_error_page
    &check_rm_error_page
	&check_rm
	&validate_rm
);

our $VERSION = '2.52';

sub check_rm {
     my $self = shift;
	 my $return_rm = shift || die 'missing required return run mode';
     my $profile_in = shift || die 'missing required profile';
     my $fif_params = shift || {};

	# If the profile is not a hash reference,
	# assume it's a CGI::App method
	my $profile;
	if (ref $profile_in eq 'HASH') {
		$profile = $profile_in;
	}
	else {
        if ($self->can($profile_in)) {
            $profile = $self->$profile_in();
        }
        else {
            $profile = eval { $self->$profile_in() };
            die "Error running profile method '$profile_in': $@" if $@;
        }

	}

     my $dfv = Data::FormValidator->new({}, $self->param('dfv_defaults') );
	 my $r =$dfv->check($self->query,$profile);
     $self->{'__DFV_RESULT'} = $r;

     # Pass the params through the object so the user
     # can just call dfv_error_page() later
     $self->{'__DFV_RETURN_RM'}  = $return_rm;
     $self->{'__DFV_FIF_PARAMS'} = $fif_params;

     if (wantarray) {
         # We have to call the function non-traditionally to achieve mix-in happiness.
         return $r, dfv_error_page($self);
     }
     else {
         return $r;
     }
}

sub dfv_results {
    my $self = shift;
    die "must call check_rm() or validate_rm() first." unless defined $self->{'__DFV_RESULT'};
    return $self->{'__DFV_RESULT'};
}

sub validate_rm {
	my $self = shift;
	my ($r,$err_page) = $self->check_rm(@_);
	return (scalar $r->valid,$err_page);
}

sub dfv_error_page {
    my $self = shift;
    my $r          = $self->{'__DFV_RESULT'};
    my $return_rm  = $self->{'__DFV_RETURN_RM'};
    my $fif_params = $self->param('dfv_fif_defaults') || {};

    # merge the defaults with the ones given for this fill
    $fif_params = {%$fif_params, %{$self->{'__DFV_FIF_PARAMS'}}};

    my $err_page = undef;
    if ($r->has_missing or $r->has_invalid) {
        # If ::Forward has been loaded, act like forward()
        my $before_rm = $self->{__CURRENT_RUNMODE};
        $self->{__CURRENT_RUNMODE} = $return_rm if ($INC{'CGI/Application/Plugin/Forward.pm'});

        my $return_page = $self->$return_rm($r->msgs);

        $self->{__CURRENT_RUNMODE} =  $before_rm;

        my $return_pageref = (ref($return_page) eq 'SCALAR')
            ? $return_page : \$return_page;

        my $fif_class = $self->param('dfv_fif_class') || 'HTML::FillInForm';
        eval { require $fif_class };
        # Deliberately do _not_ check if the eval succeeded,
        # since $fif_class might be an inlined class not to be found in @INC.
        my $fif = $fif_class->new();
        $err_page = $fif->fill(
            scalarref => $return_pageref,
            fobject => $self->query,
            %$fif_params,
        );
    }
    return $err_page;
}

*check_rm_error_page = \&dfv_error_page;
my $avoid_warning = \&check_rm_error_page;

1;
__END__

=head1 NAME

CGI::Application::Plugin::ValidateRM - Help validate CGI::Application run modes using Data::FormValidator

=head1 SYNOPSIS

 use CGI::Application::Plugin::ValidateRM;

 my  $results = $self->check_rm('form_display','_form_profile') || return $self->check_rm_error_page;


 # Optionally, you can pass additional options to HTML::FillInForm->fill()
 my $results = $self->check_rm('form_display','_form_profile', { fill_password => 0 })
        || return $self->check_rm_error_page;

=head1 DESCRIPTION

CGI::Application::Plugin::ValidateRM helps to validate web forms when using the
CGI::Application framework and the Data::FormValidator module.

=head2 check_rm()

Validates a form displayed in a run mode with a C<Data::FormValidator> profile, returning
the results and possibly an a version of the form page with errors marked on the page.

In scalar context, it returns simply the Data::FormValidator::Results object
which conveniently evaluates to false in a boolean context if there were any missing
or invalid fields. This is the recommended calling convention.

In list context, it returns the results object followed by the error page, if any.
This was the previous recommended syntax, and was used like this:

 my ($results,$err_page) = $self->check_rm('form_display','_form_profile');
 return $err_page if $err_page;

The inputs are as follows:

=over

=item Return run mode

This run mode will be used to generate an error page, with the form re-filled
(using L<HTML::FillInForm>) and error messages in the form. This page will be
returned as a second output parameter.

The errors will be passed in as a hash reference, which can then be handed to a
templating system for display. Following the above example, the form_display() routine might look like:

 sub form_display {
    my $self = shift;
    my $errs = shift;                             # <-- prepared for form reloading
    my $t = $self->load_tmpl('form_display.html');
    $t->param($errs) if $errs;                    # <-- Also necessary.
    # ...

 }

The fields should be prepared using Data::FormValidator's
built-in support for returning error messages as a hash reference.
See the documentation for C<msgs> in the L<Data::FormValidator::Results>
documentation.

Returning the errors with a prefix, such as "err_" is recommended. Using
C<any_errors> is also recommended to make it easy to display a general "we have
some errors" message.

HTML::Template users may want to pass C<die_on_bad_params=E<gt>0> to the
HTML::Template constructor to prevent the presence of the "err_" tokens from
triggering an error when the errors are I<not> being displayed.

=item Data::FormValidator profile

This can either be provided as a hash reference, or as the name
of a CGI::Application method that will return such a hash reference.

=item HTML::FillInForm options (optional)

If desired, you can pass additional options to the L<HTML::FillInForm>
L<fill()|HTML::FillInForm/fill> method through a hash reference.
See an example above.

=back

=head3 Additional Options

To control things even more, you can set parameters in your L<CGI::Application>
object itself.

=over 

=item dfv_defaults

The value of the 'dfv_defaults' param is optionally used to pass defaults to the 
L<Data::FormValidator> L<new()|Data::FormValidator/new()> constructor.

  $self->param(dfv_defaults => { filters => ['trim'] })

By setting this to a hash reference of defaults in your C<cgiapp_init> routine
in your own super-class, you could make it easy to share some default settings for
Data::FormValidator across several forms. Of course, you could also set parameter
through an instance script via the PARAMS key.

Here's an example that I've used:

 sub cgiapp_init {
     my $self = shift;

     # Set some defaults for DFV unless they already exist.
     $self->param('dfv_defaults') ||
         $self->param('dfv_defaults', {
                 missing_optional_valid => 1,
                 filters => 'trim',
                 msgs => {
                     any_errors => 'err__',
                     prefix     => 'err_',
                     invalid    => 'Invalid',
                     missing    => 'Missing',
                     format => '<span class="dfv-errors">%s</span>',
                 },
             });
 }

Now all my applications that inherit from a super class with this
C<cgiapp_init()> routine and have these defaults, so I don't have
to add them to every profile.

=item dfv_fif_class

By default this plugin uses L<HTML::FillInForm> to fill in the forms
on the error pages with the given values. This option let's you change
that so it uses an L<HTML::FillInForm> compatible class (like a subclass) 
to do the same work.

    $self->param(dfv_fif_class => 'HTML::FillInForm::SuperDuper');

=item dfv_fif_defaults

The value of the 'dfv_fif_defaults' param is optionally used to pass defaults to the 
L<HTML::FillInForm> C<fill()> method.

    $self->param(dfv_fif_defaults => {ignore_fields => ['rm']})

By setting this to a hash reference of defaults in your C<cgiapp_init> routine
in your own super-class, you could make it easy to share some default settings for
L<HTML::FillInForm> across several forms. Of course, you could also set parameter
through an instance script via the PARAMS key.

=back

=head2 CGI::Application::Plugin::Forward support

Experimental support has been added for CGI::Application::Plugin::Forward,
which keeps the current run mode up to date. This would be useful if you
were automatically generating a template name based on the run mode name,
and you wanted this to work with the form run mode used with ::ValidateRM.

If we detect that ::Forward is loaded, we will set the current run mode name to
be accurate while the error page is being generated, and then set it back to
the previous value afterwards. There is a caveat: This currently only works
when the run mode name is the same as the subroutine name for the form page.
If they differ, the current run mode name inside of the form page will be
inaccurate. If this is a problem for you, get in touch to discuss a solution.

=head2 check_rm_error_page()

After check_rm() is called this accessor method can be used to retrieve the
error page described in the check_rm() docs above. The method has an alias
named C<dfv_error_page()> if you find that more intuitive.

=head2 dfv_results()

 $self->dfv_results;

After C<check_rm()> or C<validate_rm()> has been called, the DFV results object
can also be accessed through this method. I expect this to be most useful to
other plugin authors.

=head2 validate_rm()

Works like C<check_rm> above, but returns the old style C<$valid> hash
reference instead of the results object. It's no longer recommended, but still
supported.

=head1 EXAMPLE

In a CGI::Application module:

 # This is the run mode that will be validated. Notice that it accepts
 # some errors to be passed in, and on to the template system.
 sub form_display {
 	my $self = shift;
 	my $errs = shift;

 	my $t = $self->load_tmpl('page.html');

 	$t->param($errs) if $errs;
 	return $t->output;
 }

 sub form_process {
 	my $self = shift;

 	use CGI::Application::Plugin::ValidateRM (qw/check_rm/);
 	my ($results, $err_page) = $self->check_rm('form_display','_form_profile');
 	return $err_page if $err_page;

	#..  do something with DFV $results object now

 	my $t = $self->load_tmpl('success.html');
 	return $t->output;

 }

 sub _form_profile {
 	return {
 		required => 'email',
		msgs => {
			any_errors => 'some_errors',
			prefix => 'err_',
		},
 	};
 }

In page.html:

 <!-- tmpl_if some_errors -->
 	<h3>Some fields below are missing or invalid</h3>
 <!-- /tmpl_if -->
 <form>
 	<input type="text" name="email"> <!-- tmpl_var err_email -->
 </form>


=head1 SEE ALSO

L<CGI::Application>, L<Data::FormValidator>, L<HTML::FillInForm>, perl(1)

=head1 AUTHOR

Mark Stosberg <mark@summersault.com>

=head1 MAILING LIST

If you have any questions, comments, bug reports or feature suggestions,
post them to the support mailing list! This the Data::FormValidator list.
To join the mailing list, visit L<http://lists.sourceforge.net/lists/listinfo/cascade-dataform>

=head1 LICENSE

Copyright (C) 2003-2005 Mark Stosberg <mark@summersault.com>

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,

or

b) the "Artistic License"

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

For a copy of the GNU General Public License along with this program; if not,
write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA


=cut

