package Authen::Captcha;

# $Source: /usr/local/cvs/Captcha/pm/Captcha.pm,v $ 
# $Revision: 1.23 $
# $Date: 2003/12/18 04:44:34 $
# $Author: jmiller $ 
# License: GNU General Public License Version 2 (see license.txt)

use 5.00503;
use strict;
use GD;
use String::Random qw(random_regex);
use Carp;
# these are used to find default images dir
use File::Basename;
use File::Spec;

use vars qw($VERSION);

$VERSION = '1.024';

# get our file name, used to find the default images
my $default_images_folder;
{
	my $this_file = __FILE__;
	my $this_dir = dirname($this_file);
	my @this_dirs = File::Spec->splitdir( $this_dir );
	$default_images_folder = File::Spec->catdir(@this_dirs,'Captcha','images');
}

my $num_of_soundfile_versions = 10;

# Preloaded methods go here.

sub new
{
	my ($this) = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless( $self, $class );
		
	my %opts = @_;

	# default character source images
	my $type = defined($opts{type}) ? $opts{type} : 'image';
	$self->type($type);
	my $src_images = (defined($opts{images_folder}) && (-d $opts{images_folder}))
	                 ? $opts{images_folder} : $default_images_folder;
	$self->images_folder($src_images);

	my $debug = (defined($opts{debug}) && ($opts{debug} =~ /^\d+$/))
	            ? $opts{debug} : 0;
	$self->debug($debug);
	$self->data_folder($opts{data_folder}) if($opts{data_folder});
	$self->output_folder($opts{output_folder}) if($opts{output_folder});
	my $expire = (defined($opts{expire}) && ($opts{expire} =~ /^\d+$/))
	             ? $opts{expire} : 300;
	$self->expire($expire);
	my $width = (defined($opts{width}) && ($opts{width} =~ /^\d+$/))
	             ? $opts{width} : 25;
	$self->width($width);
	my $height = (defined($opts{height}) && ($opts{height} =~ /^\d+$/))
	             ? $opts{height} : 35;
	$self->height($height);
	my $keep_failures = (defined($opts{keep_failures}) && $opts{keep_failures})
	                    ? 1 : 0;
	$self->keep_failures($keep_failures);
	
	# create a random seed if perl version less than 5.004
	if ($] < 5.005)
	{	# have to seed rand. using a fairly good seed
		srand( time() ^ ($$ + ($$ << 15)) );
	}	# else, we're just going to let perl do it's thing

	return $self;
}

sub type
{
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{
		if ($_[0] =~ /^(jpg|png|gif|image|picture)$/i)
		{
			$self->{_type} = 'image';
		} elsif ($_[0] =~ /^(sound|snd|wav|mp3)$/i) {
			$self->{_type} = 'sound';
		}
		return $self->{_type};
	} else {
		return $self->{_type};
	}
}

sub debug
{
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{
		$self->{_debug} = $_[0];
		return $self->{_debug};
	} else {
		return $self->{_debug};
	}
}

sub keep_failures
{
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{
		croak "keep_failures must be a zero or one" unless ($_[0] =~ /^[01]$/);
		$self->{_keep_failures} = $_[0];
		return $self->{_keep_failures};
	} else {
		return $self->{_keep_failures};
	}
}

sub expire 
{
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{
		croak "expire must be a possitive integer" unless ($_[0] =~ /^\d+$/);
		$self->{_expire} = $_[0];
		return $self->{_expire};
	} else {
		return $self->{_expire};
	}
}

sub width 
{
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{
		croak "width must be a possitive integer" unless ($_[0] =~ /^\d+$/);
		$self->{_width} = $_[0];
		return $self->{_width};
	} else {
		return $self->{_width};
	}
}

sub height 
{
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)
	{
		croak "height must be a possitive integer" unless ($_[0] =~ /^\d+$/);
		$self->{_height} = $_[0];
		return $self->{_height};
	} else {
		return $self->{_height};
	}
}

