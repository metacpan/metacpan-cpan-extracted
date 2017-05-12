#!/usr/bin/perl -w

use strict;
use Archive::Tyd;
use MIME::Base64 qw(encode_base64);
use Tk;
use Tk::HList;
use Tk::JPEG;
use Tk::PNG;

$SIG{__WARN__} = sub {
};

our $main = MainWindow->new (
	-title => 'Tydra',
);
$main->geometry ('640x480');
$main->optionAdd ('*tearOff', 'false');

our $body = {
	file => undef, # Save file
};

our $tyd = new Archive::Tyd();

#####################
## Menu Bar        ##
#####################

our $menu = $main->Menu (-type => 'menubar');
$main->configure (-menu => $menu);

our $fileMenu = $menu->cascade (
	-label => '~File',
	);

	$fileMenu->command (-label => '~New Archive', -accelerator => 'Ctrl+N', -command => sub {
		&newArchive();
	});

	$fileMenu->command (-label => '~Open Archive', -accelerator => 'Ctrl+O', -command => sub {
		&openArchive();
	});

	$fileMenu->command (-label => '~Save Archive', -accelerator => 'Ctrl+S', -command => sub {
		&saveArchive();
	});

	$fileMenu->command (-label => 'Save Archive ~As...', -accelerator => 'Shift+Ctrl+S', -command => sub {
		&saveArchive('as');
	});

	$fileMenu->command (-label => '~Close Archive', -accelerator => 'Ctrl+W', -command => sub {
		&newArchive();
	});

	$fileMenu->separator;

	$fileMenu->command (-label => '~Exit Tydra', -accelerator => 'Alt+F4', -command => sub {
		exit(0);
	});

our $tydMenu = $menu->cascade (
	-label => '~Tyd',
	);

	$tydMenu->command (-label => '~Add File...', -accelerator => 'Ctrl+A', -command => sub {
		&addFile();
	});

	$tydMenu->command (-label => '~Extract File...', -accelerator => 'Ctrl+E', -command => sub {
		&extractFile();
	});

	$tydMenu->command (-label => '~Delete File', -accelerator => 'Ctrl+X', -command => sub {
		&delFile();
	});

	$tydMenu->command (-label => '~View File', -accelerator => 'Enter', -command => sub {
		&viewFile();
	});

our $helpMenu = $menu->cascade (
	-label => '~Help',
	);

	$helpMenu->command (-label => '~About...', -accelerator => 'F1', -command => sub {
		&about();
	});

#####################
## Binding Keys    ##
#####################

$main->bind ('<Control-n>', \&newArchive);
$main->bind ('<Control-o>', \&openArchive);
$main->bind ('<Control-s>', \&saveArchive);
$main->bind ('<Control-S>', sub { &saveArchive('as'); });
$main->bind ('<Control-w>', \&newArchive);
$main->bind ('<Control-a>', \&addFile);
$main->bind ('<Control-e>', \&extractFile);
$main->bind ('<Control-x>', \&delFile);
$main->bind ('<Return>', \&viewFile);
$main->bind ('<F1>', \&about);

#####################
## Workspace       ##
#####################

our $table = $main->Scrolled ('HList',
	-scrollbars => 'ose',
	-header     => 1,
	-columns    => 2,
	-foreground => '#000000',
	-background => '#FFFFFF',
	-selectforeground => '#000000',
	-selectbackground => '#FFFF00',
	-selectborder     => 0,
	-command    => sub {
		&viewFile();
	},
)->pack (-fill => 'both', -expand => 1);

$table->header ('create', 0, -text => 'File Name');
$table->header ('create', 1, -text => 'Size');

MainLoop;

sub newArchive {
	$tyd = undef;
	$tyd = new Archive::Tyd();

	&refresh();
}

sub openArchive {
	my $file = $main->getOpenFile (
		-defaultextension => 'tyd',
		-filetypes => [
			[ 'Tyd Archive', ['*.tyd', '*.dat'] ],
			[ 'All Files',    '*.*'             ],
		],
		-initialdir => '.',
		-title      => 'Open Archive...',
	);
	return unless defined $file;

	my $password = &password();
	return unless defined $password;

	$body->{file} = $file;

	my $read = new Archive::Tyd (password => $password);
	$read->openArchive ($file);
	$tyd = $read;

	# Populate the list.
	&refresh();
}

sub saveArchive {
	my $as = shift || undef;

	my $file = $main->getSaveFile (
		-defaultextension => 'tyd',
		-filetypes => [
			[ 'Tyd Archive', ['*.tyd', '*.dat'] ],
			[ 'All Files',    '*.*'             ],
		],
		-initialdir => '.',
		-title      => 'Save Archive...',
	);
	return unless defined $file;

	my $password = &password;
	return unless defined $password;

	unlink ($file) if (-e $file);

	my $write = new Archive::Tyd (password => $password);
	$write->{files} = $tyd->{files};
	$write->writeArchive ($file);
}

sub addFile {
	my $file = $main->getOpenFile (
		-defaultextension => 'tyd',
		-filetypes => [
			[ 'Common Files', '*.*' ],
			[ 'All Files', '*.*' ],
		],
		-initialdir => '.',
		-title      => 'Select File...',
	);
	return unless defined $file;

	$tyd->addFile ($file);
	&refresh();
}

