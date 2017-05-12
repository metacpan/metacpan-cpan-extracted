package CGI::Application::Plugin::SuperForm;
use HTML::SuperForm;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);

@EXPORT = qw(
  &superform
  &sform
);

@EXPORT_OK = qw(
);

$VERSION = '0.5';

sub superform {
	my $c       = shift;
	my $options = shift;

	#
	# Create a superform if needed and cache it for reuse.
	#
	unless ( $c->{__superform} ) {
		$c->{__superform} = HTML::SuperForm->new( $c->query() );

		#
		# Use values in query to populate forms
		#
		$c->{__superform}->sticky(1);

		#
		# If no values found in query then fall back to user defined defaults
		#
		$c->{__superform}->fallback(1);
	}
	return $c->{__superform};
}

# short alias
*sform = \&superform;

1;
__END__

=head1 NAME

CGI::Application::Plugin::SuperForm - Create sticky HTML forms in CGI::Application run modes using HTML::SuperForm

=head1 SYNOPSIS

    use CGI::Application::Plugin::SuperForm;

	sub form_runmode {
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
	        <form>
	        Text Field: $text<br>
	        Text Area: $textarea<br>
	        Select: $select
	        </form>
	    </body>
	    </html>
	END_HTML
		return $output;

	}



=head1 DESCRIPTION

Create sticky forms with C<HTML::SuperForm>.

=head1 METHODS

=over 4

=item sform

alias to superform

=item superform

Returns a instance of C<HTML::SuperForm> preconfigured with sticky and fallback options on.
See L<HTML::SuperForm> for more information and examples.

=back

=head1 EXAMPLE USING TT PLUGIN

A simplistic but working app SuperForm, TT and AutoRunmode plugins.  TT brings in 'c' var to templates automatically, SuperForm brings in 'sform'.

  Files:

    ./lib/MyApp.pm
    .MyApp/form.tmpl
    ./server.pl

  lib/MyApp.pm

		package MyApp;
		use base 'Titanium';

		use CGI::Application::Plugin::TT;
		use CGI::Application::Plugin::SuperForm;
		use CGI::Application::Plugin::AutoRunmode;

		sub form: Runmode{
			my $c = shift;
			$c->tt_process();
		}


		sub process_form(): Runmode{
			my $c = shift;
			# do something with user input.
			# redirect to success page, etc.
			return "You said: ". $c->query()->param('input1');
		}



		1;    # End of MyApp

  MyApp/form.tmpl

	  <html>
		[% c.sform.start_form({method=>"POST"}) %]<br/>
		Say what? [% c.sform.text({name=>"input1"}) %]<br/>
		[% c.sform.hidden({name=>"rm", value=>"process_form"})	%]<br/>
		[% c.sform.submit()%]<br/>
		[% c.sform.end_form() %]<br/>
	  </html>

  .server.pl

		use warnings;
		use strict;
		use CGI::Application::Server;
		use lib 'lib';
		use MyApp;

		my $app = MyApp->new(PARAMS => {});
		my $server = CGI::Application::Server->new();
		$server->document_root('.');
		$server->entry_points({
		    '/index.cgi' => $app,
		});
		$server->run;




=head1 SEE ALSO

L<HTML::SuperForm>, L<Titanium>, L<CGI::Application>.

=head1 AUTHOR

Gordon Van Amburg, C<gordon@minipeg.net>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as perl itself.

=cut