sub output_folder
{
	
	ref(my $self = shift) or croak "instance variable needed";
	if (@_)  
	{   # it's a setter
		$self->{_output_folder} = $_[0];
		return $self->{_output_folder};
	} else {
		return $self->{_output_folder};
	}
}

sub images_folder
{
   ref(my $self = shift) or croak "instance variable needed";
   if (@_)
   {   # it's a setter
       $self->{_images_folder} = $_[0];
       return $self->{_images_folder};
   } else {
       return $self->{_images_folder};
   }
}

sub data_folder
{
   ref(my $self = shift) or croak "instance variable needed";
   if (@_)
   {   # it's a setter
       $self->{_data_folder} = $_[0];
       return $self->{_data_folder};
   } else {
       return $self->{_data_folder};
   }
}


sub check_code 
{
	ref(my $self = shift) or croak "instance variable needed";
	my ($code, $token) = @_;

	$code = lc($code);
	
	warn "$code  $token\n" if($self->debug() >= 2);

	my $current_time = time;
	# solution was not found in database (well, yet :)
	my $return_value = -2;
	my $database_file = File::Spec->catfile($self->data_folder(),"codes.txt");

	# create database file if it doesn't already exist
	$self->_touch_file($database_file);

	# zeros (0) and ones (1) are not part of the code
	# they could be confused with (o) and (l), so we swap them in
	$code =~ tr/01/ol/;

	# pull in current database
	warn "Open File: $database_file\n" if($self->debug() >= 2);
	$self->_get_exclusive_lock();
	open (DATA, "<$database_file")  or die "Can't open File: $database_file\n";
		my @data=<DATA>;
	close(DATA);
	warn "Close File: $database_file\n" if($self->debug() >= 2);

	my $passed=0;
	# $new_data will hold the part of the database we want to keep and 
	# write back out
	my $new_data = "";
	foreach my $line (@data) 
	{
		$line =~ s/\n//;
		my ($data_time,$data_token,$data_code) = $line =~ m/(^\d+)::([a-f0-9]{32})::(.*)$/
			or next;

		my $png_file = File::Spec->catfile($self->output_folder(),$data_token . ".png");
		if ($data_token eq $token)
		{

			# the token was found in the database
			if (($current_time - $data_time) > $self->expire())
			{ 
				 warn "Crypt Found But Expired\n" if($self->debug() >= 2);
				# the token was found but has expired
				$return_value = -1;
			} else {
				warn "Match Crypt in File Crypt: $token\n" if($self->debug() >= 2);
			}

			if ( ($data_code eq $code) && ($return_value != -1) )
			{
				warn "Match: " . $data_token . " And " . $token . "\n" if($self->debug() >= 2);
				# solution was correct and was found in database - passed
				$return_value = 1;
			}

			if ( $return_value < ($self->keep_failures() ? -1 : -2) )
			{
				warn "No Match: " . $data_token . " And " . $token . "\n" if($self->debug() >= 2);
				# solution was wrong, not expired, and we're keeping failures
				$new_data .= $line."\n";
			} else {
				# remove the found token so it can't be used again
				warn "Unlink File: " . $png_file . "\n" if($self->debug() >= 2);
				unlink($png_file) or carp("Can't remove png file [$png_file]\n");
			}

			if ( $return_value == -2 ) {
				# incorrect solution
				$return_value = -3;
			}

		} elsif (($current_time - $data_time) > $self->expire()) {
			# removed expired token
			warn "Removing Expired Crypt File: " . $png_file ."\n" if($self->debug() >= 2);
			unlink($png_file) or carp("Can't remove png file [$png_file]\n");
		} else {
			# token not found or expired, keep it
			$new_data .= $line."\n";
		}
	}

	# update database
	open(DATA,">$database_file")  or die "Can't open File: $database_file\n";
		print DATA $new_data;
	close(DATA);
	$self->_release_lock();
	
	return $return_value;
}


sub _open_lock_file {
	my $self = shift;
	my $file_name = shift;
	open(LOCK, ">>$file_name") or die "Error opening lockfile $file_name: $!\n";
}

