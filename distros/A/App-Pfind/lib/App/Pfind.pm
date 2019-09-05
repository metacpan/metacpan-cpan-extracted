package App::Pfind;

use 5.022;
use strict;
use warnings;

use Data::Dumper;
use Fcntl ':mode';
use File::Find;
use File::Path qw(make_path remove_tree);
use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev no_ignore_case
                    permute auto_version);
use Pod::Usage;
use Safe;

our $VERSION = '1.05';

$Data::Dumper::Terse = 1;  # Don't output variable names.
$Data::Dumper::Sortkeys = 1;  # Sort the content of the hash variables.
$Data::Dumper::Useqq = 1;  # Use double quote for string (better escaping).

{
  # A simple way to make a scalar be read-only.
  package App::Pfind::ReadOnlyVar;
  sub TIESCALAR {
    my ($class, $value) = @_;
    return bless \$value, $class;
  }
  sub FETCH {
    my ($self) = @_;
    return $$self;
  }
  # Does nothing. We could warn_or_die, but it does not play well with the fact
  # that we are inside the safe.
  sub STORE {}
  # Secret hidden methods for our usage only. These methods can't be used
  # through the tie-ed variable, but only through the object returned by the
  # call to tie.
  sub set {
    my ($self, $value) = @_;
    $$self = $value;
  }
}

# These two variables are shared with the user code. They have this name as a
# localized copy is passed to the code.
our ($internal_pfind_dir, $internal_pfind_name);
my $dir_setter = tie $internal_pfind_dir, 'App::Pfind::ReadOnlyVar';
my $name_setter = tie $internal_pfind_name, 'App::Pfind::ReadOnlyVar';

# A Safe object, created in reset_options.
my $safe;

# This hash contains options that are global for the whole program.
my %options;

# Methods that are shared with the safe:

sub prune {
  die "The prune command cannot be used when --depth-first is set.\n" if $options{depth_first};
  $File::Find::prune = 1;
}
# The prototype means that $_ will be used if nothing else is passed.
sub mkdir(_;@) {
  my $err;
  make_path(@_, { error => \$err });
  # make_path sets $! on success (as it test the existance of the file).
  undef $!;
  $! = join(', ', @$err) if @$err;
}
sub rmdir(_;@) {
  for my $d (@_) {
    CORE::rmdir($d);
  }
}
# A safe 'rm' that does not recurse into directories.
sub rm(_;@) {
  for my $f (@_) {
    if (-d $f) {
      CORE::rmdir($f);
      return if $!;
    } else {
      my $err;
      remove_tree($f, { error => \$err });
      undef $!;
      $! = join(', ', @$err) if @$err;
    }
  }
}
sub rmtree(_;@) {
  my $err;
  remove_tree(@_, { error => \$err });
  undef $!;
  $! = join(', ', @$err) if @$err;
}

sub reset_options {
  $safe = Safe->new();
  $safe->deny_only(':ownprocess', ':others', ':dangerous');
  $safe->reval('use File::Spec::Functions qw(:ALL);');
  $safe->reval('use File::Copy qw(cp mv)');
  $safe->share('$internal_pfind_dir', '$internal_pfind_name', 'prune', 'mkdir',
               'rmdir', 'rm', 'rmtree');
  $safe->share_from('main', ['*STDERR']);

  # Whether to process the content of a directory before the directory itself.
  $options{depth_first} = 0;
  # Whether to follow the symlinks.
  $options{follow} = 0;
  # Whether to follow the symlinks using a fast method that may process some files twice.
  $options{follow_fast} = 0;
  # Whether to recurse in directories.
  $options{recurse} = 1;
  # Blocks of code to execute before the main loop
  $options{begin} = [];
  # Blocks of code to execute after the main loop
  $options{end} = [];
  # Blocks of code to execute for each file and directory encountered
  $options{exec} = [];
  # Blocks of code to execute at the beginning of the processing of each directory
  $options{pre} = [];
  # Blocks of code to execute at the end of the processing of each directory
  $options{post} = [];
  # Type of files that are processed. Note that after the reading of the option, this is concatenated in a string.
  $options{type} = [];
  # Whether to chdir in the crawled directories
  $options{chdir} = 1;
  # Whether to catch errors returned in $! in user code
  $options{catch_errors} = 1;  # non-modifiable for now.
  # Add this string after each print statement
  $options{print} = "\n";
  # If true, debug message are printed on STDERR
  $options{verbose} = 0;
}

