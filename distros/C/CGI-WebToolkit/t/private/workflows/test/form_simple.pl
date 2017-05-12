my $fields = 
	FormHidden(-name => 'to', -content => 'test.form_simple_process')
	.FormDropdown(
		-label => 'Dropdown Field',
		-options => 
			 FormOption(-title => 'Option Number One')
			.FormOption(-title => 'Option Number Two')
			.FormOption(-title => 'Option Number Three'),
		-info => 'Asdfasdf asd fas dfasdfasdf asdf as df asd fas df asd asdfasdf asd fa sdfasdfasdf asd f asdfasdfasdf.',
	)
	.FormText(		-label => 'Text Field', -content => 'Lorem Ipsum...')
	.FormMultitext(	-label => 'Multiline-Text Field', -content => 'Lorem Ipsum...')
	.FormHidden()
	.FormDate(		-label => 'Date Field', -name => 'my_date_field')
	.FormTime(		-label => 'Time Field', -name => 'my_date_field2')
	.FormDatetime(	-label => 'Date and Time Field', -name => 'my_date_field3')
	.FormFile(		-label => 'File Field', -name => 'attachment')
	.FormMoney(		-label => 'Money Field')
	.FormEmail(		-label => 'Email Field')
	.FormPassword(	-label => 'Password Field<br/> (insert twice)')
	.FormColor(		-label => 'Color Field')
	.FormSlider(	-label => 'Slider Field', -name => 'my_slider_field')
	.FormCheckboxes(
		-label => 'Checkboxes Field',
		-content =>
			 FormCheckbox(-label => 'Asdfasdf asd fas dfasdfasdf asdf as df asd fas df asd asdfasdf asd fa sdfasdfasdf asd f asdfasdfasdf.')
			.FormCheckbox(-label => 'Checkbox Two')
			.FormCheckbox(-label => 'Checkbox Three'),
	)
	.FormSwitches(
		-label => 'Switches Field',
		-content =>
			 FormSwitch(-label => 'Switch One')
			.FormSwitch(-label => 'Switch Two')
			.FormSwitch(-label => 'Switch Three'),
	)
	.FormButtons();

my $html =
	 Headline(-content => 'Simple Form inside Box')
	.Form(
		-name => 'my_form',
		-action => '{script_url}',
		-content =>
			$fields
			#.fill('fieldset', {'elements' => $fields})
	);

my $page =
	Core_Page(
		-content =>
			Box(
				-top => 'Oben',
				-content => $html,
				-bottom => 'Unten',
			),
	);

$page .= Headline(-content => 'Grids');

$page .=
	Grid(
		-widths => '10% [35%] 10% [35%] 10%',
		-class => 'boxed',
		-columns => [
			'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
			'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
		],
	);

$page .=
	Grid(
		-widths => '10 [100] 10 [120] 20 [130] 30',
		-columns => [
			'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
			'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
			'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
		],
	);

return output(1, 'ok', $page);