sub _get_shared_lock {
	my $self = shift;
	my $lock_file_name = File::Spec->catfile($self->data_folder(),"codes.lock");
	$self->_open_lock_file($lock_file_name);

	# shared lock
	flock(LOCK, 1) or die "Error locking lockfile in shared mode: $!\n";
}

sub _get_exclusive_lock {
	my $self = shift;
	my $lock_file_name = File::Spec->catfile($self->data_folder(),"codes.lock");
	$self->_open_lock_file($lock_file_name);

	# exclusive lock
	flock(LOCK, 2) or die "Error locking lockfile exclusively: $!\n";
}

sub _release_lock {
	my $self = shift;
	flock(LOCK, 8) or die "Error unlocking lockfile: $!\n";
	close(LOCK);
}

sub _touch_file
{
	ref(my $self = shift) or croak "instance variable needed";
	my $file = shift;
	# create database file if it doesn't already exist
	if (! -e $file)
	{
		open (DATA, ">>$file") or die "Can't create File: $file\n";
		close(DATA);
	}
}

sub generate_random_string
{
	ref(my $self = shift) or croak "instance variable needed";
	my $length = shift;

	# generate a new code
	my $code = "";
	for(my $i=0; $i < $length; $i++)
	{ 
		my $char;
		my $list = int(rand 4) +1;
		if ($list == 1)
		{ # choose a number 1/4 of the time
			$char = int(rand 7)+50;
		} else { # choose a letter 3/4 of the time
			$char = int(rand 25)+97;
		}
		$char = chr($char);
		$code .= $char;
	}
	return $code;
}

sub _save_code
{
	ref(my $self = shift) or croak "instance variable needed";
	my $code = shift;
	my $token = shift;

	my $database_file = File::Spec->catfile($self->data_folder(),'codes.txt');

	# set a variable with the current time
	my $current_time = time;

	# create database file if it doesn't already exist
	$self->_touch_file($database_file);

	# clean expired codes and images
	$self->_get_exclusive_lock();

	open (DATA, "<$database_file")  or die "Can't open File: $database_file\n";
		my @data=<DATA>;
	close(DATA);
	
	my $new_data = "";
	foreach my $line (@data) 
	{
		$line =~ s/\n//;
		my ($data_time,$data_token,$data_code) = $line =~ m/(^\d+)::([a-f0-9]{32})::(.*)$/
			or next;
		if ( (($current_time - $data_time) > ($self->expire())) ||
		     ($data_token  eq $token) )
		{	# remove expired captcha, or a dup
			my $png_file = File::Spec->catfile($self->output_folder(),$data_token . ".png");
			unlink($png_file) or carp("Can't remove png file [$png_file]\n");
		} else {
			$new_data .= $line."\n";
		}
	}
	
	# save the code to database
	warn "open File: $database_file\n" if($self->debug() >= 2);
	open(DATA,">$database_file")  or die "Can't open File: $database_file\n";
		warn "-->>" . $new_data . "\n" if($self->debug() >= 2);
		warn "-->>" . $current_time . "::" . $token."::".$code."\n" if($self->debug() >= 2);
		print DATA $new_data;
		print DATA $current_time."::".$token."::".$code."\n";
	close(DATA);
	$self->_release_lock();
	warn "Close File: $database_file\n" if($self->debug() >= 2);
}

