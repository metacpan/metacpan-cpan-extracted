#!/usr/bin/perl -T

# MonkeyPatched version of test to get some diagnostics from tempdir

use File::Spec;
use File::Temp qw(tempdir);

use Carp;
use Scalar::Util qw(tainted);
use Mock::MonkeyPatch;

####### Monkeypatch File::Temp::tempdir

sub _patched_tempdir  {
  if ( @_ && $_[0] eq 'File::Temp' ) {
      croak "'tempdir' can't be called as a method";
  }
  carp "verifying in the monkeypatched function";
  return Mock::MonkeyPatch::ORIGINAL(@_) if (($^O eq 'VMS') || ($^O eq 'MacOS') || scalar(@_) != 3);

  # Can not check for argument count since we can have any
  # number of args

  # Default options
  my %options = (
                 "CLEANUP"    => 0, # Remove directory on exit
                 "DIR"        => '', # Root directory
                 "TMPDIR"     => 0,  # Use tempdir with template
                );

  # Check to see whether we have an odd or even number of arguments
  my ($maybe_template, $args) = File::Temp::_parse_args(@_);
  carp "options args->{DIR} $args->{DIR}" if tainted($args->{DIR});
  my $template = @$maybe_template ? $maybe_template->[0] : undef;

  # Read the options and merge with defaults
  %options = (%options, %$args);
  carp "options dir 1 $options{DIR}" if tainted($options{'DIR'});

  # Modify or generate the template

  # Deal with the DIR and TMPDIR options
  if (defined $template) {
    carp "tempdir called with tainted template $template" if tainted($template);
    # Need to strip directory path if using DIR or TMPDIR
    if ($options{'TMPDIR'} || $options{'DIR'}) {

      carp "options dir 2 $options{DIR}" if tainted($options{'DIR'});
      # Strip parent directory from the filename
      #
      # There is no filename at the end
      my ($volume, $directories, undef) = File::Spec->splitpath( $template, 1);

      # Last directory is then our template
      $template = (File::Spec->splitdir($directories))[-1];
      carp "tempdir after spltdir tainted template $template" if tainted($template);

      # Prepend the supplied directory or temp dir
      if ($options{"DIR"}) {

	carp "options dir 3 $options{DIR}" if tainted($options{"DIR"});
	carp "tempdir before cattdir 1 tainted template $template" if tainted($template);
        $template = File::Spec->catdir($options{"DIR"}, $template);
	carp "tempdir after cattdir 1 tainted template $template" if tainted($template);

      } elsif ($options{TMPDIR}) {

        # Prepend tmpdir
        $template = File::Spec->catdir(File::Spec->tmpdir, $template);
	carp "tempdir after cattdir 2 tainted template $template" if tainted($template);

      }
    }

  } else {

    if ($options{"DIR"}) {

      $template = File::Spec->catdir($options{"DIR"}, TEMPXXX);
      carp "tempdir after cattdir 3 tainted template $template" if tainted($template);

    } else {

      $template = File::Spec->catdir(File::Spec->tmpdir, TEMPXXX);
      carp "tempdir after cattdir 4 tainted template $template" if tainted($template);

    }

  }
  carp "tempdir after cattdir if block tainted template $template" if tainted($template);
  
  # Create the directory
  my $tempdir;
  my $suffixlen = 0;

  my $errstr;
  croak "Error in tempdir() using $template: $errstr"
    unless ((undef, $tempdir) = File::Temp::_gettemp($template,
                                         "open" => 0,
                                         "mkdir"=> 1 ,
                                         "suffixlen" => $suffixlen,
                                         "ErrStr" => \$errstr,
                                        ) );

  # Install exit handler; must be dynamic to get lexical
  if ( $options{'CLEANUP'} && -d $tempdir) {
    _deferred_unlink(undef, $tempdir, 1);
  }

  # Return the dir name
  return $tempdir;

}

### MonkeyPatch the Unix implementation of File::Spec->catdir
sub _patched_pp_canonpath {
    my ($self,$path) = @_;
    return unless defined $path;

    carp "Entered patched File::Spec->canonpath";
    carp "canonpath path 0 $path is tainted" if tainted($path);
    my $node = '';
    my $double_slashes_special = $^O eq 'qnx' || $^O eq 'nto';

    if ( $double_slashes_special
         && ( $path =~ s{^(//[^/]+)/?\z}{}s || $path =~ s{^(//[^/]+)/}{/}s ) ) {
      $node = $1;
    }
    carp "canonpath node 1 $node is tainted" if tainted($node);
    $path =~ s|/{2,}|/|g;                            # xx////xx  -> xx/xx
    carp "canonpath path 1 $path is tainted" if tainted($path);
    $path =~ s{(?:/\.)+(?:/|\z)}{/}g;                # xx/././xx -> xx/xx
    carp "canonpath path 2 $path is tainted" if tainted($path);
    $path =~ s|^(?:\./)+||s unless $path eq "./";    # ./xx      -> xx
    carp "canonpath path 3 $path is tainted" if tainted($path);
    $path =~ s|^/(?:\.\./)+|/|;                      # /../../xx -> xx
    carp "canonpath path 4 $path is tainted" if tainted($path);
    $path =~ s|^/\.\.$|/|;                         # /..       -> /
    carp "canonpath path 5 $path is tainted" if tainted($path);
    $path =~ s|/\z|| unless $path eq "/";          # xx/       -> xx
    carp "canonpath path 6 $path is tainted" if tainted($path);
    carp "canonpath node 2 $node is tainted" if tainted($node);
    return "$node$path";
}

my $mock = Mock::MonkeyPatch->patch('File::Temp::tempdir' => \&_patched_tempdir);
die "MonkeyPatch tempdir failed" unless $mock;

my $mock2 = Mock::MonkeyPatch->patch('File::Spec::Unix::canonpath' => \&_patched_pp_canonpath);
die "MonkeyPatch canonpath failed" unless $mock2;

use Test::More tests => 1;

my $pathdir = $ENV{HOME};  # make variable tainted and set to an existing absolute directory 
(-d $pathdir) and File::Spec->file_name_is_absolute($pathdir);

my $workdir = File::Temp::tempdir("temp.XXXXXX", DIR => "log");

ok((-d $workdir), 'tempdir test');
