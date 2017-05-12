use Test::More tests => 6;

use strict;
use warnings;

use_ok( 'CGI' );
use_ok( 'CGI::Form::Table::Reader' );

CONSTRUCT: {
	my $cgi = new CGI;

	my $form = CGI::Form::Table::Reader->new(query => $cgi, prefix => 'whatever');

	ok($form, "form constructor returns something");
	isa_ok($form, 'CGI::Form::Table::Reader');
	can_ok($form, 'rows');
}

BASIC: {
	my $cgi = new CGI;

	my $target = [
		{
			'profile' => 'n+ InGaAs',
			'xmole' => 53.2,
			'dopeconc' => 1e+16,
			'thick' => 7000,
			'dopant' => 'Si'
		},
		{
			'profile' => 'n InGaAs',
			'xmole' => 53.2,
			'dopeconc' => '',
			'thick' => 4000,
			'dopant' => ''
		},
		{
			'profile' => 'p+ InGaAs',
			'xmole' => 53.2,
			'dopeconc' => 4e+19,
			'thick' => 700,
			'dopant' => 'C'
		}
	];

  $cgi->param('struct_1_profile', 'n+ InGaAs');
  $cgi->param('struct_1_xmole',    53.2);
  $cgi->param('struct_1_thick',    7_000);
  $cgi->param('struct_1_dopant',   'Si');
  $cgi->param('struct_1_dopeconc', 1.0e16);
  
  $cgi->param('struct_2_profile', 'n InGaAs');
  $cgi->param('struct_2_xmole',    53.2);
  $cgi->param('struct_2_thick',    4_000);
  $cgi->param('struct_2_dopant',   '');
  $cgi->param('struct_2_dopeconc', '');

  $cgi->param('struct_8_profile', 'p+ InGaAs');
  $cgi->param('struct_8_xmole',    53.2);
  $cgi->param('struct_8_thick',    700);
  $cgi->param('struct_8_dopant',   'C');
  $cgi->param('struct_8_dopeconc', 4.0e19);

	my $form = CGI::Form::Table::Reader->new(query => $cgi, prefix => 'struct');
	my $rows = $form->rows;

	is_deeply($rows, $target, "contents restored correctly");
}