sub create_image_file
{
	ref(my $self = shift) or croak "instance variable needed";
	my $code = shift;

	my $length = length($code);
	my $im_width = $self->width();
	# create a new image and color
	my $im = new GD::Image(($im_width * $length),$self->height());
	my $black = $im->colorAllocate(0,0,0);

	# copy the character images into the code graphic
	for(my $i=0; $i < $length; $i++)
	{
		my $letter = substr($code,$i,1);
		my $letter_png = File::Spec->catfile($self->images_folder(),$letter . ".png");
		my $source = new GD::Image($letter_png);
		$im->copy($source,($i*($self->width()),0,0,0,$self->width(),$self->height()));
		my $a = int(rand (int(($self->width())/14)))+0;
		my $b = int(rand (int(($self->height())/12)))+0;
		my $c = int(rand (int(($self->width())/3)))-(int(($self->width())/5));
		my $d = int(rand (int(($self->height())/3)))-(int(($self->height())/5));
		$im->copyResized($source,($i*($self->width()))+$a,$b,0,0,($self->width())+$c,($self->height())+$d,$self->width(),$self->height());
	}
	
	# distort the code graphic
	for(my $i=0; $i<($length*($self->width())*($self->height())/14+200); $i++)
	{
		my $a = (int(rand ($length*($self->width())))+0);
		my $b = (int(rand $self->height())+0);
		my $c = (int(rand ($length*($self->width())))+0);
		my $d = (int(rand $self->height())+0);
		my $index = $im->getPixel($a,$b);
		if ($i < (($length*($self->width())*($self->height())/14+200)/100))
		{
			$im->line($a,$b,$c,$d,$index);
		} elsif ($i < (($length*($self->width())*($self->height())/14+200)/2)) {
			$im->setPixel($c,$d,$index);
		} else {
			$im->setPixel($c,$d,$black);
		}
	}
	
	# generate a background
	my $a = int(rand 5)+1;
	my $background_img = File::Spec->catfile($self->images_folder(),"background" . $a . ".png");
	my $source = new GD::Image($background_img);
	my ($background_width,$background_height) = $source->getBounds();
	my $b = int(rand (int($background_width/13)))+0;
	my $c = int(rand (int($background_height/7)))+0;
	my $d = int(rand (int($background_width/13)))+0;
	my $e = int(rand (int($background_height/7)))+0;
	my $source2 = new GD::Image(($length*($self->width())),$self->height());
	$source2->copyResized($source,0,0,$b,$c,($length*($self->width())),$self->height(),$background_width-$b-$d,$background_height-$c-$e);
	
	# merge the background onto the image
	$im->copyMerge($source2,0,0,0,0,($length*($self->width())),$self->height(),40);
	
	# add a border
	$im->rectangle(0,0,((($length)*($self->width()))-1),(($self->height())-1),$black);

	# save the image to file
	my $png_data = $im->png;

	return \$png_data;
}

sub create_sound_file
{
	ref(my $self = shift) or croak "instance variable needed";
	my $code = shift;
	my $length = length($code);

	my @chars = split('',$code);
	my $snd_file;
	local $/; # input record separator. So we can slurp the data.
	# get a random voice speaking the code
	foreach my $char (@chars)
	{
		my $voice = int(rand $num_of_soundfile_versions) + 1;
		my $src_name = File::Spec->catfile($self->images_folder(),$voice, $char . ".wav");
		warn "Open File: $src_name\n" if($self->debug() >= 2);
		open (FILE,"< $src_name") or die "Can't open File: $src_name\n";
			flock FILE, 1; # read lock
			binmode FILE;
			$snd_file .= <FILE>;
		close FILE;
		warn "Close File: $src_name\n" if($self->debug() >= 2);
	}
	return \$snd_file;
}

sub _save_file
{
	ref(my $self = shift) or croak "instance variable needed";
	my $file_ref = shift;
	my $file_name = shift;

	warn "Open File: $file_name\n" if($self->debug() >= 2);
	open (FILE,">$file_name") or die "Can't open File: $file_name \n";
		flock FILE, 2; # write lock
		binmode FILE;
		print FILE $$file_ref;
	close FILE;
	warn "Close File: $file_name\n" if($self->debug() >= 2);
}

