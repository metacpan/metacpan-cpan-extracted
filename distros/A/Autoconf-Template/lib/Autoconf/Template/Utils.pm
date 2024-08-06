package Autoconf::Template::Utils;

use strict;
use warnings;

use Autoconf::Template::Constants qw(:all);
use Carp;
use English qw(-no_match_vars);
use Data::Dumper;
use Date::Format qw(time2str);
use File::Basename qw(fileparse basename dirname);
use File::Path qw(make_path);
use File::Find;
use File::ShareDir qw(dist_dir);
use List::Util qw(any none pairs);
use Scalar::Util qw(reftype);
use Log::Log4perl qw(:easy);
use Log::Log4perl::Level;
use JSON;
use Template;
use YAML qw(Load LoadFile DumpFile);

use parent qw(Exporter);

our @EXPORT_OK = qw(
  create_path
  expand_filename
  filter_list
  find_files
  find_files_of_type
  find_module_filename
  find_root_dir
  flatten_filename
  get_project_meta_data
  get_subdirs
  get_subdir_by_type
  init_logger
  is_exclude_dir
  message
  module_to_path
  path_to_module
  render_tt_template
  save_project_meta_data
  slurp_file
  strip_in
  timestamp
  to_boolean
  version
);

our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

our %LOG4PERL_LEVELS = (
  trace => $TRACE,
  debug => $DEBUG,
  info  => $INFO,
  warn  => $WARN,
  error => $ERROR,
);

########################################################################
sub version {
########################################################################
  my ($version) = @_;

  print basename($PROGRAM_NAME) . " v$version\n\n";
  print $COPYRIGHT;

  return;
}

########################################################################
sub get_subdir_by_type {
########################################################################
  my ($file) = @_;

  $file =~ s/[.]in$//xsm;

  my ( $name, $path, $ext ) = fileparse( $file, qr/[.][^.]+$/xsm );

  return ( $SUBDIRS_BY_TYPE{$ext}, $ext );
}

########################################################################
sub remove_empty_dirs {
########################################################################
  my ($dirs) = @_;

  my @empty;

  $dirs //= {};

  foreach my $p ( pairs %{$dirs} ) {
    my ( $path, $files ) = @{$p};
    next if @{$files};

    if ( none { $path ne $_ && $_ =~ /^$path/xsm } keys %{$dirs} ) {
      push @empty, $path;
    }
  }

  foreach (@empty) {
    delete $dirs->{$_};
  }

  return $dirs;
}

########################################################################
sub get_subdirs {
########################################################################
  my ( $path, $dirs ) = @_;

  $dirs //= {};

  opendir my $fh, "$path"
    or croak "could not open directory: $OS_ERROR";

  while ( my $file = readdir $fh ) {

    next if $file =~ /^[t.][.]?$/xsm;

    if ( -d "$path/$file" ) {
      $dirs->{"$path/$file"} = [];
      $dirs = get_subdirs( "$path/$file", $dirs );
    }
    else {
      if ( $file =~ /[.]pm[.]in$/xsm ) {
        push @{ $dirs->{$path} }, $file;
      }
    }
  }

  closedir $fh;

  return remove_empty_dirs($dirs);
}

########################################################################
sub filter_list {
########################################################################
  my ( $files, $srcdir, @filter ) = @_;

  TRACE Dumper( [ files => $files, filter => \@filter ] );

  my @filtered_list;

  foreach my $file ( @{$files} ) {

    my $dirname = dirname $file;
    TRACE Dumper( [ dirname => $dirname, file => $file ] );

    $dirname = $dirname eq $DOT ? $EMPTY : "$dirname/";

    my $exclude;

    foreach my $f (@filter) {

      my $pattern = $f;

      if ( ref $pattern && reftype($pattern) eq 'REGEXP' ) {
        TRACE Dumper( [ file => $file, regexp => $pattern ] );

        if ( $file =~ $pattern ) {
          $exclude = $TRUE;
          TRACE Dumper( [ excluding => $file ] );
          last;
        }
      }
      else {
        TRACE Dumper( [ file => $file, pattern => $pattern ] );

        if ( $file eq $pattern ) {
          TRACE Dumper( [ excluding => $file ] );

          $exclude = $TRUE;
          last;
        }
      }

    }

    next if $exclude;

    push @filtered_list, $file;
  }

  return @filtered_list;
}

