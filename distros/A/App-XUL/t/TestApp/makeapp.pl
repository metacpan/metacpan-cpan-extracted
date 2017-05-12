#!/usr/bin/perl -w

use strict;
use lib '../../lib';
use App::XUL;

my $app = App::XUL->new(name => 'TestApp');
  
$app->add(
	Window(id => 'main',
		Vbox(flex => "1", align => "stretch", id => "box",
			Hbox(id => 'hbox1',
				Button(label => 'numchildren', oncommand => sub {
					ID('textbox1')->value("hbox1 has ".ID('hbox1')->numchildren()." children");
				}),
				Button(label => 'child(1)', oncommand => sub {
					ID('textbox1')->value("child 1 of hbox1 is ".ID('hbox1')->child(1)->id());
				}),
				Button(label => 'insert', oncommand => sub {
					ID('hbox2')->insert(Textbox());
				}),
				Button(label => 'update', oncommand => sub {
					ID('hbox2')->update(Button(label => 'Heyho!'), Button(label => 'Jojo'));
				}),
				Button(label => 'remove', oncommand => sub {
					ID('hbox2')->child(0)->remove();
				}),
			),
			Hbox(id => 'hbox2',
				Textbox(),
			),
			Hbox(
				Button(id => "btnQuit", sizeToContent => "1", label => "Quit",
					oncommand => 'quit();'
				),
				Button(id => "btnUpdate2", sizeToContent => "1", label => "Update2",
					oncommand => sub {
						ID('textbox1')->style("-moz-appearance:none;border:solid 1px red");
						#ID('button1')->label("Was clicked on ".time()."!");
					}),
				Button(id => "btnUpdate", sizeToContent => "1", label => "Update",
					oncommand => sub {
						return { # change style of textbox
							action => "update",
							id => "textbox1",
							attributes => {
								style => "-moz-appearance:none;color:red",
							},
							subactions => [
								{ # change label of button
									action => "update",
									id => "button1",
									attributes => {
										label => "Was clicked on ".time()."!",
									},
								},				
							],
						};				
					}),
				Button(id => "btnRemove", sizeToContent => "1", label => "Remove",
					oncommand => sub {
						#ID("textbox1")->remove();
					
						return { # change label of button
							action => "remove",
							id => "textbox1",
						};					
					}),
				Button(id => "btnCreate", sizeToContent => "1", label => "Create", 
					oncommand => sub {
						#ID('main')->insert(
						#	'<button label="new"/>'.
						#	'<textbox id="textbox2" flex="1" align="stretch"/>'.
						#	'<html:select>'.
						#		'<html:option>One</html:option>'.
						#		'<html:option>Two</html:option>'.
						#	'</html:select>'.
						#	H1("Hallo!").
						#	Hbox(
						#		Button(label => 'btn1').
						#		Button(label => 'btn2').
						#		Div("hello")
						#	),
						#);
					
						return {
							action => "create",
							parent => "main",
							content =>
								'<button label="new"/>'.
								'<textbox id="textbox2" flex="1" align="stretch"/>'.
								'<html:select>'.
									'<html:option>One</html:option>'.
									'<html:option>Two</html:option>'.
								'</html:select>'.
								H1("Hallo!").
								Hbox(
									Button(label => 'btn1').
									Button(label => 'btn2').
									Div("hello")
								),
						};					
					}),
			),
			Label(id => "label1", sizeToContent => "1", value => "Text Field:"),
			Textbox(id => "textbox1", flex => "1", align => "stretch"),
		),
	),
);

$app->add(
	Window(id => 'subwin',
		Vbox(flex => "1", align => "stretch", id => "box2",
			Hbox(
				Button(id => "btnUpdateX", sizeToContent => "1", label => "Update",
					oncommand => sub {
						return {
							action => "create",
							parent => "main",
							content => '<button label="added by subwin"/>'
						};					
					}),
			),
		),
	),
);

$app->bundle(
	os => 'macosx', 
	path => './TestApp.app', 
	debug => 1,
	utilspath => '../../misc',
);  