sub all_options {(
  'help|h' => sub { pod2usage(-exitval => 0, -verbose => 2) },
  'depth-first|depth|d!' => \$options{depth_first},
  'follow|f!' => \$options{follow},
  'follow-fast|ff!' => \$options{follow_fast},
  'recurse|r!' => \$options{recurse},
  'type|t=s@' => $options{type},
  'chdir!' => \$options{chdir},
  'print|p=s' => \$options{print},
  'begin|BEGIN|B=s@' => $options{begin},
  'end|END|E=s@' => $options{end},
  'pre|pre-process=s@' => $options{pre},
  'post|post-process=s@' => $options{post},
  'exec|e=s@' => $options{exec},
  'verbose|v|V+' => \$options{verbose},
)}

sub eval_code {
  my ($code, $flag) = @_;
  my $r = $safe->reval($code);
  if ($@) {
    die "Failure in the code given to --${flag}: ${@}\n";
  }
  return $r;
}

sub wrap_code_blocks {
  my ($code_blocks, $default_variable_value, $flag) = @_;
  # We're building a sub that will execute each given piece of code in a block.
  # That way we can evaluate this code in the safe once and get the sub
  # reference (so that it does not need to be recompiled for each file). In
  # addition, control flow keywords (mainly next, redo and return) can be used
  # in each block.
  my $block_start = '{ my $tmp_pfind_default = '.$default_variable_value.'; ';
  $block_start .= "print { *STDERR } 'Executing code $flag:'.\$internal_pfind_block_count++;" if $options{verbose};
  $block_start .= 'local $_ = $tmp_pfind_default;'
                  .'local $dir = $internal_pfind_dir;'
                  .'local $name = $internal_pfind_name;';
  my $block_end = $options{catch_errors} ? '} die "$!\n" if $!;' : '} ';
  my $all_exec_code = 'sub { my $internal_pfind_block_count = 1;'
                      .${block_start}.join("${block_end} \n ${block_start}", @$code_blocks).${block_end}
                      .' }';
  print STDERR $all_exec_code if $options{verbose} > 2;
  return eval_code($all_exec_code, 'exec');
}

sub run_wrapped_sub {
  my ($wrapped_code, $flag) = @_;
  # Instead of using our local variables, we could share the real one here:
  # $safe->share_from('File::Find', ['$dir', '$name']);
  # They have to be shared inside the sub as they are 'localized' each time.
  # That approach would be slower by a small factor though.
  $dir_setter->set($File::Find::dir);
  $name_setter->set($File::Find::name);
  undef $!;
  $wrapped_code->();
  die "Failure in the code given to --${flag}: $!\n" if $!;
}

# Perform a real-stat or just reads the result from the previous stat. Returns
# just the mode part of the stat.
my $last_stated_file = '';
sub cheap_stat {
  my ($relative_file_name, $full_file_name) = @_;
  return (stat(_))[2] if $full_file_name eq $last_stated_file;
  $last_stated_file = $full_file_name;
  # When executing find in follow mode, the current file has already been
  # stat-ed (this is guaranteed by find), so we can re-use the value using `_`.
  return (stat(_))[2] if $options{follow} || $options{follow_fast};
  return (stat($relative_file_name))[2];
}

my %file_mode = (
    f => S_IFREG,   # regular file
    d => S_IFDIR,   # directory
    l => S_IFLNK,   # symbolic link
    b => S_IFBLK,   # block special file
    c => S_IFCHR,   # character special file
    p => S_IFIFO,   # fifo (pipe)
    s => S_IFSOCK,  # socket
    # S_IFWHT and S_ENFMT are not supported (they're Sys-V specific features)
  );