########################################################################
sub flatten_filename {
########################################################################
  my ( $filename, $sep ) = @_;

  $sep //= $DASH;

  my $name;

  if ( $filename =~ /[.]pm/xsm ) {
    $name = path_to_module($filename);
    $name =~ s/::/$sep/gxsm;
  }
  else {
    $name = basename $filename;
    $name =~ s/[.].*$//xsm;
  }

  return lc $name;
}

########################################################################
sub expand_filename {
########################################################################
  my ($file) = @_;

  if ( $file =~ /^[~]/xsm ) {
    croak "no \$HOME environment variable set\n"
      if !$ENV{HOME};

    $file =~ s/~/$ENV{HOME}/xsm;
  }

  return $file;
}

########################################################################
sub strip_in {
########################################################################
  my ($arg) = @_;

  if ( ref $arg ) {
    for ( @{$arg} ) {
      s/[.]in$//xsm;
    }
  }
  else {
    $arg =~ s/[.]in$//xsm;
  }

  TRACE Dumper( 'strip_in', $arg );

  return $arg;
}

########################################################################
sub find_files {
########################################################################
  my ( $path, $type, $strip_in ) = @_;
  $type //= 'pm';

  return find_files_of_type(
    path  => $path,
    type  => $type,
    ext   => '.in',
    strip => $strip_in
  );
}

########################################################################
sub is_exclude_dir {
########################################################################
  my ( $name, $exclude_dirs ) = @_;

  foreach my $dir ( @{$exclude_dirs} ) {
    if ( !ref $dir ) {
      $dir = qr/^$dir/xsm;
    }

    DEBUG Dumper(
      [ reftype => reftype($dir),
        dir     => $dir,
        name    => $File::Find::name
      ]
    );

    return $TRUE
      if $File::Find::name =~ $dir;
  }

  return $FALSE;
}

########################################################################
sub find_files_of_type {
########################################################################
  my (%args) = @_;

  my ( $path, $type, $ext, $strip_in, $exclude_dirs )
    = @args{qw(path type ext strip exclude_dirs)};

  return ()
    if !-d $path;

  $ext //= $EMPTY;

  my @files;

  TRACE sprintf 'looking for files of type %s in %s', $type, $path;

  find(
    sub {
      return
        if -d $_ || !/[.]$type$ext$/xsm;

      return
        if is_exclude_dir( $File::Find::name, $exclude_dirs );

      my $name = $File::Find::name;

      if ($strip_in) {
        $name = strip_in($name);
      }

      push @files, $name;
    },
    $path
  );

  TRACE 'found files: ', join "\n", @files;

  return @files;
}

########################################################################
sub path_to_module {
########################################################################
  my ($path) = @_;

  my $module = $path;

  $module =~ s/\//::/gxsm;
  $module =~ s/[.]pm.*$//xsm;

  return $module;
}

########################################################################
sub module_to_path {
########################################################################
  my ($module) = @_;

  $module =~ s/::/\//gxsm;

  return "$module.pm";
}

########################################################################
sub timestamp {
########################################################################
  my @now = localtime;
  $now[5] += 1900;
  $now[4] += 1;

  my %timestamp;

  $timestamp{date} = {
    year  => $now[5],
    month => $now[4],
    day   => $now[3],
  };

  # Fri Feb 10 14:16:12 2023
  $timestamp{timestamp} = time2str( '%a %b %e %H:%M:%S %Y', time );

  return %timestamp;
}

