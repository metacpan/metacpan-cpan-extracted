package Chandra::EPUB;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.02';

use Chandra::App;
use Chandra::Element;
use Archive::Zip;
use MIME::Base64;
use Encode qw/decode encode/;

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

	# Start at chapter 1 if chapter 0 title is "Cover" but has no renderable content
	my $start_idx = 0;
	if (@$chapters > 1) {
		my $ch0 = $chapters->[0];
		my $body0 = extract_body($ch0->{html} || '');
		# Skip cover if it's empty or only whitespace/SVG placeholders
		if ($body0 =~ /^\s*$/ || ($ch0->{title} =~ /cover/i && $body0 !~ /<img|xlink:href/i)) {
			$start_idx = 1;
		}
	}
	
	$spa->layout(sub {
		my ($body) = @_;
		my $first_title = $chapters->[$start_idx]{title} || 'Ch 1';
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
								{ tag => 'a', href => '/', data => $first_title },
								{ tag => 'a', href => '/toc', data => 'Contents' },
								(map {
									{ tag => 'a', href => "/chapter/$_", data => "Ch $_" }
								} ($start_idx + 1) .. scalar(@$chapters) - 1),
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
				{ tag => 'div', raw => extract_body($chapters->[$start_idx]{html}) },
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
		*, *::before, *::after { box-sizing: border-box; }
		
		body {
			margin: 0;
			font-family: 'Georgia', 'Times New Roman', serif;
			background: #f8f6f1;
			color: #2d2d2d;
			line-height: 1.7;
		}
		
		#page-wrapper {
			min-height: 100vh;
			display: flex;
			flex-direction: column;
		}
		
		nav {
			background: linear-gradient(180deg, #2c3e50 0%, #1a252f 100%);
			padding: 12px 20px;
			display: flex;
			flex-wrap: nowrap;
			gap: 8px;
			align-items: center;
			box-shadow: 0 2px 8px rgba(0,0,0,0.15);
			position: sticky;
			top: 0;
			z-index: 100;
			overflow-x: auto;
			-webkit-overflow-scrolling: touch;
		}
		
		nav a:any-link {
			color: #ecf0f1;
			text-decoration: none;
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
			font-size: 13px;
			padding: 6px 12px;
			border-radius: 4px;
			transition: all 0.2s ease;
			white-space: nowrap;
		}
		
		nav a:any-link:hover {
			background: rgba(255,255,255,0.1);
			color: #fff;
		}
		
		nav a:first-child,
		nav a:nth-child(2) {
			background: rgba(52, 152, 219, 0.3);
			font-weight: 500;
		}
		
		nav a:first-child:hover,
		nav a:nth-child(2):hover {
			background: rgba(52, 152, 219, 0.5);
		}
		
		#chandra-content {
			flex: 1;
			max-width: 900px;
			margin: 0 auto;
			padding: 40px 24px 60px;
			background: #fff;
			min-height: calc(100vh - 60px);
			box-shadow: 0 0 40px rgba(0,0,0,0.05);
		}
		
		#chandra-content h1, 
		#chandra-content h2, 
		#chandra-content h3 {
			font-family: 'Georgia', serif;
			color: #1a1a1a;
			margin-top: 1.5em;
			margin-bottom: 0.5em;
			line-height: 1.3;
		}
		
		#chandra-content h1 { font-size: 2em; }
		#chandra-content h2 { font-size: 1.5em; }
		#chandra-content h3 { font-size: 1.25em; }
		
		#chandra-content p {
			margin: 1em 0;
			text-align: justify;
			hyphens: auto;
		}
		
		#chandra-content img {
			max-width: 100%;
			height: auto;
			display: block;
			margin: 1.5em auto;
			border-radius: 4px;
		}
		
		#chandra-content a:any-link {
			color: #2980b9;
			text-decoration: none;
			border-bottom: 1px solid rgba(41, 128, 185, 0.3);
			transition: all 0.2s;
		}
		
		#chandra-content a:any-link:hover {
			color: #1a5276;
			border-bottom-color: #1a5276;
		}
		
		#chandra-content blockquote {
			margin: 1.5em 0;
			padding: 1em 1.5em;
			border-left: 4px solid #3498db;
			background: #f4f8fb;
			font-style: italic;
		}
		
		#chandra-content pre, 
		#chandra-content code {
			font-family: 'SF Mono', 'Menlo', 'Monaco', monospace;
			font-size: 0.9em;
			background: #f5f5f5;
			border-radius: 3px;
		}
		
		#chandra-content pre {
			padding: 1em;
			overflow-x: auto;
		}
		
		#chandra-content code {
			padding: 0.2em 0.4em;
		}
		
		.chapter-nav {
			display: flex;
			justify-content: space-between;
			align-items: center;
			padding: 24px 0;
			margin-top: 40px;
			border-top: 1px solid #e0e0e0;
			gap: 16px;
		}
		
		.chapter-nav a:any-link {
			display: inline-flex;
			align-items: center;
			gap: 8px;
			padding: 10px 18px;
			background: #f5f5f5;
			color: #333;
			text-decoration: none;
			border-radius: 6px;
			font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
			font-size: 14px;
			transition: all 0.2s;
			border: 1px solid #ddd;
		}
		
		.chapter-nav a:any-link:hover {
			background: #2c3e50;
			color: #fff;
			border-color: #2c3e50;
		}
		
		/* TOC styling */
		#chandra-content > div > h1:first-child {
			text-align: center;
			margin-bottom: 1em;
			padding-bottom: 0.5em;
			border-bottom: 2px solid #e0e0e0;
		}
		
		#chandra-content > div > p > a {
			display: block;
			padding: 12px 16px;
			margin: 4px 0;
			background: #fafafa;
			border-radius: 6px;
			border: 1px solid #eee;
			transition: all 0.2s;
		}
		
		#chandra-content > div > p > a:hover {
			background: #f0f7fc;
			border-color: #3498db;
			transform: translateX(4px);
		}
		
		/* ============================================
		   Fixed Layout EPUB Overrides
		   ============================================ */
		
		/* Reset fixed dimensions from calibre/FXL EPUBs - exclude svg/image */
		#chandra-content *:not(svg):not(image):not(img) {
			max-width: 100% !important;
			position: static !important;
			float: none !important;
			margin-left: auto !important;
			margin-right: auto !important;
		}
		
		/* SVG cover pages */
		#chandra-content svg {
			display: block;
			max-width: 100%;
			height: auto;
			margin: 0 auto;
		}
		
		#chandra-content svg image {
			width: 100%;
			height: auto;
		}
		
		/* Keep images properly sized */
		#chandra-content img {
			max-width: 100% !important;
			height: auto !important;
			width: auto !important;
		}
		
		/* Override calibre classes */
		#chandra-content [class*="calibre"],
		#chandra-content [class*="block-rw"],
		#chandra-content [class*="galley"],
		#chandra-content [class*="body-rw"],
		#chandra-content section {
			display: block !important;
			float: none !important;
			width: auto !important;
			max-width: 100% !important;
			height: auto !important;
			min-height: 0 !important;
			background-size: contain !important;
			background-position: center !important;
			padding: 0.5em 0 !important;
			margin: 0.5em 0 !important;
			border-radius: 0 !important;
			box-shadow: none !important;
		}
		
		/* Override font sizes */
		#chandra-content [style*="font-size"],
		#chandra-content .p11,
		#chandra-content [class*="calibre"] {
			font-size: inherit !important;
		}
		
		/* Fix list styling */
		#chandra-content ol,
		#chandra-content ul {
			padding-left: 2em !important;
			margin: 1em 0 !important;
		}
		
		#chandra-content li {
			margin: 0.5em 0 !important;
			padding: 0 !important;
			display: list-item !important;
			float: none !important;
		}
		
		/* Fix headings in calibre content */
		#chandra-content [class*="calibre"] h1,
		#chandra-content [class*="calibre"] h2,
		#chandra-content [class*="calibre"] h3 {
			margin: 1em 0 0.5em !important;
			padding: 0 !important;
		}
		
		/* Hide viewport-specific backgrounds on small screens */
		#chandra-content [style*="background-image"] {
			background-image: none !important;
		}
		
		/* Fix divs that had fixed positioning */
		#chandra-content div {
			clear: both;
		}
	|;
}

