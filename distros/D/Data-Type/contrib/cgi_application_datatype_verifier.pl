#!perl

# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself

use strict;

use lib 'lib';

use CGI::Application;

use IO::Extended qw(:all);

use Error qw(:try);

our $VERSION = '0.02';

{
	package CApp::Data::Validator;

	use Error qw(:try);

	use Data::Type qw(:all);

	$Data::Type::DEBUG = 0;

	our @ISA = qw(CGI::Application);

	sub setup
	{
		my $this = shift;

			$this->start_mode('list');

			$this->mode_param('runmode');

			$this->run_modes(

				list => 'list_types',

				valid => 'valid_type',

				info => 'perl_info',
			);

			$this->tmpl_path( 'Templates/CGIApp/Data/Validator/' );

			#$self->param( 'myprop1' );
			#$self->param( myprop2 => 'prop2value' );
			#$self->param( myprop3  => ['p3v1', 'p3v2', 'p3v3'] );
	}

	sub cgiapp_prerun
	{
		my $this = shift;

		my $cgi = $this->query;

		my $data = $cgi->param('data');

		my $type = uc $cgi->param('type');

		my @args = $cgi->param('args');

			$this->prerun_mode('valid') if defined $data && defined $type;
	}

	sub teardown
	{
		my $this = shift;
	}

	sub list_types : method
	{
		my $this = shift;

			#my $tmpl = $this->load_tmpl( 'catalog.tmpl', die_on_bad_params => 0, cache => 1 );

			my $output;

			my $types = catalog();

			foreach my $name ( keys %$types )
			{
				$output .= sprintf "  %-18s - %s\n", uc $name, $types->{$name};
			}

		return $output; #$this->query->start_html( -title => 'Valid Data' ).$output.$this->query->end_html();
	}

	sub valid_type : method
	{
		my $this = shift;

		my $cgi = $this->query();

		my $data = $cgi->param('data');

		my $type = uc $cgi->param('type');

		my @args = $cgi->param('args');

		my $result;

		my $output = "Valid '$data' as type $type with args @args";

			try
			{
				no strict 'refs';

				valid( $data, "$type"->( @args ) );

				$output .= 'was successfull';
			}
			catch Type::Exception with
			{
				my $e = shift;

				$output .= 'failed';

				$output .= sprintf "\nException '%s' caught<br>", ref $e;

				$output .= sprintf "\nExpected '%s' %s at %s line %s<br>", $e->value, $e->type->info, $e->was_file, $e->was_line;
			};

		return $output; #$this->query->start_html( -title => 'Valid Data' ).$output.$this->query->end_html();
	}

	sub perl_info
	{
		return '<xmp>'.qx{pwd}."\n".qx{perl -V}.'</xmp>';
	}
}

	my $webapp = CApp::Data::Validator->new();

	$webapp->run();