sub generate_code 
{
	ref(my $self = shift) or croak "instance variable needed";
	my $length = shift;

	my $code = $self->generate_random_string($length);
	my $token = random_regex('[a-f0-9]{32}');

	my ($captcha_data_ref,$output_filename);
	if ($self->type() eq 'image')
	{
		$captcha_data_ref = $self->create_image_file($code);
		$output_filename = File::Spec->catfile($self->output_folder(),$token . ".png");
	} elsif ($self->type() eq 'sound') {
		$captcha_data_ref = $self->create_sound_file($code);
		$output_filename = File::Spec->catfile($self->output_folder(),$token . ".wav");
	} else {
		croak "invalid captcha type [" . $self->type() . "]";
	}

	$self->_save_file($captcha_data_ref,$output_filename);
	$self->_save_code($code,$token);

	# return token (token)... or, if they want it, the code as well.
	return wantarray ? ($token,$code) : $token;
}

sub version
{
   return $VERSION;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Authen::Captcha - Perl extension for creating captcha's to verify the human element in transactions.

=head1 SYNOPSIS

  use Authen::Captcha;

  # create a new object
  my $captcha = Authen::Captcha->new();

  # set the data_folder. contains flatfile db to maintain state
  $captcha->data_folder('/some/folder');

  # set directory to hold publicly accessible images
  $captcha->output_folder('/some/http/folder');

  # Alternitively, any of the methods to set variables may also be
  # used directly in the constructor

  my $captcha = Authen::Captcha->new(
    data_folder => '/some/folder',
    output_folder => '/some/http/folder',
    );

  # create a captcha. Image filename is "$token.png"
  my $token = $captcha->generate_code($number_of_characters);

  # check for a valid submitted captcha
  #   $code is the submitted letter combination guess from the user
  #   $token is the submitted token from the user (that we gave them)
  my $results = $captcha->check_code($code,$token);
  # $results will be one of:
  #          1 : Passed
  #          0 : Code not checked (file error)
  #         -1 : Failed: code expired
  #         -2 : Failed: invalid code (not in database)
  #         -3 : Failed: invalid code (code does not match token)
  ##############

=head1 WARNING

The captcha produced by this module is rather weak compared to other modules available. You are advised to update to L<GD::SecurityImage>, which provides API-compatible interface in L<GD::SecurityImage::AC> module.

=head1 ABSTRACT

Authen::Captcha provides an object oriented interface to captcha file creations.  Captcha stands for Completely Automated Public Turing test to tell Computers and Humans Apart. A Captcha is a program that can generate and grade tests that:

    - most humans can pass.
    - current computer programs can't pass

The most common form is an image file containing distorted text, which humans are adept at reading, and computers (generally) do a poor job.
This module currently implements that method. We plan to add other methods,
such as distorted sound files, and plain text riddles.

=head1 REQUIRES

    GD          (see http://search.cpan.org/~lds/GD-2.11/)
    Digest::MD5 (standard perl module)

In most common situations, you'll also want to have:

 A web server (untested on windows, but it should work)
 cgi-bin or mod-perl access
 Perl: Perl 5.00503 or later must be installed on the web server.
 GD.pm (with PNG support)

=head1 INSTALLATION

Download the zipped tar file from:

    http://search.cpan.org/search?dist=Authen-Captcha

Unzip the module as follows or use winzip:

    tar -zxvf Authen-Captcha-1.xxx.tar.gz

The module can be installed using the standard Perl procedure:

    perl Makefile.PL
    make
    make test
    make install    # you need to be root

Windows users without a working "make" can get nmake from:

    ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe

=head1 METHODS

=head2 MAIN METHODS

=over

=item C<$captcha = Authen::Captcha-E<gt>new();>

This creates a new Captcha object.
Optionally, you can pass in a hash with configuration information.
See the method descriptions for more detail on what they mean.

=over 2

   data_folder => '/some/folder', # required
   output_folder => '/some/http/folder', # required
   expire => 300, # optional. default 300
   width =>  25, # optional. default 25
   height => 35, # optional. default 35
   images_folder => '/some/folder', # optional. default to lib dir
   keep_failures => 0, # optional, defaults to 0(false)
   debug => 0, # optional. default 0

=back

=item C<$token = $captcha-E<gt>generate_code( $number_of_characters );>

Creates a captcha. Image filename is "$token.png"

It can also be called in array context to retrieve the string of characters used to generate the captcha (the string the user is expected to respond with). This is useful for debugging.
ex.

C<($token,$chars) = $captcha-E<gt>generate_code( $number_of_characters );>

=item C<$results = $captcha-E<gt>check_code($code,$token);>

check for a valid submitted captcha

$code is the submitted letter combination guess from the user

$token is the submitted token from the user (that we gave them)

If the $code and $token are correct, the image file and database entry will be removed.

If the $token matches one in the database, and "keep_failures" is false (the default), the image file and database entry will be removed to avoid repeated attempts on the same captcha.

$results will be one of:

    1 : Passed
    0 : Code not checked (file error)
   -1 : Failed: code expired
   -2 : Failed: invalid code (not in database)
   -3 : Failed: invalid code (code does not match token)

=back

=head2 ACCESSOR METHODS

=over

=item C<$captcha-E<gt>data_folder( '/some/folder' );>

Required. Sets the directory to hold the flatfile database that will be used to store the current non-expired valid captcha tokens.
Must be writable by the process running the script (usually the web server user, which is usually either "apache" or "http"), but should not be accessible to the end user.

=item C<$captcha-E<gt>output_folder( '/some/folder' );>

Required. Sets the directory to hold the generated Captcha image files. This is usually a web accessible directory so that the user can view the images in here, but it doesn't have to be web accessible (you could be attaching the images to an e-mail for some verification, or some other Captcha implementation).
Must be writable by the process running the script (usually the web server user, which is usually either "apache" or "http").

=item C<$captcha-E<gt>images_folder( '/some/folder' );>

Optional, and may greatly affect the results... use with caution. Allows you to override the default character graphic png's and backgrounds with your own set of graphics. These are used in the generation of the final captcha image file. The defaults are held in:
    [lib install dir]/Authen/Captcha/images

=item C<$captcha-E<gt>expire( 300 );>

Optional. Sets the number of seconds this captcha will remain valid. This means that the created captcha's will not remain valid forever, just as long as you want them to be active. Set to an appropriate value for your application. Defaults to 300.

=item C<$captcha-E<gt>width( 25 );>

Optional. Number of pixels high for the character graphics. Defaults to 25.

=item C<$captcha-E<gt>height( 35 );>

Optional. Number of pixels wide for the character graphics. Defaults to 35.

=item C<$captcha-E<gt>keep_failures( [0|1] );>

Optional. Defaults to zero. This option controls whether or not the captcha will remain valid after a failed attempt. By default, we only allow one attempt to solve it. This greatly reduces the possibility that a bot could brute force a correct answer. Change it at your own risk.

=item C<$captcha-E<gt>debug( [0|1|2] );>

Optional. 
Sets the debugging bit. 1 turns it on, 0 turns it off. 2 will print out verbose messages to STDERR.

=back

=head1 TODO

sound file captcha: Incorporating distorted sound file creation.

=head1 SEE ALSO

The Captcha project:
    http://www.captcha.net/

The origonal perl script this came from:
    http://www.firstproductions.com/cgi/

=head1 AUTHORS

Seth T. Jackson, E<lt>sjackson@purifieddata.netE<gt>

Josh I. Miller, E<lt>jmiller@purifieddata.netE<gt>

First Productions, Inc. created the cgi-script distributed under the GPL which was used as the basis for this module. Much work has gone into making this more robust, and suitable for other applications, but much of the origonal code remains.

Fixes were reported and contributed by various people, see Changes file for a complete list.

=head1 COPYRIGHT AND LICENSE

Copyright 2003, First Productions, Inc. (FIRSTPRODUCTIONS HUMAN TEST 1.0)

Copyright 2003 by Seth Jackson

Copyright 2012 by Paolo Rossi, Lubomir Rintel, Chris Dunlop, Gert Schepens and Ernesto Hernández-Novich

This library is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. (see license.txt).

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

=cut
