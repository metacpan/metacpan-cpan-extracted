package Archive::Tyd;

use strict;
use warnings;
use Crypt::CipherSaber;

our $VERSION = '0.02';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto || 'Archive::Tyd';

	my $self = {
		password => 'default', # Archive Password
		contents => [],        # Contents Array
		files    => {},        # File Data
		cipher   => undef,     # Cipher object
		debug    => 0,
		@_,
	};

	bless ($self,$class);
	return $self;
}

sub cipher {
	my $self = shift;
	my $force = shift || 0;

	if (not defined $self->{cipher} || $force) {
		$self->{cipher} = Crypt::CipherSaber->new ($self->{password});
	}
}

sub password {
	my ($self,$pass) = shift;
	$self->{password} = $pass;

	$self->cipher (1);
}

sub openArchive {
	my ($self,$file) = @_;

	$self->cipher;

	# Read the file.
	open (FILE, "$file");
	binmode FILE;
	my @data = <FILE>;
	close (FILE);
	chomp @data;

	my $contents = join ("\n",@data);
	$contents = $self->{cipher}->decrypt ($contents);

	my @lines = split(/\n/, $contents);

	foreach my $line (@lines) {
		my ($name,$bin) = split(/::/, $line, 2);
		$bin =~ s/<<ln>>/\n/g;
		$bin =~ s/<<lr>>/\r/g;

		$self->{files}->{$name} = $bin;
	}

	print "Opened archive $file - contents " . scalar(@lines) . " files\n" if $self->{debug};
}

sub writeArchive {
	my ($self,$file) = @_;

	$self->cipher;

	# Write to the file.
	my @write = ();
	foreach my $item (keys %{$self->{files}}) {
		print "\tAdding $item to output\n" if $self->{debug};

		# Make sure the line breaks are taken care of.
		$self->{files}->{$item} =~ s/\n/<<ln>>/g;
		$self->{files}->{$item} =~ s/\r/<<lr>>/g;
		push (@write, "$item" . '::' . "$self->{files}->{$item}");
	}

	my $bin = join ("\n",@write);

	my $enc = $self->{cipher}->encrypt ($bin);

	open (OUT, ">$file");
	binmode OUT;
	print OUT $enc;
	close (OUT);

	print "Wrote " . scalar(keys %{$self->{files}}) . " files to $file\n" if $self->{debug};
}

sub contents {
	my $self = shift;

	my @files = keys %{$self->{files}};
	return @files;
}

sub addFile {
	my ($self,$file) = @_;

	$self->cipher;

	open (FILE, $file);
	binmode FILE;
	my @data = <FILE>;
	close (FILE);
	chomp @data;

	my $filename = $self->filename ($file);

	my $content = join ("<<linebreak>>",@data);
	$content =~ s/\n/<<ln>>/g;
	$content =~ s/\r/<<lr>>/g;

	print "Added $filename to archive\n" if $self->{debug};

	# Add this to the index.
	$self->{files}->{$filename} = $content;
}

sub deleteFile {
	my ($self,$filename) = @_;

	$self->cipher;

	if (exists $self->{files}->{$filename}) {
		print "Deleted $filename\n" if $self->{debug};
		delete $self->{files}->{$filename};
	}
	else {
		warn "File $filename doesn't exist in this archive";
	}
}

sub readFile {
	my ($self,$filename) = @_;

	$self->cipher;

	if (exists $self->{files}->{$filename}) {
		my $bin = $self->{files}->{$filename};
		$bin =~ s/<<ln>>/\n/g;
		$bin =~ s/<<lr>>/\r/g;
		$bin =~ s/<<linebreak>>/\n/g;

		print "Read $filename\n" if $self->{debug};

		return $bin;
	}
	else {
		warn "File $filename doesn't exist in this archive";
	}
}

sub filename {
	my ($self,$path) = @_;

	my @parts = split(/(\/|\\)/, $path);
	my $name = pop(@parts);

	return $name;
}

1;
__END__

=head1 NAME

Archive::Tyd - Perl extension for simple file archiving.

=head1 SYNOPSIS

  use Archive::Tyd;

  my $tyd = new Archive::Tyd (password => 'secret password');

  # Load an archive.
  $tyd->openArchive ("./archive.tyd");

  # Add a file.
  $tyd->addFile ("./secret image.jpg");

  # Write the archive.
  $tyd->writeArchive ("./archive.tyd");

  # Read the secret rules.
  my $rules = $tyd->readFile ("rules.txt");

=head1 DESCRIPTION

Tyd is a simple archiving algorith for merging multiple files together and
encrypting the results, hence a password-protected archive.

B<Tyd Does:> Reading and writing of encrypted Tyd archives and file
operations within.

B<Tyd Does:> Load all files into memory. Tyd is not good as a storage device
for a large quanitity of large files. Tyd is best for keeping small text files
and graphics together (maybe to keep a spriteset and definitions for a game?)

B<Tyd Does Not:> support directories within the archive, compression of files,
and many other things that WinZip and GZip support.

=head1 METHODS

=head2 new (ARGUMENTS)

Creates a new Tyd object. You can pass in defaults here (such as B<password> and
B<debug>).

=head2 password (PASSWORD)

(Re)define the password to be used. The default password is 'default'.

=head2 openArchive (FILE)

Open the archive and decrypt it with the password. You can load multiple
archives with one object, and even change the password between each one.

=head2 writeArchive (FILE)

Writes all the files to the archive using the current password.

=head2 addFile (FILEPATH)

Adds FILEPATH to the archive. The file will later be called by its file name,
not the whole path (i.e. just "readme.txt", not "C:/secret folder/readme.txt")

=head2 deleteFile (FILENAME)

Delete the file from the archive.

=head2 readFile (FILENAME)

Read the file. It will return the binary data of the file (which you can then
save to another file or whatever).

=head2 contents

Returns an array of each file in the archive.

=head2 filename (FILEPATH) *Internal

Takes a file path and returns its name

=head2 cipher ([FORCE]) *Internal

Creates the ciphering object. Supply FORCE for it to recreate the object
forcefully (used when you call the B<password> method to change the password).

=head1 WHY

I made this module to use with games I make which will allow users to create their
own quests and store ALL of their data (maps, sound effects, tilesets, etc) into a
single, password-protected file.

This module was not meant to compress files in any way. The resulting archive
should be little more than the original size of all the files archived inside of
it. This algorithm is only for tying files together and password protecting them.

=head1 ALGORITHM

The algorithm is quite simple. When not encrypted, the archive file would read
like this:

  filename::data
  filename::data
  filename::data
  ...

Once the unencrypted file is ready, the entire thing is encrypted using
L<Crypt::CipherSaber> with the password provided and written to the archive.

=head1 CHANGES

  Version 0.02
  - Fixed some major bugs. In 0.01 version, reading an archive Tyd file and then
    re-archiving it from the files in-memory, would for some reason corrupt the file.
    This has been repaired.
  - Carriage Returns are now filtered in and out correctly.
  - Included Tydra--a Perl/Tk interface to Tyd Archive Viewing.

  Version 0.01
  - Initial Release

=head1 SEE ALSO

L<Crypt::CipherSaber>

=head1 AUTHOR

C. J. Kirsle, <kirsle "@" rainbowboi.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by C. J. Kirsle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