sub should_skip_file {
  my ($relative_file_name, $full_file_name) = @_;
  return 0 unless %{$options{type}};
  my $mode = cheap_stat($relative_file_name, $full_file_name);
  for my $m (keys(%{$options{type}})) {
    if (($mode & $file_mode{$m}) xor $options{type}{$m}) {
      print STDERR "Skipping '$full_file_name' due to '$m' type" if $options{verbose};
      return 1;
    }
  }
  return 0;
}

sub Run {
  my ($argv) = @_;
  
  reset_options();
  # After the GetOptions call this will contain the input directories.
  my @inputs = @$argv;
  GetOptionsFromArray(\@inputs, all_options())
    or pod2usage(-exitval => 2, -verbose => 0);
    
  # With this the -v option (--verbose) will still trigger the behavior of the
  # --version option (although it won't stop the execution).
  Getopt::Long::VersionMessage({-exitval => 'NOEXIT', -output => \*STDERR}) if $options{verbose};
    
  if (not @{$options{exec}}) {
    $options{exec} = ['print $name'];
  }
  
  $options{type} = { map { lc() => ($_ eq lc()) } split(//, join('', @{$options{type}})) };
  
  print STDERR "options = ".Dumper({%options}) if $options{verbose} > 1;
  
  if ($options{follow} && $options{follow_fast}) {
    die "The --follow and --follow-fast options cannot be used together.\n";
  }
  my $follow_mode = $options{follow} || $options{follow_fast};
  if (@{$options{pre}} && $follow_mode) {
    die "The --pre-process option cannot be used with --follow or --follow-fast.\n";
  }
  if (@{$options{post}} && $follow_mode) {
    die "The --post-process option cannot be used with --follow or --follow-fast.\n";
  }
  if (not $options{recurse} and $options{depth_first}) {
    die "The --no-recurse option cannot be used with --depth-first.\n";
  }
  if (join('', keys %{$options{type}}) !~ /^[fdlpsbc]*$/) {
    die "Unsupported value for the --type option.\n";
  }
  if (not @inputs) {
    print STDERR "No input given on the command-line. Exiting without doing any work.";
    exit 1;
  }

  $\ = $options{print};
  
  for my $c (@{$options{begin}}) {
    eval_code($c, 'BEGIN');
  }
  
  my $wrapped_exec = wrap_code_blocks($options{exec}, '$_', 'exec');
  # The $_ variable inside these method will be set to $File::Find::dir (as the
  # real $_ does not contain anything useful in that case).
  my $wrapped_pre;
  if (@{$options{pre}}) {
    $wrapped_pre = wrap_code_blocks($options{pre}, '$internal_pfind_dir', 'pre');
  }
  my $wrapped_post;
  if (@{$options{post}}) {
    $wrapped_post = wrap_code_blocks($options{post}, '$internal_pfind_dir', 'post');
  }

  find({
    bydepth => $options{depth_first},
    follow => $options{follow},
    follow_fast => $options{follow_fast},
    no_chdir => !$options{chdir},
    wanted => sub {
      if (not $options{recurse} and cheap_stat($_, $File::Find::name) & S_IFDIR) {
        print "Will not recurse into $File::Find::name" if $options{verbose};
        $File::Find::prune = 1;
      }
      print STDERR "Looking at file: $File::Find::name" if $options{verbose};
      return if should_skip_file($_, $File::Find::name);
      run_wrapped_sub($wrapped_exec, 'exec');
    },
    preprocess => sub {
      print STDERR "Entering: $File::Find::dir" if $options{verbose};
      run_wrapped_sub($wrapped_pre, 'pre-process') if $wrapped_pre;
      return @_;  # Needed by find().
    },
    postprocess => sub {
      print STDERR "Exiting: $File::Find::dir" if $options{verbose};
      run_wrapped_sub($wrapped_post, 'post-process') if $wrapped_post;
    }
  }, @inputs);

  for my $c (@{$options{end}}) {
    eval_code($c, 'BEGIN');
  }
}

1;
