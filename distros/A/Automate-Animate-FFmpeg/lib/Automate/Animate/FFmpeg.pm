package Automate::Animate::FFmpeg;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.12';

use utf8; # filenames can be in utf8

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

use File::Temp;
use File::Find::Rule;
use IPC::Run;
use Text::ParseWords;
use Encode;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
use Cwd::utf8 qw/abs_path cwd/;

sub	new {
	my $class = $_[0];
	my $params = $_[1];

	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	my $self = {
		'input-images' => [],
		'output-filename' => undef,
		'verbosity' => 0,
		# params to ffmpeg must be given as an arrayref
		# these are our standard params, they are read only and must
		# be supplied here as an ARRAYref
		'ffmpeg-standard-params' => ['-c', 'copy', '-c:v', 'copy', '-c:a', 'copy', '-q:a', '0', '-q:v', '1'],
		# extra params to ffmpeg can be specified by the caller
		# we store this as an ARRAYref, each option and value is an item of its own
		'ffmpeg-extra-params' => [],
		# the duration of each frame in seconds (fractional supported)
		# or <=0 for using FFmpeg's defaults
		'frame-duration' => 0,
		# this will be modified during perl Makefile.PL
		'ffmpeg-executable' => '/usr/local/bin/ffmpeg', # specify fullpath if not in path
		# end this will be modified during perl Makefile.PL
	};
	bless $self, $class;

	my $ak;

	# sort out the easy params
	my $verbos = 0;
	$ak = 'verbosity';
	if( exists($params->{$ak}) && defined($verbos=$params->{$ak}) ){ $self->verbosity($verbos) }

	for $ak (qw/
		output-filename
		frame-duration
	/){
		if( exists($params->{$ak}) && defined($params->{$ak}) ){
			$self->{$ak} = $params->{$ak};
			if( $verbos > 1 ){ print "${whoami} (via $parent), line ".__LINE__." : parameter '$ak' set to : ".$params->{$ak}."\n"; }
		}
	}

	# specify input images as scalar, arrayref or hashref (values)
	$ak = 'input-images';
	if( exists($params->{$ak}) && defined($params->{$ak})
		&& scalar($params->{$ak})
	){
		$self->input_images($params->{$ak});
	}

	# input image filenames are read from specified file (one filename per line)
	$ak = 'input-images-from-file';
	if( exists($params->{$ak}) && defined($params->{$ak})
		&& scalar($params->{$ak})
	){
		if( ! $self->input_file_with_images($params->{$ak}) ){ print STDERR perl2dump($params->{$ak})."${whoami} (via $parent), line ".__LINE__." : error, failed to load input images from file containing their pathnames: '".$params->{$ak}."'.\n"; return undef }
	}

	# input images can be specified via a pattern and a search dir
	# like : 'input-pattern' => ['*.png', '/x/y/searchdir']
	$ak = 'input-pattern';
	if( exists($params->{$ak}) && defined($params->{$ak}) ){
		if( ref($params->{$ak})ne'ARRAY' ){ print STDERR perl2dump($params->{$ak})."${whoami} (via $parent), line ".__LINE__." : error, the argument to '$ak' must be an ARRAYref of 1 or 2 items: the pattern and optionally the search dir. See above for what was provided.\n"; return undef }
		if( ! $self->input_pattern($params->{$ak}) ){ print STDERR perl2dump($params->{$ak})."${whoami} (via $parent), line ".__LINE__." : error, failed to find input files based on the above pattern and search dir.\n"; return undef }
	}
	# or via multiple patterns (an ARRAY of ARRAY patterns, as above)
	$ak = 'input-patterns';
	if( exists($params->{$ak}) && defined($params->{$ak}) ){
		if( ref($params->{$ak})ne'ARRAY' ){ print STDERR perl2dump($params->{$ak})."${whoami} (via $parent), line ".__LINE__." : error, the argument to '$ak' must be an ARRAYref of one or more ARRAYrefs each of 1 or 2 items: the pattern and optionally the search dir. See above for what it was provided.\n"; return undef }
		if( ! $self->input_patterns($params->{$ak}) ){ print STDERR perl2dump($params->{$ak})."${whoami} (via $parent), line ".__LINE__." : error, failed to find input files based on the above pattern and search dir.\n"; return undef }
	}

	# specify output filename
	$ak = 'output-filename';
	if( exists($params->{$ak}) && defined($params->{$ak}) ){
		$self->output_filename($params->{$ak});
		if( $verbos > 1 ){ print "${whoami} (via $parent), line ".__LINE__." : parameter '$ak' set to : ".$params->{$ak}."\n"; }
	}
	# any extra ffmpeg params?
	# these are cmdline options to FFmpeg and must be
	# passed as an ARRAY, each flag, option and parameter is
	# a single array item, for example
	# ['-i', 'inputfile', '-o', 'out', '-p', '1', '2']
	# note that above -p is used as in -p 1 2
	$ak = 'ffmpeg-extra-params';
	if( exists($params->{$ak}) && defined($params->{$ak}) ){
		if( ! defined($self->ffmpeg_extra_params($params->{$ak})) ){ print STDERR perl2dump($params->{$ak})."${whoami} (via $parent), line ".__LINE__." : error, failed to parse/verify the above params to ffmpeg via '--ffmpeg-extra-params'.\n"; return undef }
		if( $verbos > 1 ){ print "${whoami} (via $parent), line ".__LINE__." : parameter '$ak' set to : ".$params->{$ak}."\n"; }
	}

	return $self
}
# it spawns ffmpeg as external command via IPC::Run::run(@cmd)
# requires that at least 1 input image was specified before.
# returns 0 on failure, 1 on success
sub	make_animation {
	my $self = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $verbos = $self->verbosity();

	my $cmdret = $self->_build_ffmpeg_cmdline();
	if( ! defined $cmdret ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, failed to build ffmpeg command line, call to ".'_build_ffmpeg_cmdline()'." has failed.\n"; return 0 }
	my $cmdline = $cmdret->{'cmdline'};
	my $tmpfile = $cmdret->{'tmpfile'};
	if( $verbos > 0 ){ print "${whoami} (via $parent), line ".__LINE__." : executing system command:\n".join(' ',@$cmdline)."\n" }
	my ($in, $out, $err);
	my $ret = IPC::Run::run($cmdline, \$in, \$out, \$err);
	if( ! $ret ){ 
		print STDERR "$out\n$err\n${whoami} (via $parent), line ".__LINE__." : error, executing this command has failed (the list of input files is in '$tmpfile', you may delete it when you are done):\n  ".join(' ', @$cmdline)."\n";
		return 0
	}
	if( $verbos > 0 ){
		if( $verbos > 1 ){ print $out."\n" }
		print "${whoami} (via $parent), line ".__LINE__." : done, success. Output animation of ".$self->num_input_images()." input images is in '".$self->output_filename()."'.\n"
	}
	unlink($tmpfile);

	return 1;
}
sub	_build_ffmpeg_cmdline {
	my $self = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $verbos = $self->verbosity();

	if( $self->num_input_images() == 0 ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, no input images in store.\n"; return undef }
	if( ! defined $self->output_filename() ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, no output filename specified.\n"; return undef }

	my $execu = $self->ffmpeg_executable();
	if( ! defined $execu ){ print STDERR "$whoami() (via $parent), line ".__LINE__." : error, the path to the ffmpeg executable is undefined. That means that the external, 3rd-party dependency 'ffmpeg' was not located during installation. First you need to install ffmpeg. Then re-install current module. Note that if ffmpeg is installed in a non-standard location you need to specify that location (i.e. the full-path to the ffmpeg executable) at installation of this module by setting the environment variable 'AUTOMATE_ANIMATE_FFMPEG_PATH'. See the documentation (https://metacpan.org/pod/Automate::Animate::FFmpeg#INSTALLATION) for further details.\n"; return undef }

	# get a tmp file - only drawback is it is in current working dir
	# but on the other hand we do not want caller to delete a directory!
	my ($fh, $tmpfile) = File::Temp::tempfile('XXXXXXXXXXXX', SUFFIX => '.txt');
	my $duration_str = $self->frame_duration() > 0 ? "duration ".$self->frame_duration()."\n" : "";
	binmode $fh, ':encoding(UTF-8)';
	print $fh "file '".$_."'\n"
			  .${duration_str}
	for @{$self->{'input-images'}};
	close $fh;

	my @cmdline = (
		$execu,
		# the extra params to FFmpeg is just a command-line args style
		@{ $self->ffmpeg_extra_params() },
		# and the concats etc.
		'-f', 'concat',
		'-y',
		# this is about accepting relative filepaths to images
		'-safe', '0',
		# all images filepathas are in this file (one in each line)
		'-i', $tmpfile,
		@{ $self->ffmpeg_standard_params() },
		$self->output_filename()
	);
	return {
		'cmdline' => \@cmdline,
		# this can be unlinked by caller if needed
		'tmpfile' => $tmpfile
	}
}
# set the executable only via the constructor
sub	ffmpeg_executable { return $_[0]->{'ffmpeg-executable'} }
sub	verbosity {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'verbosity'} unless defined $m;
	$self->{'verbosity'} = $m;
	return $m
}
sub	frame_duration {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'frame-duration'} unless defined $m;
	$self->{'frame-duration'} = $m;
	return $m
}

# note: when setting an output filename, make sure you
# specify the extension and it does make sense to FFmpeg (e.g. mp4)
sub	output_filename {
	my $self = $_[0];
	my $outfile = $_[1];
	return $self->{'output-filename'} unless defined $outfile;
	$self->{'output-filename'} = $outfile;
	return $outfile
}
sub	_cmdline2argsarray {
	my $m = $_[0];
	if( ref($m) eq 'ARRAY' ){
		return [ @$m ]
	} elsif( ref($m) eq '' ){
		return Text::ParseWords::shellwords($m)
	} elsif( ref($m) eq 'HASH' ){
		return [ %$m ];
	}
	print STDERR "_cmdline2argsarray() : error, an ARRAYref/HASHref/String-scalar containing command-line arguments was expected, not ".ref($m)."\n";
	return undef
}
sub	ffmpeg_extra_params {
	my $self = $_[0];
	my $m = $_[1];
	return $self->{'ffmpeg-extra-params'} unless defined $m;
	my $ret = _cmdline2argsarray($self->{'ffmpeg-extra-params'});
	if( ! defined $ret ){ print STDERR perl2dump($ret)."ffmpeg_extra_params() : error, failed to pass above arguments.\n"; return undef }
	$self->{'ffmpeg-extra-params'} = $ret;
	return $ret
}
sub	ffmpeg_standard_params { return $_[0]->{'ffmpeg-standard-params'} }
sub	num_input_images { return scalar @{$_[0]->{'input-images'}} }
# specify a text file which holds image filenames, one per line to be added
# hash-comments are understood, empty/only-space lines are removed
# returns 1 on success, 0 on failure
sub	input_file_with_images {
	my ($self, $infile) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $verbos = $self->verbosity();
	if( ! defined $infile ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, an input filename of input image filenames is expected.\n"; return 0 }
	my $fh;
	if( ! open($fh, '<:encoding(UTF-8)', $infile) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, could not open input file '$infile' for reading, $!\n"; return 0 }
	while( <$fh> ){
		chomp;
		s/#.*$//;
		s/^\s*$//;
		$self->input_images($_) unless /^\s*$/;
	} close $fh;
	return 1
}
sub	clear_input_images { $#{ $_[0]->{'input-images'} } = -1 }
# Add using a single pattern/searchdir
# add image files via a pattern and an input dir, e.g. '*.png', '/x/y/z/'
# make sure that the order you expect is what you get during the pattern materialisation
# the search dir is optional, default is Cwd::cwd
sub	input_pattern {
	my ($self, $params) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $verbos = $self->verbosity();
	my ($_pattern, $indir) = @$params;
	my $indir_need_encode_utf8 = 0;
	if( ! defined $indir ){
		$indir = _my_cwd();
		if( $verbos > 0 ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : warning, no search dir was specified and using current dir '$indir'.\n" }
	} else { $indir_need_encode_utf8 = 1 }
	my $pattern;
	# allows for /pattern/modifiers
	if( $_pattern =~ m!^regex\(/(.*?)/(.*?)\)$! ){
		# see https://www.perlmonks.org/?node_id=1210675
		my $pa = $1; my $mo = $2;
		if( $mo!~/^[msixpodualn]+$/ ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, illegal modifiers ($mo) to the specified regex detected.\n"; return 0 }
		# the modifiers are entered as (?...) before the regex pattern
		$pattern = qr/(?${mo})${pa}/;
	} else { $pattern = $_pattern }
	if( $verbos > 1 ){ print "${whoami} (via $parent), line ".__LINE__." : searching under dir '$indir' with pattern '".$pattern."' ...\n" }

	if( ! defined $self->input_images([
		# this little piglet does not support unicode
		# or, rather, readdir() needs some patching
		# additionally, it fails in M$ as the unicoded
		# filenames get doubly encoded, let's see if this will fix it:
		($^O eq 'MSWin32')
			?
			    File::Find::Rule
				->file()
				->name($pattern)
				->in($indir)
			:
			    map { Encode::decode_utf8($_) }
			    File::Find::Rule
				->file()
				->name($pattern)
				->in(Encode::encode_utf8($indir))
	]) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, call to input_images() has failed.\n"; return 0 }

	return 1 # success
}
# This adds many patterns:
# the input is an ARRAY of 1-or-2-item arrays
# each subarray must consist of a pattern and optionally a search dir (else current dir will be used)
sub	input_patterns {
	my ($self, $specs) = @_;
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $verbos = $self->verbosity();
	for my $as (@$specs){
		if( (scalar(@$as)==0)
		 || (scalar(@$as)>2)
		){ print STDERR perl2dump($as)."${whoami} (via $parent), line ".__LINE__." : error, the spec must contain at least a pattern and optionally a search-dir as an array, see above.\n"; return 0; }
		if( ! $self->input_pattern($as) ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : error, call to input_pattern() has failed for this spec: @$as\n"; return 0 }
	}
	return 1 # success
}
# if no parameter is specified then it returns the current list of input images as an arrayref
# Otherwise:
# specify one or more input filenames (of images) via a single scalar, an arrayref or
# a hashref whose values are image filenames, to convert them into video
# in this case returns undef on failure or the current, updated list of input images on success
sub	input_images {
	my ($self, $m) = @_;
	if( ! defined $m ){ return $self->{'input-images'} }
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];
	my $verbos = $self->verbosity();
	if( $verbos > 0 ){
		if( $verbos > 1 ){ print STDOUT perl2dump($m)."${whoami} (via $parent), line ".__LINE__." : called with input images as shown above ...\n" }
		else { print STDOUT "${whoami} (via $parent), line ".__LINE__." : called ...\n" }
	}
	# NOTE: Cwd::abs_path() messes up on unicode filenames and requires Encode::decode_utf8()
	# but there is also Cwd::utf8 to consider sometime...
	my $rf = ref $m;
	if( $rf eq 'ARRAY' ){
		for my $af (@$m){
			if( ! -e $af ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : warning/1, input image '$af' does not exist on disk and will be ignored.\n"; next }
			push @{$self->{'input-images'}}, _my_abs_path($af);
		}
	} elsif( $rf eq 'HASH' ){
		for my $af (values %$m){
			if( ! -e $af ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : warning/2, input image '$af' does not exist on disk and will be ignored.\n"; next }
			push @{$self->{'input-images'}}, _my_abs_path($af);
		}		
	} elsif( $rf eq '' ){
		if( ! -e $m ){ print STDERR "${whoami} (via $parent), line ".__LINE__." : warning/3, input image '$m' does not exist on disk and will be ignored.\n"; }
		else { push @{$self->{'input-images'}}, _my_abs_path($m) }
	} else { print STDERR "${whoami} (via $parent), line ".__LINE__." : error, input can be an arrayref of input image filenames, a hashref whose values are filenames or a single filename in the form of a scalar."; return undef }
	if( $verbos > 1 ){ print STDOUT perl2dump($self->{'input-images'})."${whoami} (via $parent), line ".__LINE__." : called and added some images, above is a list of all input images to create the animation.\n" }
	return $self->{'input-images'}
}

sub _my_cwd {
	return cwd()
}
# NOTE: unicode filenames may not be canonicalised
# e.g. iota-including-accent and iota with separate accent.
# the OS will not care but if you do comparisons you will fail
# So, consider canonicalising the filenames if you are doing comparison
# e.g. in the tests
# see https://perlmonks.org/?node_id=11156629
# Also, Cwd needs utf8 decode but Cwd::utf8 doesn't
# And File::Find::Rule needs also utf8 decoce unless it is chained to abs_path
sub _my_abs_path {
	#return Encode::decode_utf8(abs_path($_[0])) # for plain Cwd
	return abs_path($_[0]) # for Cwd::utf8
}

# that's the end, pod now starts

=pod

=encoding UTF-8

=head1 NAME

Automate::Animate::FFmpeg - Create animation from a sequence of images using FFmpeg

=head1 VERSION

Version 0.12


=head1 SYNOPSIS

This module creates an animation from a sequence of input
images using L<FFmpeg|https://ffmpeg.org>.
An excellent, open source program.

FFmpeg binaries must already be installed in your system.

    use Automate::Animate::FFmpeg;
    my $aaFFobj = Automate::Animate::FFmpeg->new({
      # specify input images in any of these 4 ways or a combination:
      # 1) by specifying each input image (in the order to appear)
      #    in an ARRAYref
      'input-images' => [
        '/xyz/abc/im1.png',
        '/xyz/abc/im2.png',
        ...
      ],
      # 2) by specifying an input pattern (glob or regex)
      #    and optional search path
      'input-pattern' => ['*.png', './'],
      # 3) by specifying an ARRAY of input patterns
      #    (see above)
      'input-patterns' => [
          ['*.tiff'],
          # specify a regex to filter-in all files under search dir
	  # NOTE: observe the escaping rules for each quotation method you use
          [qw!regex(/photos2023-.+?\\.png/i)!, 'abc/xyz'],
      ],
      # 4) by specifying a file which contains filenames
      #    of the input images.
      'input-images-from-file' => 'file-containing-a-list-of-pathnames-to-images.txt',

      # optionally specify the duration of each frame=image
      'frame-duration' => 5.3, # seconds

      'output-filename' => 'out.mp4',
    });
    # no animation yet!

    # options can be set after construction as well:

    # optionally add some extra params to FFmpeg as an arrayref
    $aaFF->ffmpeg_extra_params(['-x', 'abc', '-y', 1, 2, 3]);

    # you can also add images here, order is important
    $aaFF->input_images(['img1.png', 'img2.png']) or die;

    # or add images via a search pattern and optional search dir
    $aaFF->input_pattern(['*.png', './']);

    # or add images via multiple search patterns
    $aaFF->input_patterns([
	['*.png', './'],
	['*.jpg', '/images'],
	['*.tiff'], # this defaults to current dir
    ]) or die;

    # and make the animation:
    die "make_animation() has failed"
      unless $aaFF->make_animation()
    ;

=head1 INSTALLATION

During "making the makefile" (C<perl Makefile.PL>),
there will be a check to locate the binary C<ffmpeg>
in your system. At first it checks if the environment
variable C<AUTOMATE_ANIMATE_FFMPEG_PATH> is set, for example,
in *nix, you can set this variable and do the installation like this:

    AUTOMATE_ANIMATE_FFMPEG_PATH=/abc/xyz/ffmpeg perl Makefile.PL

Or, if you do not have direct control to the installation process
(e.g. via cpan/cpanm/package-manager) do it like this:

    export AUTOMATE_ANIMATE_FFMPEG_PATH=/abc/xyz/ffmpeg
    cpan -i Automate::Animate::FFmpeg

Or, like this:

    # this opens a shell after fetching the module tarball and unpacking it
    cpanm --look Automate::Animate::FFmpeg
    export AUTOMATE_ANIMATE_FFMPEG_PATH=/abc/xyz/ffmpeg
    perl Makefile.PL
    ...

If the environment variable C<AUTOMATE_ANIMATE_FFMPEG_PATH> was not set,
the installer will search in the "usual" locations for the ffmpeg
binaries. This is done by L<File::Which>'s C<which()>.

If nothing was found, then it is assumed that C<ffmpeg> is not installed.
B<But>, the installation will proceed with a warning. Tests
will be run, but they too will succeed (with a warning) on the
absence of an C<ffmpeg> executable.
The location
to the C<ffmpeg> binaries will be left undefined in the module's
installed scripts and the module will be totally unusable.
This choice was made in order not to fail the tests when
C<ffmpeg> is missing from test machines.

Installation of C<ffmpeg> binaries is straightforward from
their L<website|https://ffmpeg.org//download.html> for Linux, OSX
and windows, if you are still using it. Many Linux distributions
offer C<ffmpeg> via their package managers. That, or
download a static build from said website.

=head1 METHODS

=head2 C<new>

  my $ret = Automate::Animate::FFmpeg->new({ ... });

All arguments are supplied via a hashref with the following keys:

=over 4

=item * C<input-images> : an array of pathnames to input images. Image types can be what ffmpeg understands: png, jpeg, tiff, and lots more.

=item * C<input-pattern> : an arrayref of 1 or 2 items. The first item is the pattern
which complies to what L<File::Find::Rule> understands (See [https://metacpan.org/pod/File::Find::Rule#Matching-Rules]).
For example C<*.png>, regular expressions can be passed by enclosing them in C<regex(/.../modifiers)>
and should include the C<//>. Modifiers can be after the last C</>. For example C<regex(/\.(mp3|ogg)$/i)>.

The optional second parameter is the search path. If not specified, the current working dir will be used.

Note that there is no implicit or explicit C<eval()> in compiling the user-specified
regex (i.e. when pattern is in the form C<regex(/.../modifiers)>).
Additionally there is a check in place for the user-specified modifiers to the regex:
C<die "never trust user input" unless $modifiers=~/^[msixpodualn]+$/;>.
Thank you L<Discipulus|https://www.perlmonks.org/?node_id=174111>.

=item * C<input-patterns> : same as above but it expects an array of C<input-pattern>.

=item * C<input-images-from-file> : specify the file which contains pathnames to image files, each on its own line.

=item * C<ffmpeg-extra-params> : pass extra parameters to the C<ffmpeg> executable as an arrayref of arguments, each argument must be a separate item as in : C<['-i', 'file']>.

=item * C<frame-duration> : set the duration of each frame (i.e. each input image) in the animation in (fractional) seconds.

=item * C<qw/verbosity> : set the verbosity, 0 being mute.

=back

Return value:

=over 4

=item * C<undef> on failure or the blessed object on success.

=back

This is the constructor. It instantiates the object which does the animations. Its
input parameters can be set also via their own setter methods.
If input images are specified during construction then the list
of filenames is constructed and kept in memory. Just the filenames.

=head2 C<make_animation()>

  $aaFF->make_animation() or die "failed";

It initiates the making of the animation by shelling out to C<ffmpeg>
with all the input images specified via one or more calls to any of:

=over 2

=item * input_images($m)

=item * input_pattern($m)

=item * input_patterns($m)

=item * input_file_with_images($m)

=back

On success, the resultant animation will be
written to the output file
(specified using L<output_filename($m)> before the call.

Return value:

=over 4

=item * 0 on failure, 1 on success.

=back

=head2 C<input_images($m)>

  my $ret = $aaFF->input_images($m);

It sets or gets the list (as an ARRAYref) of all input images currently in the list
of images to create the animation. The optional input parameter, C<$m>,
is an ARRAYref of input images (their fullpath that is) to create
the animation.

Return value:

=over 4

=item * the list, as an ARRAYref, of the image filenames currently
set to create the animation.

=back

=head2 C<input_pattern($m)>

  $aaFF->input_pattern($m) or die "failed";

Initiates a search via L<File::Find::Rule> for the
input image files to create the animation using
the pattern C<$m-E<gt>[0]> with starting search dir being C<$m-E<gt>[1]>,
which is optional -- default being C<Cwd::cwd> (current working dir).
So, C<$m> is an array ref of one or two items. The first is the search
pattern and the optional second is the search path, defaulting to the current
working dir.

The pattern (C<$m-E<gt>[0]>) can be a shell wildcard, e.g. C<*.png>,
or a regex specified as C<regex(/REGEX-HERE/modifiers)>, for example
C<regex(/\.(mp3|ogg)$/i)> Both shell wildcards and regular expressions
must comply with what L<File::Find::Rule> expects, see [https://metacpan.org/pod/File::Find::Rule#Matching-Rules].

The results of the search will be added to the list of input images
in the order of appearance.

Multiple calls to C<input_pattern()> will load
input images in the order they are found.

C<input_pattern()> can be combined with C<input_patterns()>
and C<input_images()>. The input images list will increase
in the order they are called.

B<Caveat>: the regex is parsed, compiled and passed on to L<File::Find::Rule>.
Escaping of special characters (e.g. the backslash) may be required.

B<Caveat>: the order of the matched input images is entirely up
to L<File::Find::Rule>. There may be unexpected results
when filenames contain unicode characters. Consider
these orderings for example:

=over 2

=item * C<blue.png, κίτρινο.png, red.png>,

=item * C<blue.png, γάμμα.png, κίτρινο.png, red.png>,

=item * C<blue.png, κίτρινο.png, γαμμα.png red.png>,

=back

Return value:

=over 4

=item * 0 on failure, 1 on success.

=back

=head2 C<input_patterns($m)>

  $aaFF->input_patterns($m) or die "failed";

Argument C<$m> is an array of arrays each composed of one or two items.
The first argument, which is mandatory, is the search pattern.
The optional second argument is the directory to start the search.
For each item of C<@$m> it calls L<input_pattern($m)>.

C<input_patterns()> can be combined with C<input_pattern()>
and C<input_images()>. The input images list will increase
in the order they are called.

Return value:

=over 4

=item * 0 on failure, 1 on success.

=back

=head2 C<output_filename($m)>

  my $ret = $aaFF->output_filename($m);

It sets or gets the output filename of the animation.

When setting an output filename, make sure you
specify its extension and it does make sense to FFmpeg (e.g. mp4).

Return value:

=over 4

=item * the current output filename.

=back

=head2 C<input_file_with_images($m)>

  $aaFF->input_file_with_images($m) or die "failed";

Reads file C<$m> which must contain filenames, one filename
per line, and adds the up to the list of input images to create the
animation.

Return value:

=over 4

=item * 0 on failure, 1 on success.

=back

=head2 C<num_input_images()>

  my $N = $aaFF->num_input_images();

Return value:

=over 4

=item * on success, it returns the number of input images currently
in the list to create the animation. On failure, or when there
are now images to create the animation, it returns 0.

=back

=head2 C<clear_input_images()>

  $aaFF->clear_input_images();

It clears the list of input images to create an animation.
Zero, null, it's over for Bojo.

=head2 C<ffmpeg_executable()>

  my $ret = $aaFF->ffmpeg_executable();

You can not change the path to the executable mid-stream.

Return value:

=over 4

=item * on success, it returns the path to C<ffmpeg> executable
as it was set during module installation.
The return value will be C<undef> if C<ffmpeg> executable was not
detected during installation.

=back

=head2 C<verbosity($m)>

  my $ret = $aaFF->verbosity($m);

It sets or gets the verbosity level. Zero being mute.

Return value:

=over 4

=item * the current verbosity level.

=back

=head2 C<frame_duration($m)>

  my $ret = $aaFF->frame_duration($m);

It sets or gets the frame duration in (fractional) seconds.
Frame duration is the time that each frame(=image) appears
in the produced animation.

Return value:

=over 4

=item * the current frame duration in (fractional) seconds.

=back

=head1 SCRIPTS

A script for making animations from input images using C<ffmpeg>
is provided: C<automate-animate-ffmpeg.pl>.

It accepts the following options:

    --input-image I [--input-image I2 ...] : specify the full path of an
    image to be added to the animation. Multiple images are expected.

      OR

    --input-images-from-file F [--input-images-from-file F2 ...] :
    specify a file which contains a list of input images to be
    animated, each on its own line. Multiple images are expected.

      OR

    --input-pattern/-p P [D] : specify a pattern and optional search
    dir to select the files from disk. This pattern must be accepted
    by File::Find::Rule::name(). If search dir is not specified,
    the current working dir will be used.

    --output-filename/-o O : the filename of the output animation.

    [--frame-duration/-d SECONDS : specify the duration of each
    frame=input image in (fractional) seconds.]

    [--verbosity/-V N : specify verbosity. Zero being the mute.
    Default is 0.]

As an example,

    automate-animate-ffmpeg.pl \
       --input-pattern '*.png' 't/t-data/images' \
       --output-filename out.mp4 \
       --frame-duration 3.5

    # or

    automate-animate-ffmpeg.pl \
       --input-pattern 'regex(/.+?.png/i)' \
       --output-filename out.mp4 \
       --frame-duration 3.5

=head2 UNICODE FILENAMES

Unicode filenames are supported ... I think. Please report
any problems.


=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-automate-animate-ffmpeg at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Automate-Animate-FFmpeg>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Automate::Animate::FFmpeg


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Automate-Animate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Automate-Animate>

=item * Review this module at PerlMonks

L<https://www.perlmonks.org/?node_id=21144>

=item * Search CPAN

L<https://metacpan.org/release/Automate-Animate>

=back


=head1 ACKNOWLEDGEMENTS

=over 2

=item * A big thank you to L<FFmpeg|https://ffmpeg.org>, an
excellent, open source software for all things moving.

=item * A big thank you to L<PerlMonks|https://perlmonks.org>
for the useful L<discussion|https://perlmonks.org/?node_id=11156484>
on parsing command line arguments as a string. And an even bigger
thank you to L<PerlMonks|https://perlmonks.org> for just being there.

=item * On compiling a regex when pattern and modifiers are in
variables, L<discussion|https://www.perlmonks.org/?node_id=1210675>
at L<PerlMonks|https://perlmonks.org>.

=item * A big thank you to Ace, the big dog. Bravo Ace!

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Andreas Hadjiprocopis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Automate::Animate::FFmpeg
