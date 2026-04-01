package Ascii::Text::Chandra;

use 5.008003;
use strict;
use warnings;

use Chandra::App;
use Chandra::Element;
use Ascii::Text;

our $VERSION = 0.01;

sub run {
	my ($self, %args) = @_;

	my $app = Chandra::App->new(
		title => $args{title} || 'Ascii::Text::Chandra',
		width => $args{width} || 800,
		height => $args{height} || 600,
		debug => 1
	);

	my @files = map { { tag => 'option', data => $_ }  } Ascii::Text->new->list();
	$app->set_content(
		Chandra::Element->new({
			tag => 'div',
			children => [
				{
					tag => 'form',
					children => [
						{
							tag => 'input',
							id => 'input-back',
							type => 'color',
							value => 'rgb(0,0,0)'
						},
						{
							tag => 'input',
							id => 'input-color',
							type => 'color',
							value => 'rgb(0,255,0)'
						},
						{
							tag => 'select',
							id => 'input-font',
							children => \@files
						},

						{
							tag => 'input',
							id => 'input-text',
							value => 'Hello World'
						},
					]
				},
				{
					tag => 'pre',
					id => 'chandra-content', 
				}
			]
		})
	);

	$app->css(q|
		body {
			margin: 0; 
			background: rgb(0,0,0);
		}
		form {
			background: rgb(30, 34, 37);
			border-bottom: 1px solid rgb(10, 14, 17);
			padding: 0.5em 1em;
			display: flex;
		}
		#input-text {
			padding: 0.5em;
			background: rgb(40, 44, 47);
			border: none;
			color: rgb(240, 244, 247);
			flex-grow: 1;
		}
		select#input-font {
			padding: 0.5em;
			background: rgb(40, 44, 47);
			border: none;
			color: rgb(240, 244, 247);
			background-clip: unset !important;
			border-radius: 0;
			appearance: none;
			margin-right: 0.5em;
		}
		#input-font {
			padding: 0.5em;
			background: rgb(30, 34, 37);
			border: none;
			color: rgb(240, 244, 247);
		}
		input[type="color"] {
			block-size: 3em;
			inline-size: 3em;
			vertical-align: middle;
			padding: 0;
		}
		pre {
			padding: 2em 1em;
			color: rgb(0, 255, 0);
		}
	|);

	$app->js(qq|
		let inputEl = document.querySelector('input#input-text');
		let select = document.querySelector('select#input-font');
		let content = document.querySelector('#chandra-content');
		let back_color = document.querySelector('#input-back');
		let fore_color = document.querySelector('#input-color');

		function calculate_spaces() {
			var len = content.offsetWidth;
			var span = document.createElement('span');
			content.appendChild(span);
			span.innerHTML = '';
			for(var i = 0; span.offsetWidth <= len; i++) {
			  span.innerHTML += ' ';
			}
			let num = span.innerHTML.substring(0, span.innerHTML.length - 1);
			span.remove();
			return num.length;
		}

	
		function doSend() {
			var text = inputEl.value.trim();
			if (!text) return;
			let max_space = calculate_spaces();
			window.chandra.invoke('render_text', [select.value, text, max_space]).then(d => content.innerText = d);
		}

		fore_color.addEventListener('change', function (e) {
			content.style["color"] = e.target.value;
		});

		back_color.addEventListener('change', function (e) {
			document.body.style["background"] = e.target.value;
		});


		inputEl.addEventListener('keydown', function(e) {
			if (e.key === 'Enter') {
				e.stopPropagation();
				e.preventDefault();
				doSend();
			}
		});

		select.addEventListener('change', function(e) {
			doSend();
		});

		window.addEventListener('resize', function (e) {
			doSend();
		});

    		inputEl.focus();
		doSend();
	|);

	$app->bind('render_text', sub {
		my ($font, $text, $max_space) = @_;
		my $t = Ascii::Text->new(
			align => 'left',
			pad => 0,
			font => ucfirst($font),
			max_width => $max_space,
			override_empty_space => 3
		);
		my $ascii = $t->stringify($text);
		return $ascii;
	});

	$app->run;
}


1;

__END__

=head1 NAME

Ascii::Text::Chandra - Render ascii text in a Chandra webview

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Ascii::Text::Chandra;

    Ascii::Text::Chandra->run(); # will open a chandra window with a simple form to render ascii text

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ascii-text-chandra at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ascii-Text-Chandra>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ascii::Text::Chandra

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ascii-Text-Chandra>

=item * Search CPAN

L<https://metacpan.org/release/Ascii-Text-Chandra>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Ascii::Text::Chandra