# give an fqp to a Perl module, we just want the portion of the path
# that reflects the package name...so if Foo::Bar is found at
# '/tmp/foo/Foo/Bar.pm' we return: 'Foo/Bar.pm'
########################################################################
sub find_module_filename {
########################################################################
  my ($file) = @_;

  # if file does not exist it should be listed in manifest as something
  # like: Foo/Bar.pm but we'll create it later
  return $file
    if !-e $file;

  my $module = slurp_file($file);

  if ( $module =~ /package\s+([^;]+)/xsm ) {
    return module_to_path($1);
  }

  return;
}

########################################################################
sub slurp_file {
########################################################################
  my ( $file, %options ) = @_;

  my $type = lc( $options{type} // $EMPTY );

  if ( any { $type eq $_ } qw(json yaml dmp) ) {
    $options{comments} = $FALSE;
  }

  $options{comments} //= $TRUE; # leave comments

  local $RS = undef;

  open my $fh, '<', $file
    or croak "could not open $file";

  my $content = <$fh>;

  close $fh;

  if ( !$options{comments} ) {
    while ( $content =~ s/^[\#][^\n]*$//gxsm ) { }
  }

  return decode_json($content)
    if $type eq 'json';

  return Load($content)
    if $type eq 'yaml';

  return eval "$content" ## no critic (ProhibitStringyEval)
    if $type eq 'dmp';

  return $content;
}

########################################################################
sub render_tt_template {
########################################################################
  my (@in) = @_;

  my %args;

  if ( ref $in[0] && reftype( $in[0] ) eq 'HASH' ) {
    %args = %{ $in[0] };
  }
  else {
    @args{qw(template parameters outfile)} = @in;
  }

  my ( $template, $parameters, $outfile )
    = @args{qw( template parameters outfile)};

  my @cleanup = @{ $args{cleanup} || [] };

  TRACE Dumper(
    [ 'rendering template:' => $template,
      'to outfile:'         => $outfile,
      'cleanup:'            => $args{cleanup},
      'parameters:'         => $parameters,
      'INCLUDE_PATH:'       => Dumper( [$INCLUDE_PATH] ),
    ]
  );

  my $tt = Template->new(
    { INCLUDE_PATH => [ $INCLUDE_PATH, dist_dir('Autoconf-Template') ],
      ABSOLUTE     => $TRUE,
      INTERPOLATE  => $FALSE,
      FILTERS      => {
        to_am_var => sub {
          my $text = shift;
          $text =~ s/\//_/xmsg;
          return $text;
        }
      },

    }
  );

  my $content = $EMPTY;

  croak sprintf "error rendering template: %s\n", $tt->error()
    if !$tt->process( $template, $parameters, \$content );

  if ( any { $_ eq 'nl' } @cleanup ) {
    TRACE 'cleaning up multiple new lines...';

    while ( $content =~ s/\n\n\n/\n/xsmg ) { }
  }

  if ($outfile) {

    create_path($outfile);

    open my $fh, '>', $outfile
      or croak sprintf 'could not open [%s] for writing: %s', $outfile,
      $OS_ERROR;

    print {$fh} $content;

    close $fh;
  }

  return $content;
}

{
  my $meta_data;

########################################################################
  sub get_project_meta_data {
########################################################################
    my ($options) = @_;

    return %{$meta_data}
      if $meta_data;

    my ( $project, $destdir ) = find_root_dir($options);

    my $meta_data_file;

    if ( $destdir && $project ) {
      $meta_data_file = sprintf '%s/%s/project.yaml', $destdir, $project;
    }
    elsif ( $options->{'project-root'} ) {
      $meta_data_file = sprintf '%s/project.yaml', $options->{'project-root'};
    }

    $meta_data = eval { return LoadFile($meta_data_file) };

    return %{ $meta_data || {} };
  }
}

########################################################################
sub to_boolean {
########################################################################
  my ($val) = @_;

  $val //= $EMPTY;

  return ( any { $val eq $_ } qw(true 1 on yes) ) ? $TRUE : $FALSE;
}

########################################################################
sub save_project_meta_data {
########################################################################
  my ( $options, $meta_data ) = @_;

  $meta_data->{updated_date} = scalar localtime;

  foreach ( keys %BOOLEAN_OPTIONS ) {
    $meta_data->{$_} = to_boolean( $meta_data->{$_} ) ? 'true' : 'false';
  }

  DumpFile( sprintf( '%s/project.yaml', $options->{root} ), $meta_data );

  return;
}

########################################################################
sub find_root_dir {
########################################################################
  my ($options) = @_;

  my ( $project, $destdir );

  # see if we can figure out what project we are in...
  if ( $options->{'project-root'} ) {
    my %meta_data = get_project_meta_data($options);

    if ( keys %meta_data ) {
      $project = $meta_data{project};
      $destdir = dirname $options->{'project-root'};
    }
  }
  elsif ( -e 'Makefile' ) {
    # PACKAGE_NAME is the project name, so if you are anywhere in the
    # build tree and have a 'Makefile' there I can probably find
    # the project name...
    my $makefile = slurp_file('Makefile');

    if ( $makefile =~ /^PACKAGE_NAME\s=\s([^\n]+)$/xsm ) {
      $project = $1;
    }

    if ( $makefile =~ /^abs_top_srcdir\s=\s([^\n]+)$/xsm ) {
      # init_parameters() will create destdir from project and
      # destdir, so we want the the directory preceding the root of the
      # project directory...
      $destdir = dirname $1;
    }
  }

  croak
    q{Unable to find the root of your project. Use --project-root option or run 'configure'}
    if !$project || !$destdir;

  @{$options}{qw(destdir project)} = ( $destdir, $project );

  return ( $project, $destdir );
}

########################################################################
sub message {
########################################################################
  my ( $options, @message ) = @_;

  return if $options->{quiet};

  return print {*STDOUT} "@message\n";
}

########################################################################
sub init_logger {
########################################################################
  my ($level) = @_;

  $level //= 'info';

  $level = $LOG4PERL_LEVELS{$level} || $INFO;

  if ( $ENV{DEBUG} ) {
    $level = $ENV{DEBUG} > 1 ? $TRACE : $DEBUG;
  }

  Log::Log4perl->easy_init(
    { level  => $level,
      file   => '>>autoconf-template-perl.log',
      layout => '%d (%r/%R) (%p) %l %m%n',
    }
  );

  return get_logger();
}

########################################################################
sub create_path {
########################################################################
  my ($file) = @_;

  my ( $name, $path, $ext ) = fileparse( $file, qr/[.][^.]+$/xsm );

  if ( !-d $path ) {
    make_path($path);
  }

  return -d $path;
}

1;

## no critic (RequirePodSections)

__END__

=pod

=head1 NAME

AutoConf::Utils - Collection of useful utilities used across multiple
C<autoconf-template-perl> scripts.

=head1 SYNOPSIS

 use AutoConf::Utils qw(find_files_of_type);

=head1 DESCRIPTION

Useful utilities collected here to reduce the bulk and increase
maintainability in C<autoconf-template-perl> scripts.

=head1 METHODS AND SUBROUTINES

=head2 find_files_of_type

 filed_files_of_type(args)

Traverses a path looking for files of a given type. Returns a list of
absolute paths to the files found. Accepts of hash of arguments described below.

=over 5

=item * path

Absolute (or relative) path to search. Note that files are returned
with their absolute paths regardless of whether path is relative or
absolute.

=item * type

Type (extension without .) of the files to find.

Example: 'pm'

=item * ext

Additional extension to include in search for type (typically C<.in>).

=item * exclude_dirs

Array of directories to skip.

=item * strip_in

Boolean that indicates C<.in> extensions should be removed.

=back

Example:

  my @files = find_files_of_type(
    type => 'pm',
    ext  => '.in',
    path => $path,
  );

=head1 AUTHOR

Rob Lauer - <rlauer@usgn.net>

=cut
