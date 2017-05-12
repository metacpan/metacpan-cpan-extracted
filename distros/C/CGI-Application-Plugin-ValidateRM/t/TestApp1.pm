package TestApp1;

use strict;

use CGI::Application;
@TestApp1::ISA = qw(CGI::Application);

sub setup {
	my $self = shift;

	$self->run_modes([qw/
		form_display
		form_process

        form_display_with_ref
        form_process_with_ref

        form_process_with_fif_opts
	/]);
}

# This is the run mode that will be validated. Notice that it accepts
# some errors to be passed in, and on to the template system.
sub form_display {
	my $self = shift;
	my $errs = shift;

	my $t = $self->load_tmpl('t/01_display.html', die_on_bad_params=>0);

	$t->param($errs) if $errs;
	return $t->output;
}

# This is another run mode that will be validated. Similar, but this one
# returns a reference to the output rather than returning the output itself.
sub form_display_with_ref {
    my $self = shift;
    my $errs = shift;

    my $t = $self->load_tmpl('t/01_display.html',
        die_on_bad_params=>0,
        );

    $t->param($errs) if $errs;
    return \$t->output;
}

sub form_process {
	my $self = shift;

	use CGI::Application::Plugin::ValidateRM;

	my ($results, $err_page) = $self->validate_rm('form_display', '_form_profile' );
	return $err_page if $err_page; 

	return 'success';
}

sub form_process_with_ref {
    my $self = shift;

    my ($results, $err_page) = $self->validate_rm('form_display_with_ref', '_form_profile' );
    return $err_page if $err_page;

    return 'success';
}

sub form_process_with_fif_opts {
    my $self = shift;

    my $results = $self->check_rm('form_display', '_form_profile', { fill_password => 0 }  ) 
        || return $self->dfv_error_page;

    return 'success';
}



sub _form_profile {
	return {
		required => [qw/email phone/],
        optional => [qw/passwd/],
		constraints => {
			email => 'email',
		},
		msgs => { 
			any_errors => 'err__',
			prefix => 'err_',
		},
	};
}