sub load_epub {
	my ($file) = @_;
	my $zip = Archive::Zip->new($file);
	
	# Find the OPF file via container.xml
	my $container = $zip->contents('META-INF/container.xml');
	die "Invalid EPUB: no META-INF/container.xml\n" unless $container;
	
	my ($opf_path) = $container =~ /full-path="([^"]+)"/;
	die "Invalid EPUB: no rootfile in container.xml\n" unless $opf_path;
	
	my $opf = $zip->contents($opf_path);
	die "Invalid EPUB: cannot read $opf_path\n" unless $opf;
	
	# Get base directory for relative paths
	my $base_dir = '';
	if ($opf_path =~ m{^(.+)/[^/]+$}) {
		$base_dir = $1 . '/';
	}
	
	# Parse manifest: id => href mapping
	my %manifest;
	while ($opf =~ m{<item\s+([^>]+)>}g) {
		my $attrs = $1;
		my ($id) = $attrs =~ /id="([^"]+)"/;
		my ($href) = $attrs =~ /href="([^"]+)"/;
		my ($media) = $attrs =~ /media-type="([^"]+)"/;
		$manifest{$id} = { href => $href, media => $media || '' } if $id && $href;
	}
	
	# Parse spine: ordered list of itemrefs
	my @spine;
	if ($opf =~ m{<spine[^>]*>(.*?)</spine>}s) {
		my $spine_content = $1;
		while ($spine_content =~ m{<itemref\s+idref="([^"]+)"}g) {
			push @spine, $1;
		}
	}
	
	# Collect images and convert to data URIs FIRST (needed for CSS)
	my %images;
	for my $name ($zip->memberNames()) {
		next unless $name =~ m{\.(png|jpg|jpeg|gif|svg)$}i;
		my $ext = lc($1);
		my $mime = $ext eq 'svg' ? 'image/svg+xml' : 
		           $ext eq 'jpg' ? 'image/jpeg' : "image/$ext";
		my $data = $zip->contents($name);
		next unless $data;
		# Store by full path and basename for flexible matching
		my $b64 = "data:$mime;base64," . encode_base64($data, '');
		$images{$name} = $b64;
		my ($basename) = $name =~ m{([^/]+)$};
		$images{$basename} = $b64 if $basename;
	}
	
	# Collect CSS and replace image URLs with data URIs
	my $css = '';
	for my $id (keys %manifest) {
		if ($manifest{$id}{media} eq 'text/css') {
			my $css_path = $manifest{$id}{href};
			my $full_path = $base_dir . $css_path;
			my $css_content = $zip->contents($full_path);
			if ($css_content) {
				# Get CSS file's directory for resolving relative paths
				my $css_dir = '';
				if ($full_path =~ m{^(.*/)[^/]+$}) {
					$css_dir = $1;
				}
				# Replace url() references with data URIs
				$css_content =~ s{url\(([^)]+)\)}{
					my $url = $1;
					$url =~ s/^["']|["']$//g;  # strip quotes
					my $match = $images{$url} || $images{$css_dir . $url} || $images{$base_dir . $url};
					if (!$match) {
						my ($bn) = $url =~ m{([^/]+)$};
						$match = $images{$bn} if $bn;
					}
					$match ? "url($match)" : "url($url)"
				}ge;
				$css .= $css_content . "\n";
			}
		}
	}
	
	# Load chapters in spine order
	my @chapters;
	my $chapter_num = 0;
	for my $idref (@spine) {
		my $item = $manifest{$idref} or next;
		my $href = $base_dir . $item->{href};
		my $html = $zip->contents($href);
		next unless $html;
		
		my ($title) = $html =~ m{<title>([^<]*)</title>}i;
		$title ||= $html =~ m{<h1[^>]*>([^<]*)</h1>}i ? $1 : '';
		$title =~ s/^\s+|\s+$//g if $title;
		$title ||= $chapter_num == 0 ? 'Cover' : "Chapter $chapter_num";
		
		push @chapters, { title => $title, html => $html, href => $href };
		$chapter_num++;
	}
	
	# If spine is empty, try to find xhtml files directly
	if (!@chapters) {
		my @xhtml_files = sort grep { /\.x?html?$/i } $zip->memberNames();
		for my $f (@xhtml_files) {
			next if $f =~ /toc\.x?html?$/i;  # skip TOC
			my $html = $zip->contents($f);
			next unless $html;
			my ($title) = $html =~ m{<title>([^<]*)</title>}i;
			$title ||= $f;
			push @chapters, { title => $title, html => $html, href => $f };
		}
	}
	
	# Process chapters: embed images, fix links
	for my $ch (@chapters) {
		# Replace image src with data URIs
		$ch->{html} =~ s{src="([^"]+)"}{
			my $src = $1;
			my $match = $images{$src} || $images{$base_dir . $src};
			if (!$match) {
				# Try basename match
				my ($bn) = $src =~ m{([^/]+)$};
				$match = $images{$bn} if $bn;
			}
			$match ? qq{src="$match"} : qq{src="$src"}
		}ge;
		
		# Replace SVG xlink:href with data URIs
		$ch->{html} =~ s{xlink:href="([^"]+)"}{
			my $src = $1;
			my $match = $images{$src} || $images{$base_dir . $src};
			if (!$match) {
				my ($bn) = $src =~ m{([^/]+)$};
				$match = $images{$bn} if $bn;
			}
			$match ? qq{xlink:href="$match"} : qq{xlink:href="$src"}
		}ge;
		
		$ch->{html} =~ s/\xEF\xBF\xBC//g;  # strip U+FFFC
		
		# Convert internal links to route format
		# chapters[0] -> "/", chapters[1+] -> "/chapter/$idx"
		$ch->{html} =~ s{href="([^"#]+)(#[^"]*)?"}{
			my ($link, $anchor) = ($1, $2 || '');
			my $idx = _find_chapter_index(\@chapters, $link, $base_dir);
			if (defined $idx) {
				$idx == 0 ? qq{href="/$anchor"} : qq{href="/chapter/$idx$anchor"}
			} else {
				qq{href="$link$anchor"}
			}
		}ge;
	}
	
	return { css => $css, chapters => \@chapters, images => \%images };
}

sub _find_chapter_index {
	my ($chapters, $link, $base_dir) = @_;
	for my $i (0 .. $#$chapters) {
		my $href = $chapters->[$i]{href};
		return $i if $href && ($href eq $link || $href eq "$base_dir$link" || 
		                       $href =~ /\Q$link\E$/);
	}
	return undef;
}

sub extract_body {
	my ($xhtml) = @_;
	if ($xhtml =~ m{<body[^>]*>(.*)</body>}s) {
		my $body = $1;
		$body =~ s/\xEF\xBF\xBC//g;  # strip U+FFFC (raw UTF-8 bytes)
		
		# Remove problematic inline styles that break responsive layout
		$body =~ s{style="[^"]*(?:width|height|position|left|right|top|bottom)\s*:\s*\d+[^"]*"}{}gi;
		
		return decode('UTF-8', $body);
	}
	return $xhtml;
}

1;

__END__

=head1 NAME

Chandra::EPUB - Epub reader built with Perl and Chandra

=head1 VERSION

Version 0.02

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
