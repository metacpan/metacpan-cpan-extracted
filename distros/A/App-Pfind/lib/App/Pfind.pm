package App::Pfind;

use 5.022;
use strict;
use warnings;

use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev no_ignore_case
                    permute auto_version);
use Pod::Usage;
use File::Find;
use Safe;

our $VERSION = '1.03';

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

sub prune {
  die "The prune command cannot be used when --depth-first is set.\n" if $options{depth_first};
  $File::Find::prune = 1;
}

sub reset_options {
  $safe = Safe->new();
  $safe->deny_only(':ownprocess', ':others', ':dangerous');
  $safe->reval('use File::Spec::Functions qw(:ALL);');
  $safe->share('$internal_pfind_dir', '$internal_pfind_name', 'prune');

  # Whether to process the content of a directory before the directory itself.
  $options{depth_first} = 0;
  # Whether to follow the symlinks.
  $options{follow} = 0;
  # Whether to follow the symlinks using a fast method that may process some files twice.
  $options{follow_fast} = 0;
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
  # Whether to chdir in the crawled directories
  $options{chdir} = 1;
  # Whether to catch errors returned in $! in user code
  $options{catch_errors} = 1;  # non-modifiable for now.
  # Add this string after each print statement
  $options{print} = "\n";
}

sub all_options {(
  'help|h' => sub { pod2usage(-exitval => 0, -verbose => 2) },
  'depth-first|depth|d!' => \$options{depth_first},
  'follow|f!' => \$options{follow},
  'follow-fast|ff!' => \$options{follow_fast},
  'chdir!' => \$options{chdir},
  'print|p=s' => \$options{print},
  'begin|BEGIN|B=s@' => $options{begin},
  'end|END|E=s@' => $options{end},
  'pre|pre-process=s@' => $options{pre},
  'post|post-process=s@' => $options{post},
  'exec|e=s@' => $options{exec}
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
  my ($code_blocks, $default_variable_value) = @_;
  # We're building a sub that will execute each given piece of code in a block.
  # That way we can evaluate this code in the safe once and get the sub
  # reference (so that it does not need to be recompiled for each file). In
  # addition, control flow keywords (mainly next, redo and return) can be used
  # in each block.
  my $block_start = '{ my $tmp_pfind_default = '.$default_variable_value.'; '
                    .'local $_ = $tmp_pfind_default;'
                    .'local $dir = $internal_pfind_dir;'
                    .'local $name = $internal_pfind_name;';
  my $block_end = $options{catch_errors} ? '} die "$!\n" if $!;' : '} ';
  my $all_exec_code = "sub { ${block_start}".join("${block_end} \n ${block_start}", @$code_blocks)."${block_end} }";
  return eval_code($all_exec_code, 'exec');
}

sub create_wrapped_sub_executor {
  my ($wrapped_code, $flag) = @_;
  return sub {
    # Instead of using our local variables, we could share the real one here:
    # $safe->share_from('File::Find', ['$dir', '$name']);
    # They have to be shared inside the sub as they are 'localized' each time.
    # That approach would be slower by a small factor though.
    $dir_setter->set($File::Find::dir);
    $name_setter->set($File::Find::name);
    $wrapped_code->();
    die "Failure in the code given to --${flag}: $!\n" if $!;
    return @_;
  }
}

sub Run {
  my ($argv) = @_;
  
  reset_options();
  # After the GetOptions call this will contain the input directories.
  my @inputs = @$argv;
  GetOptionsFromArray(\@inputs, all_options())
    or pod2usage(-exitval => 2, -verbose => 0);
    
  if (not @{$options{exec}}) {
    $options{exec} = ['print'];
  }
  
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

  $\ = $options{print};
  
  for my $c (@{$options{begin}}) {
    eval_code($c, 'BEGIN');
  }
  
  my $wrapped_exec = wrap_code_blocks($options{exec}, '$_');
  # The $_ variable inside these method will be set to $File::Find::dir (as the
  # real $_ does not contain anything useful in that case).
  my $pre_option;
  if (@{$options{pre}}) {
    my $wrapped_pre = wrap_code_blocks($options{pre}, '$internal_pfind_dir');
    $pre_option = create_wrapped_sub_executor($wrapped_pre, 'pre-process');
  }
  my $post_option;
  if (@{$options{post}}) {
    my $wrapped_post = wrap_code_blocks($options{post}, '$internal_pfind_dir');
    $post_option = create_wrapped_sub_executor($wrapped_post, 'post-process');
  }
  
  find({
    bydepth => $options{depth_first},
    follow => $options{follow},
    follow_fast => $options{follow_fast},
    no_chdir => !$options{chdir},
    wanted => create_wrapped_sub_executor($wrapped_exec, 'exec'),
    preprocess => $pre_option,
    postprocess => $post_option,
  }, @inputs);

  for my $c (@{$options{end}}) {
    eval_code($c, 'BEGIN');
  }
}

1;