sub extractFile {
	my $index = $table->selectionGet;
	my $file = $table->itemCget ($index,0,-text);
	return unless exists $tyd->{files}->{$file};

	my ($ext) = $file =~ /\.(\w+)$/i;
	print "Ext: $ext\n";

	my $target = $main->getSaveFile (
		-defaultextension => ".$ext",
		-filetypes        => [
			[ 'Text Document', [ '*.txt'                    ] ],
			[ 'Perl File',     [ '*.pl', '*.pm',            ] ],
			[ 'JPEG Image',    [ '*.jpeg', '*.jpg', '*.jpe' ] ],
			[ 'GIF Image',     [ '*.gif',                   ] ],
			[ 'PNG Image',     [ '*.png',                   ] ],
			[ 'BMP Image',     [ '*.bmp',                   ] ],
			[ 'All Files',       '*.*'                        ],
		],
		-initialdir => '.',
		-title      => 'Extract File...',
	);
	return unless defined $target;

	my $bin = $tyd->readFile ($file);
	open (OUT, ">$target");
	binmode OUT;
	print OUT $bin;
	close (OUT);
}

sub delFile {
	my $index = $table->selectionGet;
	my $file = $table->itemCget ($index,0,-text);
	return unless exists $tyd->{files}->{$file};

	# Delete the file.
	$tyd->deleteFile ($file);
	&refresh();
}

sub viewFile {
	my $index = $table->selectionGet;
	my $file = $table->itemCget ($index,0,-text);
	return unless exists $tyd->{files}->{$file};

	# Figure out its extension.
	if ($file =~ /\.(jpg|jpe|jpeg)$/i) {
		my $bin = $tyd->readFile ($file);
		my $base = encode_base64 ($bin);

		my $image = $main->Photo (-data => $base, -format => 'JPEG');

		my $show = $main->DialogBox (
			-title   => "$file",
			-buttons => [ 'Close' ],
		);

		$show->Label (
			-image => $image,
		)->pack (-padx => 5, -pady => 5);

		$show->Show;
	}
	elsif ($file =~ /\.gif$/i) {
		my $bin = $tyd->readFile ($file);
		my $base = encode_base64 ($bin);

		my $image = $main->Photo (-data => $base, -format => 'GIF');

		my $show = $main->DialogBox (
			-title   => "$file",
			-buttons => [ 'Close' ],
		);

		$show->Label (
			-image => $image,
		)->pack (-padx => 5, -pady => 5);

		$show->Show;
	}
	elsif ($file =~ /\.png$/i) {
		my $bin = $tyd->readFile ($file);
		my $base = encode_base64 ($bin);

		my $image = $main->Photo (-data => $base, -format => 'PNG');

		my $show = $main->DialogBox (
			-title   => "$file",
			-buttons => [ 'Close' ],
		);

		$show->Label (
			-image => $image,
		)->pack (-padx => 5, -pady => 5);

		$show->Show;
	}
	elsif ($file =~ /\.bmp$/i) {
		my $bin = $tyd->readFile ($file);
		my $base = encode_base64 ($bin);

		my $image = $main->Photo (-data => $base, -format => 'BMP');

		my $show = $main->DialogBox (
			-title   => "$file",
			-buttons => [ 'Close' ],
		);

		$show->Label (
			-image => $image,
		)->pack (-padx => 5, -pady => 5);

		$show->Show;
	}
	elsif ($file =~ /\.(htm|html)$/i) {
		my $bin = $tyd->readFile ($file);
		open (TMP, ">./tmp.html");
		print TMP $bin;
		close (TMP);

		system ("start tmp.html");
		unlink ("./tmp.html");
	}
	else {
		# We'll assume it's text.
		my $show = $main->DialogBox (
			-title   => "$file",
			-buttons => [ 'Close' ],
		);

		my $view = $show->Scrolled ('ROText',
			-foreground => '#000000',
			-background => '#FFFFFF',
			-scrollbars => 'ose',
			-wrap       => 'word',
		)->pack (-fill => 'both', -expand => 1);

		$view->insert ('end',$tyd->readFile($file));

		$show->Show;
	}
}

sub about {
	my $show = $main->DialogBox (
		-title   => "About Tydra",
		-buttons => [ 'Close' ],
	);

	my $view = $show->Scrolled ('ROText',
		-foreground => '#000000',
		-background => '#FFFFFF',
		-scrollbars => 'ose',
		-wrap       => 'word',
	)->pack (-fill => 'both', -expand => 1);

	$view->insert ('end',"About Tydra\n\n"
		. "Tydra is a Perl/Tk interface for the Tyd archiver.\n\n"
		. "Tydra and the Tyd archiving format are owned by Cerone Kirsle\n"
		. "(http://search.cpan.org/~kirsle/)");

	$show->Show;
}

sub refresh {
	my @files = $tyd->contents;

	$table->delete ('all');

	my $row = 0;
	foreach my $file (@files) {
		my $bin = $tyd->readFile ($file);
		my $len = length $bin;

		$table->add ($row);
		$table->itemCreate ($row, 0, -text => $file);
		$table->itemCreate ($row, 1, -text => "$len bytes");
		$row++;
	}
}

sub password {
	my $pass = $main->DialogBox (
		-title   => 'Enter Archive Password',
		-buttons => ['Ok', 'Cancel'],
		-default_button => 'Ok',
	);

	$pass->Label (
		-text => 'Enter the password for this archive:',
	)->pack();

	my $password = '';

	$pass->Entry (
		-textvariable => \$password,
		-takefocus    => 1,
		-show         => '*',
	)->pack (-fill => 'x', -expand => 1);

	$pass->focusForce();

	my $choice = $pass->Show;

	if ($choice =~ /ok/i) {
		return $password;
	}

	return undef;
}

=head1 NAME

Tydra - A "WinZip" style application for Tyd documents.

=head1 SYNOPSIS

  $ perl Tydra.pl

=head1 DESCRIPTION

Tydra is a Perl/Tk application as a front-end to viewing and saving Tyd archives visually,
in a similar format to WinZip.

=cut