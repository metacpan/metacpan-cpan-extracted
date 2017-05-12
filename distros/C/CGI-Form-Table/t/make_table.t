use Test::More tests => 13;

use strict;
use warnings;

# these tests are wholly inadequate

use_ok( 'CGI::Form::Table' );

# simplest case
{
	my $form = CGI::Form::Table->new(
		prefix  => 'whatever',
		columns => [qw(profile xmole dopeconc thick dopant)]
	);

	ok($form->as_html,    "got some output");
	ok($form->javascript, "got some output");
}

# with initial_rows
{
	my $form = CGI::Form::Table->new(
		prefix  => 'whatever',
		columns => [qw(profile xmole dopeconc thick dopant)],
		initial_rows => 10
	);

	ok($form->as_html,    "got some output");
	ok($form->javascript, "got some output");
}

# with column_content
{
	my $form = CGI::Form::Table->new(
		prefix  => 'whatever',
		columns => [qw(profile xmole dopeconc thick dopant)],
		column_content => {
			xmole  => sub { 'disabled' },
			dopant => CGI::Form::Table->_select([[ A => 'Alpha' ], [B => 'Beta' ]])
		}
	);

	ok($form->as_html,    "got some output");
	ok($form->javascript, "got some output");
}

# with column_header
{
	my $form = CGI::Form::Table->new(
		prefix  => 'whatever',
		columns => [qw(profile xmole dopeconc thick dopant)],
		column_header => { xmole  => 'x mole fraction' }
	);

	ok($form->as_html,    "got some output");
	ok($form->javascript, "got some output");
}

# with initial_values
{
	my $form = CGI::Form::Table->new(
		prefix  => 'whatever',
		columns => [qw(profile xmole dopeconc thick dopant)],
		initial_values => [
			{ profile => 'PB',      thick => 500, dopant => 'chocolate' },
			{ profile => 'Nutella', thick => 500, },
		]
	);

	ok($form->as_html,    "got some output");
	ok($form->javascript, "got some output");
}

# complex!
# initial_rows > initial_values
# column_header, column_values
{
	my $form = CGI::Form::Table->new(
		prefix  => 'whatever',
		columns => [qw(profile xmole dopeconc thick dopant)],
		column_header  => { profile => 'ingredient' },
		column_content => {
			profile => CGI::Form::Table->_select([
				[ '' => 'nothing' ],
				[ PB => 'PB' ],
				[ Nutella => 'Nutella' ],
				[ Tahini => 'Tahini' ]
			]),
			thick => CGI::Form::Table->_input({type => 'slider'})
		},
		initial_rows   => 4,
		initial_values => [
			{ profile => 'PB',      thick => 500, dopant => 'chocolate' },
			{ },
			{ profile => 'Nutella', thick => 500, },
		]
	);

	ok($form->as_html,    "got some output");
	ok($form->javascript, "got some output");
}
