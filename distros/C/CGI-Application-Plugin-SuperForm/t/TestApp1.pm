package TestApp1;

use strict;

use CGI::Application;
@TestApp1::ISA = qw(CGI::Application);
use CGI::Application::Plugin::SuperForm;

sub setup {
	my $self = shift;

	$self->run_modes(
		[
			qw/
			  test_form test_form_not_sticky
			  /
		]
	);
}

sub test_form {
	my $c = shift;

	my $form_start = $c->superform->start_form(
		{
			method => "POST",
			action => $c->query()->url() . "/myapp/form_process",
		}
	);

	my $text = $c->superform->text( name => 'text', default => 'Default Text' );

	my $textarea = $c->superform->textarea(
		name    => 'textarea',
		default => 'More Default Text'
	);

	my $select = $c->superform->select(
		name    => 'select',
		default => 2,
		values  => [ 0, 1, 2, 3 ],
		labels  => {
			0 => 'Zero',
			1 => 'One',
			2 => 'Two',
			3 => 'Three'
		}
	);

	my $output = <<"END_HTML";
	    <html>
	    <body>
	        $form_start <br>
	        Text Field: $text<br>
	        Text Area: $textarea<br>
	        Select: $select
	        </form>
	    </body>
	    </html>
END_HTML
	return $output;

}

sub test_form_not_sticky {
	my $c = shift;

	# turn off sticky
	$c->superform( { sticky => 0 } );

	my $form_start = $c->superform->start_form(
		{
			method => "POST",
			action => $c->query()->url() . "/myapp/form_process",
		}
	);

	my $text = $c->superform->text( name => 'text', default => 'Default Text' );

	my $textarea = $c->superform->textarea(
		name    => 'textarea',
		default => 'More Default Text'
	);

	my $select = $c->superform->select(
		name    => 'select',
		default => 2,
		values  => [ 0, 1, 2, 3 ],
		labels  => {
			0 => 'Zero',
			1 => 'One',
			2 => 'Two',
			3 => 'Three'
		}
	);

	my $output = <<"END_HTML";
	    <html>
	    <body>
	        $form_start <br>
	        Text Field: $text<br>
	        Text Area: $textarea<br>
	        Select: $select
	        </form>
	    </body>
	    </html>
END_HTML
	return $output;
}

1;
