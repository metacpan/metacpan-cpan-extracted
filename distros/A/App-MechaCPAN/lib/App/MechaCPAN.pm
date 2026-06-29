package App::MechaCPAN;

use v5.14;
use warnings;

use Cwd qw/cwd/;
use Carp;
use Config;
use Symbol qw/geniosym/;
use autodie;
use Term::ANSIColor qw//;
use IPC::Open3;
use IO::Select;
use List::Util qw/first/;
use Scalar::Util qw/blessed openhandle/;
use File::Temp qw/tempfile tempdir/;
use File::Fetch;
use File::Spec qw//;
use Getopt::Long qw//;

use Exporter qw/import/;

BEGIN
{
  our @EXPORT_OK = qw/
    url_re git_re git_extract_re
    has_git has_updated_git min_git_ver
    can_https
    logmsg info success error
    dest_dir get_project_dir
    fetch_file inflate_archive
    file_digest_chk get_cpan_checksums
    humane_tmpname humane_tmpfile humane_tmpdir
    parse_cpanfile
    run run_qvf restart_script
    rel_start_to_abs
    /;
  our %EXPORT_TAGS = ( go => [@EXPORT_OK] );
}

our $VERSION = '0.32';

my @commands = qw/
  perl
  install
  deploy
  /;

foreach my $cmd ( @commands )
{
  my $pkg = __PACKAGE__ . "::" . ucfirst($cmd);
  local $@;
  my ($file, $line) = ( __FILE__, __LINE__+1);
  eval qq{#line $line "$file"\nrequire $pkg};
  die $@
    if $@;
}

my $loaded_at_compile;
my $restarted_key        = 'APP_MECHACPAN_RESTARTED';
my $is_restarted_process = delete $ENV{$restarted_key};

{
  no warnings 'void';
  INIT
  {
    $loaded_at_compile = 1;
  }
}

$loaded_at_compile //= 0;

our @args = (
  'diag-run!',
  'verbose|v!',
  'quiet|q!',
  'no-log!',
  'directory|d=s',
  'build-reusable-perl!',
  'verify!',
  'help|h!',
);

# Timeout when there's no output in seconds
our $TIMEOUT = $ENV{MECHACPAN_TIMEOUT} // 60;
our $VERBOSE;    # Print output from sub commands to STDERR
our $QUIET;      # Do not print any progress to STDERR
our $LOGFH;      # File handle to send the logs to
our $LOG_ON = 1; # Default if to log or not
our $PROJ_DIR;   # The directory given with -d or pwd if not provided
our $CHKSIGS;    # Check signatures on/off/best attempt (undef)

# In certain blocks, you may see `no warnings 'uninitialized'`. Several subs
# end up doing a lot of work with comparisions that don't distinguish between
# undef and the empty string, so these warnings create more noise than useful
# feedback, and the code to silence them are not meaningfully better

sub main
{
  my @argv = @_;

  if ( $0 =~ m/zhuli/ )
  {
    no warnings 'uninitialized';

    if ( $argv[0] =~ m/^do the thing/i )
    {
      success( "zhuli$$", 'Running deployment' )
        unless $is_restarted_process;
      $argv[0] = 'deploy';
    }
    if ( $argv[0] =~ m/^do$/i
      && $argv[1] =~ m/^the$/i
      && $argv[2] =~ m/^thing$/i )
    {
      success( "zhuli$$", 'Running deployment' )
        unless $is_restarted_process;
      @argv = ( 'deploy', @argv[ 3 .. $#argv ] );
    }
  }

  my @args = (
    @App::MechaCPAN::args,
    @App::MechaCPAN::Perl::args,
    @App::MechaCPAN::Install::args,
    @App::MechaCPAN::Deploy::args,
  );
  @args = keys %{ { map { $_ => 1 } @args } };

  if ( !@argv )
  {
    my $prog = ( File::Spec->splitpath($0) )[2] || 'mechacpan';

    my @options = map {
      my ($names) = m/^([^=:!+]+)/;
      join( ', ', map { length > 1 ? "--$_" : "-$_" } split /\|/, $names );
    } @App::MechaCPAN::args;

    my $orig_fh = select STDERR;

    say "Usage: $prog [options] <command> [<args>]";
    say "";
    say "Commands:";
    say "  $_"
      foreach @commands;
    say "";
    say "Global Options:";
    say "  $_"
      foreach @options;
    say "";
    say "Run '$prog --help' for full documentation.";

    select $orig_fh;
    return -1;
  }

  my $options = {};
  my $getopt_ret
    = Getopt::Long::GetOptionsFromArray( \@argv, $options, @args );
  return -1
    if !$getopt_ret;

  if ( $options->{help} )
  {
    require Pod::Usage;
    Pod::Usage::pod2usage(
      -input   => $INC{ _inc_pkg(__PACKAGE__) },
      -verbose => 2,
      -exitval => 'NOEXIT',
      -output  => \*STDOUT,
    );
    return 0;
  }

  my $merge_options = sub
  {
    my $arg = shift;
    if ( ref $arg eq 'HASH' )
    {
      $options = { %$arg, %$options };
      return 0;
    }
    return 1;
  };

  @argv = grep { $merge_options->($_) } @argv;

  my $orig_dir = cwd;
  if ( exists $options->{directory} )
  {
    if ( !-d $options->{directory} )
    {
      die "Cannot find directory: $options->{directory}\n";
    }
    chdir $options->{directory};
  }

  # Once we've established the project directory, we need to attempt to
  # restart the script.
  &restart_script();

  local $PROJ_DIR = cwd;
  local $LOGFH;
  local $VERBOSE = $options->{verbose} // $VERBOSE;
  local $QUIET   = $options->{quiet}   // $QUIET;
  local $CHKSIGS = $options->{verify}  // $CHKSIGS;

  my $cmd;

  if ( $options->{'build-reusable-perl'} )
  {
    $cmd = 'Perl';
    $options->{'build-reusable'} = delete $options->{'build-reusable-perl'};
    if ( lc $argv[0] eq 'perl' )
    {
      info("Option build-reusable-perl implies the perl command, it can be omitted");
      shift @argv;
    }
  }

  $cmd = $cmd // ucfirst lc shift @argv;

  my $pkg    = join( '::', __PACKAGE__, $cmd );
  my $action = eval { $pkg->can('go') };
  my $munge  = eval { $pkg->can('munge_args') };

  if ( !defined $action )
  {
    warn "Could not find action to run: $cmd\n";
    return -1;
  }

  if ( $options->{'diag-run'} )
  {
    warn "Would run '$cmd'\n";
    chdir $orig_dir;
    return 0;
  }

  $options->{is_restarted_process} = $is_restarted_process;

  if ( defined $munge )
  {
    @argv = $pkg->$munge( $options, @argv );
  }

  my $dest_dir = &dest_dir;
  if ( !-d $dest_dir )
  {
    mkdir $dest_dir;
  }

  _setup_log($dest_dir)
    unless $options->{'no-log'};

  local $@;
  my $ret = eval { $pkg->$action( $options, @argv ) || 0; };
  chdir $orig_dir;

  if ( !defined $ret )
  {
    error($@);
    return -1;
  }

  return $ret;
}

sub _git_str
{
  state $_git_str;

  if ( !defined $_git_str )
  {
    $_git_str = '';
    my $git_version_str = eval { run(qw/git --version/); };
    if ( defined $git_version_str )
    {
      ($_git_str) = $git_version_str =~ m/git version (\d+[.]\d+[.]\d+)/;
    }
  }

  return $_git_str;
}

sub min_git_ver
{
  return '1.7.7';
}

sub has_updated_git
{
  my $git_version_str = _git_str;
  if ($git_version_str)
  {
    use version 0.77;
    if ( version->parse($git_version_str) >= version->parse(min_git_ver) )
    {
      return 1;
    }
  }

  return;
}

sub has_git
{
  return _git_str && has_updated_git;
}

# Give a list of https-incapable File::Fetch methods when https is unavailable
sub _https_blacklist
{
  require Module::Load::Conditional;

  state $can_https
    = Module::Load::Conditional::can_load( modules => 'IO::Socket::SSL' );

  if ( !$can_https )
  {
    return qw/lwp httptiny httplite/;
  }

  return ();
}

sub can_https
{
  state $can_https;

  # track the blacklist for testing
  state $ff_blacklist;
  undef $can_https
    if $File::Fetch::BLACKLIST ne $ff_blacklist;

  if ( !defined $can_https )
  {
    my $test_url = 'https://get.mechacpan.us/latest';
    my $test_str = '';

    local $File::Fetch::WARN;
    local $@;

    my $ff = File::Fetch->new( uri => $test_url );
    return 0
      if !defined $ff;

    $ff_blacklist = $File::Fetch::BLACKLIST;

    # Make sure not to use methods that can't handle https
    local $File::Fetch::BLACKLIST = [ @$ff_blacklist, _https_blacklist ];
    $ff->scheme('http');
    $can_https = defined $ff->fetch( to => \$test_str );
  }

  return $can_https;
}

sub url_re
{
  state $url_re = qr[
    ^
    (?: ftp | http | https | file )
    : //
  ]xmsi;
  return $url_re;
}

sub git_re
{
  state $git_re = qr[
    ^ (?: git | ssh ) : [^:]
    |
    [.]git (?: @|$ )
  ]xmsi;
  return $git_re;
}

sub git_extract_re
{
  state $re = qr[
    ^
    (                   # git url capture
      .* ://
      (?: \w*@)?      # Might have an @ for user@url
      .*?               # Capture the rest
    )
    (?:                 # git commit id capture
      @
      ([^@]*)           # Evertyhing after @ is a commit_id
    )?
    $
  ]xmsi;

  return $re;
}

sub parse_cpanfile
{
  my $file       = shift;
  my @incl_types = @_;

  state $sandbox_num = 1;
  state @phases;
  @phases = qw/configure build test author/
    if !@phases;

  my $result = { runtime => {} };

  $result->{current} = $result->{runtime};

  my $methods = {
    on => sub
    {
      my ( $phase, $code ) = @_;
      local $result->{current} = $result->{$phase} //= {};
      $code->();
    },
    feature => sub {...},
  };

  foreach my $type (qw/requires recommends suggests conflicts/)
  {
    $methods->{$type} = sub
    {
      my ( $module, $ver ) = @_;
      if ( $module eq 'perl' )
      {
        $result->{perl} = $ver;
        return;
      }
      $result->{current}->{$type}->{$module} = $ver;
    };
  }

  foreach my $phase (@phases)
  {
    $methods->{ $phase . '_requires' } = sub
    {
      my ( $module, $ver ) = @_;
      $result->{$phase}->{requires}->{$module} = $ver;
    };
  }

  my $code_fh;
  if ( !($code_fh = openhandle($file) ) )
  {
    open $code_fh, '<', $file;
  }
  my $code = do { local $/; <$code_fh> };

  my $pkg = __PACKAGE__ . "::Sandbox$sandbox_num";
  $sandbox_num++;

  foreach my $method ( keys %$methods )
  {
    no strict 'refs';
    *{"${pkg}::${method}"} = $methods->{$method};
  }

  local $@;
  my $sandbox = join(
    "\n",
    qq[package $pkg;],
    qq[no warnings;],
    qq[# line 1 "$file"],
    qq[$code],
    qq[return 1;],
  );

  my $no_error = eval $sandbox;

  croak $@
    unless $no_error;

  delete $result->{current};

  if (@incl_types)
  {
    my %incl = ( map { $_ => 1 } @incl_types );

    foreach my $phase ( values %$result )
    {
      next
        if ref $phase ne 'HASH';

      foreach my $type ( keys %$phase )
      {
        if ( !$incl{$type} )
        {
          delete $phase->{$type};
        }
      }
    }
  }

  return $result;
}

sub humane_qr
{
  state $humane_re = qr[
    [.]
    \d{4} \d{2} \d{2}
    _
    \d{2} \d{2} \d{2}
    [.]
    \w{4}
  ]xmsi;

  return $humane_re;
}

sub humane_tmpname
{
  my $descr = shift // '';

  my @localtime = localtime;
  my $now       = sprintf(
    "%04d%02d%02d_%02d%02d%02d",
    $localtime[5] + 1900,
    $localtime[4] + 1,
    @localtime[ 3, 2, 1, 0 ]
  );

  return "mecha_$descr.$now.XXXX";
}

sub _mktmpdir
{
  my $proj_dir = _get_project_dir();
  my $tmp_dir
    = defined $proj_dir ? "$proj_dir/local/tmp" : File::Spec->tmpdir;

  mkdir $tmp_dir
    unless -d $tmp_dir;

  return $tmp_dir;
}

sub humane_tmpfile
{
  my $descr   = shift;
  my $tmp_dir = _mktmpdir;

  my $template = File::Spec->catdir( $tmp_dir, humane_tmpname($descr) );
  return File::Temp->new(TEMPLATE => $template);
}

sub humane_tmpdir
{
  my $descr   = shift;
  my $tmp_dir = _mktmpdir;

  my $template = File::Spec->catdir( $tmp_dir, humane_tmpname($descr) );
  return tempdir(
    TEMPLATE => $template,
    CLEANUP  => 1,
  );
}

sub _setup_log
{
  my $dest_dir = shift;

  my $log_dir = "$dest_dir/logs";
  mkdir $log_dir
    unless -d $log_dir;

  my $proj_dir = &_get_project_dir;
  my $template = File::Spec->catdir( $log_dir, humane_tmpname('log') );
  my $log_path;
  ( $LOGFH, $log_path ) = tempfile( $template, UNLINK => 0 );
  $log_path =~ s[^\Q$proj_dir\E/?][];
  info("logging to '$log_path'...\n");
}

sub logmsg
{
  my @lines = @_;

  return
    unless defined $LOGFH;

  foreach my $line (@lines)
  {
    if ( $line !~ m/\n$/xms )
    {
      $line .= "\n";
    }
    print $LOGFH $line;
  }

  return;
}

sub info
{
  my $key  = shift;
  my $line = shift;

  if ( !defined $line )
  {
    $line = $key;
    undef $key;
  }

  status( $key, 'YELLOW', $line );
}

sub success
{
  my $key  = shift;
  my $line = shift;

  if ( !defined $line )
  {
    $line = $key;
    undef $key;
  }

  status( $key, 'GREEN', $line );
}

sub error
{
  my $key  = shift;
  my $line = shift;

  if ( !defined $line )
  {
    $line = $key;
    undef $key;
  }

  status( $key, 'RED', $line );
}

my $RESET = Term::ANSIColor::color('RESET');
my $BOLD  = Term::ANSIColor::color('BOLD');

sub _show_line
{
  my $key   = shift;
  my $color = shift;
  my $line  = shift;

  no warnings 'uninitialized';

  # If the color starts with red, it's an error and we should not touch it,
  # otherwise, we should clean up the line
  state $ERR_COLOR = Term::ANSIColor::color('RED');
  if ( $color !~ m/^\Q$ERR_COLOR/ )
  {
    $line =~ s/\n/ /xmsg;
  }

  state @key_lines;

  my $idx = first { $key_lines[$_] eq $key } 0 .. $#key_lines;

  if ( !defined $key )
  {
    # Scroll Up 1 line
    print STDERR "\n";
    $idx = -1;
  }

  # When key is _, that means we're undoing the last line
  if ( $key eq '_' )
  {
    $idx = 0;
  }

  if ( !defined $idx )
  {
    unshift @key_lines, $key;
    $idx = 0;

    # Scroll Up 1 line
    print STDERR "\n";
  }
  $idx++;

  # Don't bother with fancy line movements if we are verbose
  if ($VERBOSE)
  {
    print STDERR "$color$line$RESET\n";
    return;
  }

  # We use some ANSI escape codes, so they are:
  # \e[.F  - Move up from current line, which is always the end of the list
  # \e[K   - Clear the line
  # $color - Colorize the text
  # $line  - Print the text
  # $RESET - Reset the colorize
  # \e[.E  - Move down from the current line, back to the end of the list
  print STDERR "\e[${idx}F";
  print STDERR "\e[K";
  print STDERR "$color$line$RESET\n";
  print STDERR "\e[" . ( $idx - 1 ) . "E"
    if $idx > 1;

  return;
}

sub status
{
  my $key   = shift;
  my $color = shift;
  my $line  = shift;

  no warnings 'uninitialized';

  if ( !defined $line )
  {
    $line  = $color;
    $color = 'RESET';
  }

  # The _ key means undo the last line, but only status can do that, so treat
  # it the same as undef
  if ( $key eq '_' )
  {
    undef $key;
  }

  logmsg($line);

  return
    if $QUIET;

  $color = eval { Term::ANSIColor::color($color) } // $RESET;

  state @last_key;

  # Undo the last line that is bold
  if ( @last_key && !$VERBOSE && $last_key[0] ne $key )
  {
    _show_line(@last_key);
  }

  _show_line( $key, $color . $BOLD, $line );

  @last_key = ( $key // '_', $color, $line );
}

{
  no warnings 'void';
  END  { print STDERR "\n" unless $QUIET; }
  INIT { print STDERR "\n" unless $QUIET; }
}

sub _get_project_dir
{
  my $result = $PROJ_DIR;

  return $result;
}

sub get_project_dir
{
  my $result = _get_project_dir;

  if ( !defined $result )
  {
    $result = cwd;

    $result =~ s{ / local /? $}{}xms;
  }

  return $result;
}

package MechaCPAN::DestGuard
{
  use Cwd qw/cwd/;
  use Scalar::Util qw/refaddr weaken/;
  use overload '""' => sub { my $s = shift; return $$s }, fallback => 1;
  my $dest_dir;

  sub get
  {
    my $result = $dest_dir;
    if ( !defined $result )
    {
      my $pwd = App::MechaCPAN::get_project_dir;
      $dest_dir = \"$pwd/local";
      bless $dest_dir;
      $result = $dest_dir;
      weaken $dest_dir;
    }

    mkdir $dest_dir
      unless -d $dest_dir;

    return $dest_dir;
  }

  sub DESTROY
  {
    undef $dest_dir;
  }
}

sub dest_dir
{
  my $result = MechaCPAN::DestGuard::get();
  return $result;
}

sub fetch_file
{
  my $url = shift;
  my $to  = shift;

  use File::Copy qw/copy/;
  use Fatal qw/copy/;

  my $proj_dir = &dest_dir;
  my $slurp;

  local $File::Fetch::WARN;
  local $@;

  my $ff = File::Fetch->new( uri => $url );

  if ( $File::Fetch::VERSION < 0.50 )
  {
    # File::Fetch < 0.50 (versions bundled with perl before 5.26) does not
    # have an entry for https, so we have to convince it to use the http list
    # by telling it that the scheme is http. This does *NOT* change what
    # scheme the file is actually fetched with, only what client list will
    # be used/attempted. So https URIs are still fetched over https. In modern
    # versions of File::Fetch there is an https list, and that list does
    # enforce https verification
    $ff->scheme('http')
      if $ff->scheme eq 'https';
  }

  if ( ref $to eq 'SCALAR' )
  {
    $slurp = $to;
    undef $to;
  }

  my ( $dst_path, $dst_file, $result );
  if ( !defined $to )
  {
    $result = humane_tmpfile( $ff->output_file );

    my @splitpath = File::Spec->splitpath( $result->filename );
    $dst_path = File::Spec->catpath( @splitpath[ 0 .. 1 ] );
    $dst_file = $splitpath[2];
  }
  else
  {
    if ( $to =~ m[/$] )
    {
      $dst_path = $to;
      $dst_file = $ff->output_file;
    }
    else
    {
      my @splitpath = File::Spec->splitpath("$to");
      $dst_path = File::Spec->catpath( @splitpath[ 0 .. 1 ] );
      $dst_file = $splitpath[2];
    }

    $dst_path = File::Spec->rel2abs( $dst_path, "$proj_dir" )
      unless File::Spec->file_name_is_absolute($dst_path);
    $result = File::Spec->catdir( $dst_path, $dst_file );
  }

  mkdir $dst_path
    unless -d $dst_path;

  my $where = $ff->fetch( to => $dst_path );

  if ( !defined $where )
  {
    my $tmpfile = File::Spec->catdir( $dst_path, $ff->output_file );
    if ( -e $tmpfile && !-s )
    {
      unlink $tmpfile;
    }
    my $error = $ff->error || "Could not download $url";
    die "$error\n";
  }

  if ( $where ne $result )
  {
    copy( $where, $result );
    $result->seek( 0, 0 )
      if fileno $result;
    unlink $where;
  }

  if ( defined $slurp )
  {
    open my $slurp_fh, '<', $result;
    $$slurp = do { local $/; <$slurp_fh> };
    $result->seek( 0, 0 )
      if fileno $result;
  }

  return $result;
}

sub file_digest_chk
{
  my ( $path, $expected ) = @_;

  require Digest::SHA;
  my $actual = Digest::SHA->new('sha256')->addfile( "$path", 'b' )->hexdigest;

  $expected = uc $expected;
  $actual   = uc $actual;

  die "Expected and Actual Digest differs: $actual ne $expected"
    if $expected ne $actual;

  return;
}

sub _verify_checksums_body
{
  my $chksum_body = shift;

  # CHECKSUMS has a very regular pattern. If it doesn't match, we must refuse
  # loudly since it appears to be tampered with.

  my @result;
  my @content = split /\r?\n/, $chksum_body;

  while ( @content && $content[0] eq '' )
  {
    shift @content;
  }

  while ( @content && $content[-1] eq '' )
  {
    pop @content;
  }

  # Check the file header and the PGP header
  {
    my $header     = shift @content;
    my $pgp_header = shift @content;

    # First line must be that the PGP is also valid perl
    push @result, $header;
    croak "CHECKSUMS file failed validation: header-line mismatch"
      if $header ne q{0&&<<''; # this PGP-signed message is also valid perl};

    # Second line MUST be the PGP signed message start
    push @result, $pgp_header;
    croak "CHECKSUMS file failed validation: PGP header mismatch"
      if $pgp_header ne q{-----BEGIN PGP SIGNED MESSAGE-----};
  }

  # We're now safely in the PGP signed message. Grab all the PGP headers
  while ( defined( my $pgp_line = shift @content ) )
  {
    push @result, $pgp_line;
    last
      if $pgp_line eq '';
  }

  # Now read the perl hash header start, which is any number of comments
  # followed by a hash definition
  while ( defined( my $perl_intro = shift @content ) )
  {
    push @result, $perl_intro;
    last
      if $perl_intro eq '$cksum = {';    # } This confuses vim and annoys me

    next
      if $perl_intro =~ m/^[#]/xms;

    my $linenum = scalar @result;
    croak "CHECKSUMS file failed validation: Unexpected perl code $linenum";
  }

  my ($indent) = $content[0] =~ m/^(\s+)/;

  croak "CHECKSUMS file failed validation: missing indentation"
    if !defined $indent;

  # Definition lines can only be `'Key' => {` or `'Key' => 'Value'`
  while ( defined( my $perl_line = shift @content ) )
  {
    push @result, $perl_line;
    last
      if $perl_line =~ m/^};$/xms;

    next
      if $perl_line =~ m/^ \Q$indent\E '[^' ]+' \s+ => \s+ {$/xms;

    next
      if $perl_line
      =~ m/^ \Q$indent\E \s+ '[\w-]+' \s+ => \s+ ('[^' ]+' | \d+) ,? $/xms;

    next
      if $perl_line =~ m/^ \Q$indent\E},?/xms;

    my $linenum = scalar @result;
    croak "CHECKSUMS file failed validation: Unexpected perl code $linenum";
  }

  {
    my $perl_footer = shift @content;

    if ( $perl_footer ne '__END__' )
    {
      my $linenum = scalar @result;
      croak "CHECKSUMS file failed validation: Unexpected footer $linenum";
    }
    push @result, $perl_footer;
  }

  # We now have no content that perl will read, which means all we should have is the PGP signature
  {
    my $pgp_header = shift @content;
    push @result, $pgp_header;

    if ( $pgp_header ne '-----BEGIN PGP SIGNATURE-----' )
    {
      my $linenum = scalar @result;
      croak
        "CHECKSUMS file failed validation: Unexpected PGP header $linenum";
    }

    # Ignore all of the PGP armor headers. They must be well-formed as much as
    # they can be (includes a colon followed by a space as a separator)
    while ( defined( my $pgp_line = shift @content ) )
    {
      push @result, $pgp_line;

      last
        if $pgp_line eq '';

      next
        if $pgp_line =~ m{: };

      my $linenum = scalar @result;
      croak "CHECKSUMS file failed validation: Unexpected pgp armor header line $linenum";
    }

    while ( defined( my $pgp_line = shift @content ) )
    {
      push @result, $pgp_line;

      last
        if $pgp_line eq '-----END PGP SIGNATURE-----';

      next
        if $pgp_line =~ m{^[A-Za-z0-9+/=]*$}x;

      my $linenum = scalar @result;
      croak "CHECKSUMS file failed validation: Unexpected pgp line $linenum";
    }
  }

  croak "CHECKSUMS file failed validation: missing PGP signature end"
    if $result[-1] ne '-----END PGP SIGNATURE-----';

  croak "CHECKSUMS file failed validation: Unexpected data after end"
    if @content;

  return join( "\n", @result );
}

my $cpan_fingerprint = '2E66 557A B97C 19C7 91AF  8E20 328D A867 450F 89EC';
my $keyserve         = 'https://www.cpan.org/modules/04pause.html';
my $search           = '';

sub _cpan_key_chk
{
  my $keyring = shift;    # Expects the binary public key data

  require Digest::SHA;

  # Parse the packet header (RFC 9580) and make sure its a Public Key
  # (type 6). We also require it to be the new packet format
  my $body_len;
  my $type;
  my ( $header_octet, $remaining ) = unpack 'Ca*', $keyring;

  die "not an OpenPGP packet"
    if !( $header_octet & 0x80 );

  if ( !( $header_octet & 0x40 ) )
  {
    $type = ( $header_octet >> 2 ) & 0x0F;
    my $len_type = $header_octet & 0x03;

    ( $body_len, $remaining )
      = $len_type == 0 ? unpack( 'Ca*', $remaining )
      : $len_type == 1 ? unpack( 'na*', $remaining )
      : $len_type == 2 ? unpack( 'Na*', $remaining )
      :   die "indeterminate-length packet in primary key position";
  }

  if ( $header_octet & 0x40 )
  {
    $type = $header_octet & 0x3F;

    my ($enc_len) = unpack 'C', $remaining;

    if ( $enc_len < 192 )
    {
      ( $body_len, $remaining ) = unpack 'Ca*', $remaining;
    }
    elsif ( $enc_len < 224 )
    {
      my $extra;
      ( $enc_len, $extra, $remaining ) = unpack 'CCa*', $remaining;
      $body_len = ( ( $enc_len - 192 ) << 8 ) + $extra + 192;
    }
    elsif ( $enc_len == 255 )
    {
      ( $enc_len, $body_len, $remaining ) = unpack 'CNa*', $remaining;
    }
    else { die "partial-length packet in primary key position" }
  }

  die "first packet is type $type, not a public key (type 6)"
    unless $type == 6;

  my $body = substr( $remaining, 0, $body_len );
  die "truncated key packet"
    if length($body) != $body_len;

  my $version = unpack 'C', $body;
  die "not a v4 key (got version $version)"
    if $version != 4;

  # v4 fingerprint = SHA-1( 0x99 || 2-byte BE length || packet body )
  my $to_hash  = "\x99" . pack( 'n', $body_len ) . $body;
  my $actual   = uc( Digest::SHA::sha1_hex($to_hash) );
  my $expected = $cpan_fingerprint;
  $expected =~ s/\s//g;

  die
    "Downloaded CPAN Public key does not match expected fingerprint ( $actual ne $expected )"
    if $actual ne $expected;

  return;
}

sub cpan_keyring
{
  state $keyring_path;
  state $cache_path;

  if ( !defined $cache_path )
  {
    my $dest_dir  = &dest_dir;
    my $cache_dir = File::Spec->catdir( "$dest_dir", 'cache' );
    mkdir $cache_dir
      unless -d $cache_dir;

    $cache_path = File::Spec->catfile( "$cache_dir", 'cpan_keyring.pgp' );
  }

  if ( !defined $keyring_path && -e $cache_path )
  {
    my $mtime = ( stat $cache_path )[9];
    if ( defined $mtime && time - $mtime < 24 * 60 * 60 )
    {
      open my $keyring_fh, '<', $cache_path;
      my $keyring = do { local $/; <$keyring_fh> };

      # Verify that this is the CPAN key by checking the primary key.
      local $@;
      eval { _cpan_key_chk($keyring) };
      my $error = $@;

      if ($error)
      {
        logmsg "Existing CPAN Public Key on disk could not be used: $error";
        unlink $cache_path;
      }
      else
      {
        $keyring_path = $cache_path;
      }
    }
  }

  if ( !defined $keyring_path )
  {
    # Always download the freshest, even if we leave it in local/
    my $keyring = '';
    fetch_file( "$keyserve$search", \$keyring );

    # Strip the armor around the base64 string
    $keyring =~ s/\r//xmsg;
    $keyring =~ s{
      \A
      .*?                                        # Everything before the armor
      (?: \Q$cpan_fingerprint\E [^\n]* \n )      # require fingerprint on prior line
      \Q-----BEGIN PGP PUBLIC KEY BLOCK-----\E\n
      (?: [^\n]+ \n)* \n                         # The headers
      (
        (?: [A-Za-z0-9+/]* =* \n )*              # The base64 content
      )
      (?: =[A-Za-z0-9+\/]{4}\s*\n )?             # The optional checksum
      \Q-----END PGP PUBLIC KEY BLOCK-----\E
      .*                                         # Everything after the armor
      \Z
    }{$1}xms;

    require MIME::Base64;

    $keyring = MIME::Base64::decode_base64($keyring);

    # Verify that this is the CPAN key by checking the primary key.
    _cpan_key_chk($keyring);

    open my $keyring_fh, '>', $cache_path;
    print $keyring_fh $keyring;

    $keyring_path = $cache_path;
  }

  return $keyring_path;
}

#gpgv, sqv, gpg, sq, and rnp
my @verifier = (
  sub
  {
    return
      if !eval { run(qw/gpgv --version/); 1 };

    return sub
    {
      my ( $file, $keyring ) = @_;
      run_qvf( "gpgv", "--keyring", "$keyring", "$file" );
    };
  },
  sub
  {
    my $out = eval { run(qw/sqv --version/) };
    return
      if !defined $out;
    my ($major) = $out =~ m/(\d+)\.\d+(?:\.\d+)?/;
    return
      if !defined $major || $major < 1;

    return sub
    {
      my ( $file, $keyring ) = @_;
      run_qvf( "sqv", "--keyring", "$keyring", "$file" );
    };
  },
  sub
  {
    return
      if !eval { run(qw/gpg --version/); 1 };

    return sub
    {
      my ( $file, $keyring ) = @_;
      run_qvf( "gpg", "--no-default-keyring", "--keyring", "$keyring",
        "--verify", "$file" );
    };
  },
  sub
  {
    my $out = eval { run(qw/sq --version/) };
    return
      if !defined $out;
    my ($major) = $out =~ m/(\d+)\.\d+(?:\.\d+)?/;
    return
      if !defined $major || $major < 1;

    return sub
    {
      my ( $file, $keyring ) = @_;
      run_qvf( "sq", "verify", "--signer-file", "$keyring", "$file" );
    };
  },
  sub
  {
    return
      if !eval { run(qw/rnp --version/); 1 };

    return sub
    {
      my ( $file, $keyring ) = @_;
      run_qvf( "rnp", "--keyfile", "$keyring", "--verify", "$file" );
    };
  },
);

sub _resolve_verifier
{
  state $verify_fn;

  if ( !defined $verify_fn )
  {
    foreach my $verify (@verifier)
    {
      my $fn = $verify->();
      if ( defined $fn )
      {
        $verify_fn = $fn;
        last;
      }
    }
  }

  return $verify_fn;
}

sub get_cpan_checksums
{
  my $url = shift;
  my $key = shift;

  # If verify is off, don't check any part of the CHECKSUMS
  return
    if defined $CHKSIGS && !$CHKSIGS;

  die "CHECKSUMS URL must be HTTPS, not '$url'"
    unless $url =~ m{\Ahttps://}xmsi;

  die "CHECKSUMS URL must end with CHECKSUMS, not '$url'"
    unless $url =~ m{CHECKSUMS\z}xmsi;

  # Even if verification is optional, not downloading the CHECKSUMS is fatal
  my $checksums = '';
  fetch_file( $url, \$checksums );
  $checksums = App::MechaCPAN::_verify_checksums_body($checksums);

  # If $CHKSIGS is true, we must verify that CHECKSUMS has a valid signature
  # If $CHKSIGS is undef, we will verify that CHECKSUMS has a valid signature
  #   if possible, but won't throw errors if can't.
  # In both cases, the CHECKSUMS is used to validate the checksums of the
  #   downloaded file
  # If $CHKSIGS is otherwise false, we already did an early return above
  my $verify_fn = _resolve_verifier();

  if ( !defined $verify_fn )
  {
    die "Could not find verification program and verification was required"
      if $CHKSIGS;
    logmsg "CHECKSUMS signature not checked: PGP verifier not found";
  }
  else
  {
    my $keyring  = cpan_keyring();
    my $chk_file = humane_tmpfile('CHECKSUMS');

    $chk_file->print($checksums);
    $chk_file->flush;
    $verify_fn->( "$chk_file", $keyring );
    logmsg "VALID: $url";
  }

  my $result = do
  {
    require Safe;
    my $safe = Safe->new("App::MechaCPAN::reval");

    local $@;
    my $chksum = $safe->reval($checksums);
    die "Failed to parse CHECKSUMS: $@"
      if $@;

    die "Failed to get HASH from CHECKSUMS"
      if ref $chksum ne 'HASH';

    $chksum;
  };

  # If a module name is passed ($key), then we check if it is listed in the
  # CHECKSUMS file. If it is missing, it depends on $CHKSIGS. If it is true
  # (strict verify), an error will be produced. If it is undef (best-effort)
  # then a log entry will be added, and nothing will be returned, whcih will
  # match the no-verify path above.
  if ( defined $key && !exists $result->{$key} )
  {
    die "Could not find module '$key' in CHECKSUMS"
      if $CHKSIGS;

    logmsg "Could not find '$key' in CHECKSUMS, not attempting to verify";
    return;
  }

  return $result;
}

my @inflate = (

  # System tar
  sub
  {
    my $src = shift;

    my $humane_qr = humane_qr;
    return
      unless $src =~ m{ [.]tar[.] (?: xz | gz | bz2|bzip2 ) $humane_qr? $}xms;

    state $tar;
    if ( !defined $tar )
    {
      my $tar_version_str = eval { run(qw/tar --version/); };
      $tar = defined $tar_version_str;
    }

    return
      unless $tar;

    my $unzip
      = $src =~ m/gz $humane_qr? $/xms          ? 'gzip'
      : $src =~ m/(bz2|bzip2) $humane_qr? $/xms ? 'bzip2'
      :                                           'xz';

    # Instead of relying on a shell to pipe contents from unzip to tar, both
    # gnutar and bsdtar accept the use-compress-program option. bsdtar needs
    # the -d option so it will decompress, while gnutar automatically adds it
    # but it is harmless to add.
    run( 'tar', '--use-compress-program', "$unzip -d", '-xf', $src );
    return 1;
  },

  # Archive::Tar
  sub
  {
    my $src = shift;

    require Archive::Tar;
    my $tar = Archive::Tar->new;
    $tar->error(1);

    my $ret = $tar->read( "$src", 1, { extract => 1 } );

    die $tar->error
      unless $ret;
  },
);

sub _path_escapes_dir
{
  my $path = shift;

  return 0
    if !defined $path;
  return 0
    if !length $path;

  return 1
    if File::Spec->file_name_is_absolute($path);

  for my $part ( File::Spec->splitdir($path) )
  {
    return 1
      if $part eq '..';
  }

  return 0;
}

# Inspect a tar archive's header entries (no extraction). Returns a
# human-readable reason if any entry would escape the destination dir
# (absolute paths, '..' traversal in names, or symlink/hardlink targets
# pointing outside). Returns undef if the archive is safe.
sub _validate_archive_is_safe
{
  my $src = shift;

  require Archive::Tar;

  # Create a tar iterator. The magic 1 tells it to decompress
  my $iter = Archive::Tar->iter( "$src", 1 );

  return "could not read archive: $src"
    if !defined $iter;

  while ( my $entry = $iter->() )
  {
    my $name = $entry->full_path;

    return "unsafe entry name: '$name'"
      if _path_escapes_dir($name);

    if ( $entry->is_symlink || $entry->is_hardlink )
    {
      my $linkname = $entry->linkname;

      return "unsafe link target: '$name' -> '$linkname'"
        if _path_escapes_dir($linkname);
    }
  }

  return;
}

sub inflate_archive
{
  my $src = shift;
  my $dir = shift;

  my $sha256;

  if ( ref $src eq 'HASH' )
  {
    $sha256 = delete $src->{sha256};

    # Technically the error is wrong, it can have an optional sha256 key,
    # but it gets people here to see that the error is that there is a
    # narrow requirement for the hashref version of inflate_archive
    die "Hashref for inflate_archive must be only the 'src' key"
      if scalar( keys %$src ) != 1 || !exists $src->{src};

    $src = $src->{src};
  }

  # $src can be a file path or a URL.
  if ( !-e "$src" )
  {
    $src = fetch_file($src);
  }

  if ($sha256)
  {
    file_digest_chk( $src, $sha256 );
    logmsg "Digest passed: $src";
  }

  if ( !defined $dir )
  {
    my $descr = ( File::Spec->splitpath($src) )[2];
    $dir = humane_tmpdir($descr);
  }

  die "Could not find destination directory: $dir"
    if !-d $dir;

  if ( my $reason = _validate_archive_is_safe($src) )
  {
    croak "Refusing to extract unsafe archive $src: $reason\n";
  }

  my $orig = cwd;

  my $is_complete;
  foreach my $inflate_sub (@inflate)
  {
    local $@;
    my $success;
    my $error_free = eval {
      chdir $dir;
      $success = $inflate_sub->($src);
      1;
    };

    my $err = $@;
    my @glob = glob('*');

    chdir $orig;

    logmsg $err
      unless $error_free;

    if ($success && @glob > 0)
    {
      $is_complete = 1;
      last;
    }
  }

  if ( !$is_complete )
  {
    croak "Could not unpack archive: $src\n";
  }

  # If there's only 1 file and it's a directory, go ahead and chdir into it
  my @files = glob("$dir/*");
  if ( @files == 1 && -d $files[0] )
  {
    $dir = $files[0];
  }

  return $dir;
}

sub _genio
{
  state $iswin32 = $^O eq 'MSWin32';
  my $write_hdl;
  my $read_hdl;

  if ($iswin32)
  {
    use Socket;
    socketpair( $read_hdl, $write_hdl, AF_UNIX, SOCK_STREAM, PF_UNSPEC );
    shutdown( $read_hdl,  1 );
    shutdown( $write_hdl, 0 );
  }
  else
  {
    $write_hdl = $read_hdl = geniosym;
  }

  $write_hdl->blocking(0);
  $write_hdl->autoflush(1);
  $read_hdl->blocking(0);
  $read_hdl->autoflush(1);

  return ( $read_hdl, $write_hdl );
}

# Run a command and suppress the entire output unless there was an error
sub run_qvf
{
  my @args = @_;
  if ( $VERBOSE )
  {
    return run(@args);
  }

  my $qvf = '';
  open my $fh, '>', \$qvf;

  local $@;

  my $result;
  eval {
    local $LOGFH   = $fh;
    defined wantarray ? $result = run(@args) : run(@args);
  };

  if ( $@ )
  {
    if ( $LOGFH )
    {
      print $LOGFH $qvf;
    }
    die $@;
  }

  return
    if !defined wantarray;

  if (wantarray)
  {
    return split( /\r?\n/, $result );
  }

  return $result;
}

sub run
{
  my $cmd  = shift;
  my @args = @_;

  my $max_lines = 15;
  my $out = "";
  my $err = "";
  my @err_tail;
  my @out_tail;

  my $dest_out_fh  = $LOGFH;
  my $dest_err_fh  = $LOGFH;
  my $print_output = $VERBOSE;
  my $wantoutput   = defined wantarray;

  if ( ref $cmd eq 'GLOB' || ( blessed $cmd && $cmd->isa('IO::Handle') ) )
  {
    $dest_out_fh = $cmd;
    $cmd         = shift @args;
    undef $print_output;
  }

  # If the output is asked for (non-void context), don't show it anywhere
  #<<<
  if ($wantoutput)
  {
    undef $dest_out_fh; open $dest_out_fh, ">", \$out;
    undef $dest_err_fh; open $dest_err_fh, ">", \$err;
    undef $print_output;
  }
  #>>>

  my ( $output, $output_chld ) = _genio;
  my ( $error,  $error_chld )  = _genio;

  warn( join( "\t", $cmd, @args ) . "\n" )
    if $VERBOSE;

  print $dest_err_fh ( 'Running: ', join( "\t", $cmd, @args ) . "\n" )
    if defined $dest_err_fh;

  my $pid = open3(
    undef,
    $output_chld->fileno ? '>&' . $output_chld->fileno : $output_chld,
    $error_chld->fileno  ? '>&' . $error_chld->fileno  : $error_chld,
    $cmd, @args
  );
  undef $output_chld;
  undef $error_chld;

  my $select = IO::Select->new;

  $select->add( $output, $error );

  my $alrm_code = "TIMEOUT\n";
  local $SIG{ALRM} = sub { die $alrm_code };
  local $@;

  eval {
    alarm $TIMEOUT;
    while ( my @ready = $select->can_read )
    {
      alarm $TIMEOUT;
      foreach my $fh (@ready)
      {
        my $line = <$fh>;

        if ( !defined $line )
        {
          $select->remove($fh);
          next;
        }

        # All output goes to STDERR so it can be captured
        # in verbose mode
        print STDERR $line if $print_output;

        if ( $fh eq $output )
        {
          print $dest_out_fh $line
            if defined $dest_out_fh;
          if ( !$wantoutput )
          {
            $out .= $line;
            unshift @out_tail, $line;
            $#out_tail = $max_lines
              if $#out_tail > $max_lines;
          }
        }

        if ( $fh eq $error )
        {
          print $dest_err_fh $line
            if defined $dest_err_fh;
          if ( !$wantoutput )
          {
            $err .= $line;
            unshift @err_tail, $line;
            $#err_tail = $max_lines
              if $#err_tail > $max_lines;
          }
        }

      }
    }
  };

  my $eval_error = $@;
  alarm 0;

  if ( $eval_error eq $alrm_code )
  {
    info "Idle timeout (${TIMEOUT}s) exceeded, killing";
    kill "KILL", $pid;
  }

  waitpid( $pid, 0 );

  if ($?)
  {
    my $code = qq/Exit Code: / . ( $? >> 8 );
    my $sig  = ( $? & 127 ) ? qq/Signal: / . ( $? & 127 ) : '';
    my $core = $? & 128     ? 'Core Dumped'               : '';

    # There could be a lot of output, ignore all but the very end
    $out_tail[-1] = "...SKIPPED\n"
      if scalar @out_tail > $max_lines;
    my $out_tail = join( '', reverse @out_tail );
    chomp $out_tail;

    $err_tail[-1] = "...SKIPPED\n"
      if scalar @err_tail > $max_lines;
    my $err_tail = join( '', reverse @err_tail );
    chomp $err_tail;

    croak ""
      . Term::ANSIColor::color('RED')
      . qq/\nCould not execute '/
      . join( ' ', $cmd, @args ) . qq/'/
      . qq/\nPID: $pid/
      . qq/\t$code/
      . qq/\t$sig/
      . qq/\t$core/
      . Term::ANSIColor::color('GREEN')
      . qq/\n$out_tail/
      . Term::ANSIColor::color('YELLOW')
      . qq/\n$err_tail/
      . Term::ANSIColor::color('RESET') . "\n";
  }

  return
    if !defined wantarray;

  if (wantarray)
  {
    return split( /\r?\n/, $out );
  }

  return $out;
}

# Install App::MechaCPAN into a local perl, either by ::Install or copy
sub _inc_pkg
{
  my $inc_name = ( shift || __PACKAGE__ ) . '.pm';
  $inc_name =~ s{::}{/}g;
  return $inc_name;
}

my $starting_cwd;
BEGIN { $starting_cwd = cwd }

sub rel_start_to_abs
{
  my $f = shift;

  $f = File::Spec->rel2abs( $f, $starting_cwd )
    unless File::Spec->file_name_is_absolute($f);

  return $f;
}

sub self_install
{
  my $real0 = shift;

  my $dest_dir = &dest_dir;
  my $dest_lib = File::Spec->catdir( "$dest_dir", qw/lib perl5/ );
  my $dest_app = File::Spec->catdir( "$dest_dir", qw/bin/ );
  my $inc_name = _inc_pkg;

  return
    if !-d $dest_dir;

  # Return if there's already a copy
  return
    if -e File::Spec->catdir( $dest_lib, $inc_name );

  use File::Copy qw/copy/;
  use File::Path qw/make_path/;
  use Fatal qw/copy/;

  make_path $dest_lib, $dest_app;

  if ( defined $real0 && -e $real0 )
  {
    # Attempt to find the full path to this file.
    my $mecha_path;

    foreach my $lib (@INC)
    {
      my $mecha_file
        = rel_start_to_abs( File::Spec->catdir( $lib, $inc_name ) );
      if ( -e $mecha_file )
      {
        $mecha_path = rel_start_to_abs $lib;
        last;
      }
    }

    if ( defined $mecha_path )
    {
      $inc_name =~ s/[.]pm$//;
      my %copy_list;
      foreach my $k ( grep {m/$inc_name/} keys %INC )
      {
        my $src = File::Spec->catdir( $mecha_path, $k );
        my $dst = File::Spec->catdir( $dest_lib,   $k );

        my $dst_path
          = File::Spec->catpath( ( File::Spec->splitpath($dst) )[ 0 .. 1 ] );
        make_path $dst_path;

        if ( !-e $src )
        {
          %copy_list = ();
          last;
        }
        $copy_list{$src} = $dst;
      }

      if ( keys %copy_list )
      {
        while ( my ( $src, $dst ) = each %copy_list )
        {
          copy $src => $dst;
        }
        copy $real0 => $dest_app;
        return;
      }
    }
  }

  # We don't check the result because we are going to continue even if
  # the install fails
  info "Installing " . __PACKAGE__;
  App::MechaCPAN::Install->go( {}, __PACKAGE__ );
  return;
}

sub restart_script
{
  my $dest_dir   = &dest_dir;
  my $local_perl = File::Spec->canonpath("$dest_dir/perl/bin/perl");
  my $this_perl  = File::Spec->canonpath($^X);
  my $cwd        = cwd;

  if ( $^O ne 'VMS' )
  {
    $this_perl .= $Config{_exe}
      unless $this_perl =~ m/$Config{_exe}$/i;
    $local_perl .= $Config{_exe}
      unless $local_perl =~ m/$Config{_exe}$/i;
  }

  return
    if $local_perl eq $this_perl;

  my $real0 = rel_start_to_abs $0;

  if ( !-e -r $real0 )
  {
    logmsg "Could not find '$0', not in '$starting_cwd' nor pwd '$cwd'";
    info "Could not find '$0' in order to restart script";
    return;
  }

  if (
    $loaded_at_compile      # IF we were loaded during compile-time
    && -e -x $local_perl    # AND the local perl is there
    && -e -f -r $real0      # AND we are a readable file
    && !$^P                 # AND we're not debugging
    )
  {
    # ReExecute using the local perl
    my @inc_add;
    my @paths = qw/
      sitearchexp sitelibexp
      vendorarchexp vendorlibexp
      archlibexp privlibexp
      otherlibdirsexp
      /;

    my %site_inc = map { defined $_ ? ( $_ => 1 ) : () } @Config{@paths}, '.';

    foreach my $lib ( split ':', $ENV{PERL5LIB} // '')
    {
      $site_inc{$lib} = 1;
      $site_inc{"$lib/$Config{archname}"} = 1;
    }

    # If we are not a self-contained script, we should call self_install to
    # make sure we are installed, by hook or by crook
    if ( $INC{&_inc_pkg} =~ m/MechaCPAN[.]pm/ )
    {
      self_install($real0);
    }

    foreach my $lib (@INC)
    {
      push( @inc_add, $lib )
        unless exists $site_inc{$lib};
    }

    # Make sure anything from PERL5LIB and local::lib are removed since it's
    # most likely the wrong version as well.
    $ENV{PERL_LOCAL_LIB_ROOT} //= '';
    @inc_add = grep { $_ !~ m/^$ENV{PERL_LOCAL_LIB_ROOT}/xms } @inc_add;
    undef @ENV{qw/PERL_LOCAL_LIB_ROOT PERL5LIB/};

    # If we've running, inform the new us that they are a restarted process
    local $ENV{$restarted_key} = 1
      if ${^GLOBAL_PHASE} eq 'RUN';

    # Cleanup any files opened already. They arn't useful after we exec
    File::Temp::cleanup();

    info "Restarting to local perl\n";
    info( join( " ", $local_perl, map( {"-I$_"} @inc_add ), $real0, @ARGV ) );
    exec( $local_perl, map( {"-I$_"} @inc_add ), $real0, @ARGV );
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::MechaCPAN - Mechanize the installation of CPAN things.

=head1 SYNOPSIS

  # Install 5.24 into local/perl/
  user@host:~$ mechacpan perl 5.24
  
  # Install Catalyst into local/
  user@host:~$ mechacpan install Catalyst
  
  # Install everything from the cpanfile into local/
  # If cpanfile.snapshot exists, it will be consulted first
  user@host:~$ mechacpan install
  
  # Install perl and everything from the cpanfile into local/
  # If cpanfile.snapshot exists, it will be consulted exclusivly
  user@host:~$ mechacpan deploy
  user@host:~$ zhuli do the thing
  
  # Download mechacpan for use or for a one-off command
  user@host:~$ curl -L https://get.mechacpan.us -o mechacpan
  user@host:~$ curl -L https://get.mechacpan.us | perl - deploy

=head1 DESCRIPTION

App::MechaCPAN Mechanizes the installation of perl and CPAN modules.
It is designed to be small and focuses more on installing things in a self-contained manner. That means that everything is installed into a C<local/> directory.

MechaCPAN was created because installation of a self-contained deployment required at least 4 tools:

=over

=item plenv/Perl-Build or perlbrew to manage perl installations

=item cpanm to install packages

=item local::lib to use locally installed modules

=item carton to manage and deploy exact package versions

=back

In development these tools are invaluable, but when deploying a package, installing at least 4 packages from github, CPAN and the web just for a small portion of each tool is more than needed. App::MechaCPAN aims to be a single tool that can be used for deploying packages in a automated fashion.

App::MechaCPAN focuses on the aspects of these tools needed for deploying packages to a system. For instance, it will read and use carton's C<cpanfile.snapshot> files, but cannot create them. To create C<cpanfile.snapshot> files, you must use carton.

=head2 Should I use App::MechaCPAN instead of <tool>

Probably not, no. It can be used in place of some tools, but its focus is not on the features a developer needs. If your needs are very simple and you don't need many options, you might be able to get away with only using C<App::MechaCPAN>. However be prepared to run into limitations quickly.

=head1 USING FOR DEPLOYMENTS

=head2 COMMANDS

  user@host:~/project/$ ls -la
  drwxr-xr-x  6 user users 20480 Jan 18 13:00 .
  drwxr-xr-x 25 user users  4096 Jan 18 13:00 ..
  drwxr-xr-x  8 user users  4096 Jan 18 13:05 .git
  -rw-r--r--  1 user users     7 Jan 18 13:06 .perl-version
  -rw-r--r--  1 user users   109 Jan 18 13:06 cpanfile
  drwxr-xr-x  3 user users  4096 Jan 18 13:10 lib
  
  user@host:~/project/$ mechacpan deploy

That command will do 2 things:

=over

=item Install perl

It will install perl into the directory local/perl.  It will use the version in C<.perl-version> to decide what version will be installed.

=item Install modules

Then it will use the installed perl to install all the module dependencies that are listed in the cpanfile.

=back

=head1 COMMANDS

=head2 Perl

  user@host:~$ mechacpan perl 5.24

The L<perl|App::MechaCPAN::Perl> command is used to install L<perl> into C<local/>. This removes the packages dependency on the operating system perl. By default, it tries to be helpful and include C<lib/> and C<local/> into C<@INC> automatically, but this feature can be disabled. See L<App::MechaCPAN::Perl> for more details.

=head2 Install

  user@host:~$ mechacpan install Catalyst

The L<install|App::MechaCPAN::Install> command is used for installing specific modules. All modules are installed into the C<local/> directory. See See L<App::MechaCPAN::Install> for more details.

=head2 Deploy

  user@host:~$ mechacpan deploy

The L<deploy|App::MechaCPAN::Deploy> command is used for automating a deployment. It will install both L<perl> and all the modules specified from the C<cpanfile>. If there is a C<cpanfile.snapshot> that was created by L<Carton>, C<deploy> will treat the modules lised in the snapshot file as the only modules available to install. See L<App::MechaCPAN::Deploy> for more details.

=head1 OPTIONS

Besides the options that the individual commands take, C<App::MechaCPAN> takes several that are always available.

=head2 --verbose

By default only informational descriptions of what is happening is shown. Turning verbose on will show every command and all output produced by running each command. Note that this is B<not> the opposite of quiet.

=head2 --quiet

Using quiet means that the normal information descriptions are hidden. Note that this is B<not> the opposite of verbose, turning both options on means no descriptions will be show, but all output from all commands will be.

=head2 --no-log

A log is normally outputted into the C<local/logs> directory. This option will prevent a log from being created.

=head2 --verify

When C<--verify> is given, a verification of the CPAN C<CHECKSUMS> file during module install is required. Note that packages from L<BackPAN|https://backpan.perl.org/> will not verify when C<--verify> is given. This process includes three steps after downloading the C<CHECKSUMS> file from CPAN for the module.

=over

=item 1. Confirm the shape of CHECKSUMS

C<CHECKSUMS> files contain all the files and the file checksums for a CPAN author's uploads. This file is compared against a rigid definition to ensure that it does not appear to be doing anything malicious.

=item 2. Confirm the signature of CHECKSUMS

Once the C<CHECKSUMS> structure has been examined, the embedded signature is verified. The C<CHECKSUMS> file is signed using the PAUSE Batch Signing Key (C<2E66 557A B97C 19C7 91AF  8E20 328D A867 450F 89EC>, accessible at L<https://www.cpan.org/modules/04pause.html>). This signature is checked with an external PGP signature verification program. See below for a list of usable external verification programs.

=item 3. Compare the sha256 of the downloaded module to CHECKSUMS

Once the CHECKSUMS file has been checked, the size, CPAN author path, and the C<sha256> value of the downloaded module archive are compared against the values from the CHECKSUMS file. These values must match.

=back

You can also disable C<CHECKSUMS> verification completely with C<--no-verify>. That will prevent all of these steps from running at all.

When neither option is provided then the signature checking step is attempted, but will not produce an error if the external verification program could not be found, or the file is from backpan and has no corrisponding C<CHECKSUMS> entry. An error is still raised if any other parts of the process finds a problem.

If L<MetaCPAN|https://metacpan.org> was used to find a module, the search will include the SHA256 of the package, which will be checked against the downloaded archive. This check cannot be disabled currently.

The verification programs that can be used are: L<gpgv|https://www.gnupg.org/>, L<sqv|https://sequoia-pgp.org/>, L<gpg|https://www.gnupg.org/>, L<sq|https://sequoia-pgp.org/>, and L<rnp|https://www.rnpgp.org/>.

=head2 --directory=<path>

Changes to a specified directory before any processing is done. This allows you to specify what directory you want C<local/> to be in. If this isn't provided, the current working directory is used instead.

=head2 --build-reusable-perl

Giving this options will override the mode of operation and generate a reusable, relocatable L<perl> archive. This accepts the same parameters as the L<Perl|App::MechaCPAN::Perl> command (i.e. L</devel> and L</threads>) to generate the binary. Note that the C<lib/> directory is always included unless the L<--skip-lib|App::MechaCPAN::Perl/skip-lib> option is included. The archive name will generally reflect what systems the resuling archive can run on. Because of the nature of how L<perl> builds binaries, it cannot guarantee that it will work on any given system. This option will have the best luck if you use it with the same version of a distribution.

Once you have a reusable binary archive, L<App::MechaCPAN::Perl> can use that archive as a source file and install the binaries into the local directory. This can be handy if you are building a lot of identical systems and only want to build L<perl> once.

The exact parameters included in the archive name are:

=over

=item * The version built

=item * The architecture name, as found in the first piece of $Config{archname}

=item * The Operating System, as found in $Config{osname}

=item * Optionally notes if it was built with threads

=item * The name of the libc used

=item * The version of the libc used

=item * The C<so> version of libraries used, with common libaries being abbreviated

=back

An example archive name would be C<perl-v5.36.0-x86_64-linux-glibc-2.35-y1.1n2.0u1.tar.xz>

=head2 C<$ENV{MECHACPAN_TIMEOUT}>

Every command that C<App::MechaCPAN> runs is given an idle timeout before it is killed and a failure is returned. This timeout is reset every time the command outputs to C<STDOUT> or C<STDERR>. Using the environment variable C<MECHACPAN_TIMEOUT>, you can override or disable this timeout. It is always in seconds and setting it to 0 will disable it. The default is 60 seconds.

=head1 SCRIPT RESTART WARNING

This module B<WILL> restart the running script B<IF> it's used as a module (e.g. with C<use>) and the perl that is running is not the version installed in C<local/>. It does this at two points: First right before run-time and Second right after a perl is installed into C<local/>. During restart, C<App::MechaCPAN> will attempt to install itself into C<local/> unless it was invoked as a fully-contained version of C<mechacpan>.

The scripts and modules that come with C<App::MechaCPAN> are prepared to handle this. If you use C<App::MechaCPAN> as a module, you should to be prepared to handle it as well.

This means that any END and DESTROY blocks B<WILL NOT RUN>. Anything created with File::Temp will be cleaned up, however.

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2017- Jon Gentle

=head1 LICENSE

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=over

=item L<App::cpanminus>

=item L<local::lib>

=item L<Carton>

=item L<CPAN>

=item L<plenv|https://github.com/tokuhirom/plenv>

=item L<App::perlbrew>

=back

=cut
