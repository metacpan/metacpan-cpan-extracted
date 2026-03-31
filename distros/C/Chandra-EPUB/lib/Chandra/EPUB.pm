package Chandra::EPUB;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.01';

use Chandra::App;
use Chandra::Element;
use Archive::Zip;
use MIME::Base64;
use Encode;

sub open {
	my ($pkg, $file) = @_;
	$pkg->new(file => $file)->run();
}

sub new {
	my ($pkg, $args) = (shift, scalar @_ > 1 ? { @_ } : shift) ;

	die "must provide a EPUB book <file> path" unless $args->{file};

	$args->{book} ||= load_epub($args->{file});

	return bless $args, $pkg;
}

sub run {
	my ($self) = @_;

	my $spa = Chandra::App->new(
		title  => $self->{title} || 'Chandra::EPUB',
		width  => $self->{width} || 800,
		height => $self->{height} || 600,
		debug => 1
	);

	my $book = $self->{book};
	my $chapters = $book->{chapters};
	my $css = $book->{css};
	my $custom_css = custom_css();

	$spa->layout(sub {
		my ($body) = @_;
		Chandra::Element->new({
			tag => 'div',
			children => [
				{ tag => 'style', raw => $css },
				{
					tag => 'style',
					raw => $custom_css
				},
				{
					tag => 'div',
					id => 'page-wrapper',
					children => [
						{
							tag => 'nav',
							children => [
								{ tag => 'a', href => '/', data => 'Home' },
								{ tag => 'a', href => '/toc', data => 'Contents' },
								(map {
									{ tag => 'a', href => "/chapter/$_", data => "Ch $_" }
								} 1 .. scalar(@$chapters) - 1),
							],
						},
						{
							tag => 'div',
							id => 'chandra-content',
							raw => $body,
						},	
					],
				},
			],
		});
	});

	$spa->route('/' => sub {
		Chandra::Element->new({
			tag => 'div',
			children => [
				{ tag => 'div', raw => extract_body($chapters->[0]{html}) },
			],
		});
	});

	$spa->route('/toc' => sub {
		Chandra::Element->new({
			tag => 'div',
			children => [
				{ tag => 'h1', data => 'Table of Contents', style => 'text-align:center;color:#76696B' },
				(map {
					my $i = $_;
					{
						tag => 'p',
						style => 'margin:8px 0',
						children => [
							{ tag => 'a', href => "/chapter/$i", data => $chapters->[$i]{title} },
						]
					};
				} 1 .. $#$chapters),
			],
		});
	});

	for my $i (1 .. $#$chapters) {
		my $idx = $i;
		$spa->route("/chapter/$i" => sub {
			my $body = extract_body($chapters->[$idx]{html});
			my @nav_children;
			push @nav_children, { tag => 'a', href => '/chapter/' . ($idx - 1), data => "\x{2190} Previous" }
			if $idx > 1;
			push @nav_children, { tag => 'a', href => '/toc', data => 'Contents' };
			push @nav_children, { tag => 'a', href => '/chapter/' . ($idx + 1), data => "Next \x{2192}" }
			if $idx < $#$chapters;

			Chandra::Element->new({
				tag => 'div',
				children => [
					{ tag => 'div', raw => $body },
					{ tag => 'div', class => 'chapter-nav', children => \@nav_children },
					{
						tag => 'script',
						raw => 'window.scrollTo(0,0)'
					}
				],
			});
		});
	}

	$spa->not_found(sub {
		Chandra::Element->new({ tag => 'h1', data => '404 - Not Found' });
	});

	$spa->run;
}

sub custom_css {
	return q|
		body{margin:0}
		nav{background:rgb(20, 24, 27);gap:10px;display:flex;flex-direction:row;overflow:scroll;padding: 1em}
		nav a:any-link{color:rgb(200,204,207);text-decoration:none;font-size:16px;white-space:nowrap;}
		nav a:any-link:hover{color:rgb(240,244,247);text-decoration:underline}
		#chandra-content{font-size:14px;max-width:700px;margin:20px auto;padding:0 20px}
		#chandra-content .p11 {font-size:14px;}
		.chapter-nav{display:flex;justify-content:space-between;padding:20px 0;border-top:1px solid #ccc;margin-top:20px}
		.chapter-nav a{color:#333}
	|;
}

sub load_epub {
	my ($file) = @_;
	my $zip = Archive::Zip->new($file);
	my $css = $zip->contents('OPS/css/book.css') || '';
	my %images;
	for my $name ($zip->memberNames()) {
		next unless $name =~ m{^OPS/images/(.+\.png)$};
		my $data = $zip->contents($name);
		$images{$1} = 'data:image/png;base64,' . encode_base64($data, '');
	}
	my @chapters;
	my $title_html = $zip->contents('OPS/titlePageContent.xhtml') || '';
	push @chapters, { title => 'Title', html => $title_html };
	# Then numbered chapters
	my @chapter_files = sort {
		my ($na) = $a =~ /(\d+)/;
		my ($nb) = $b =~ /(\d+)/;
		($na || 0) <=> ($nb || 0)
	} grep { m{^OPS/chapter-\d+\.xhtml$} } $zip->memberNames();
	for my $file (@chapter_files) {
		my $html = $zip->contents($file);
		next unless $html;
		my ($num) = $file =~ /chapter-(\d+)/;
		my ($title) = $html =~ m{<title>([^<]*)</title>};
		$title =~ s/^\d+\s+// if $title;
		$title ||= "Chapter $num";
		push @chapters, { title => $title, html => $html };
	}
	for my $ch (@chapters) {
		for my $img_name (keys %images) {
			$ch->{html} =~ s{src="images/\Q$img_name\E"}{src="$images{$img_name}"}g;
		}
		$ch->{html} =~ s/\xEF\xBF\xBC//g;  # strip U+FFFC (raw UTF-8 bytes)
		$ch->{html} =~ s{href="chapter-(\d+)\.xhtml"}{'href="/chapter/' . $1 . '"'}ge;
	}
	return { css => $css, chapters => \@chapters, images => \%images };
}
use Encode qw/decode encode/;
sub extract_body {
	my ($xhtml) = @_;
	if ($xhtml =~ m{<body[^>]*>(.*)</body>}s) {
		my $body = $1;
		$body =~ s/\xEF\xBF\xBC//g;  # strip U+FFFC (raw UTF-8 bytes)
		return decode('UTF-8', $body);
	}
	return $xhtml;
}

1;

__END__

=head1 NAME

Chandra::EPUB - Epub reader built with Perl and Chandra

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	Chandra::EPUB->open('mybook.epub');

...

	my $book = Chandra::EPUB->new(
		file => 'mybook.epub'
		width => 800, # optional
		height => 600, # optional
		title => 'My Book', # optional	
	);
	$book->run();

=head1 DESCRIPTION

Chandra::EPUB is an EPUB reader built with Perl and Chandra. It allows you to open and read Epub files, navigate through chapters, and customize the reading experience with optional settings such as width, height, and title.

=cut

=head1 METHODS

=head2 open

Open an EPUB file and start the reader. Same as calling new with the file and then run.

	Chandra::EPUB->open('mybook.epub');

=cut

=head2 new

Instantiate a new Chandra::EPUB object. You can provide the file path to the EPUB book, as well as optional settings for width, height, and title.

	my $book = Chandra::EPUB->new(
		file => 'mybook.epub'
		width => 800, # optional
		height => 600, # optional
		title => 'My Book', # optional	
	);

=cut

=head2 run

Run the EPUB reader application. This will open a window and display the contents of the EPUB book.

	$book->run();

=cut

=head2 load_epub

Load the EPUB file and extract its contents, including CSS, chapters, and images.

	my $book_data = load_epub('mybook.epub');

=cut

=head2 extract_body

Extract the inner content of the <body> tag from the given XHTML string.

	my $body = extract_body($xhtml);

=cut

=head1 AUTHOR

lnation <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chandra-epub at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chandra-EPUB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Chandra::EPUB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Chandra-EPUB>

=item * Search CPAN

L<https://metacpan.org/release/Chandra-EPUB>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by lnation <email@lnation.org>.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Chandra::EPUB
