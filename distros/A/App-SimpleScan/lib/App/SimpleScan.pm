package App::SimpleScan;

use warnings;
use strict;
use English qw(-no_match_vars);

our $VERSION = '3.01';

use Carp;
use Getopt::Long;
use Regexp::Common;
use Scalar::Util qw(blessed);
use WWW::Mechanize;
use WWW::Mechanize::Pluggable;
use Test::WWW::Simple;
use App::SimpleScan::TestSpec;
use App::SimpleScan::Substitution;
use Graph;

use Module::Pluggable search_path => [qw(App::SimpleScan::Plugin)];

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(sub_engine tests test_count 
                             next_line_callbacks _deps));

$|++;                                                   ##no critic

use App::SimpleScan::TestSpec;

my $reference_mech = new WWW::Mechanize::Pluggable;
my $sub_engine     = new App::SimpleScan::Substitution;

my @local_pragma_support =
  (
    ['agent'   => \&_do_agent],
    ['nocache'   => \&_do_nocache],
    ['cache'   => \&_do_cache],
  );

# Variables and setup for basic command-line options.
my($generate, $run, $warn, $override, $defer, $debug);
my($cache_from_cmdline, $no_agent);
my($run_status);

# Option-to-variable mappings for Getopt::Long
my %basic_options = 
  ('generate'  => \$generate,
   'run'       => \$run,
   'warn'      => \$warn,
   'override'  => \$override,
   'defer'     => \$defer,
   'debug'     => \$debug,
   'autocache' => \$cache_from_cmdline,
   'no-agent'  => \$no_agent,
   'status'    => \$run_status,
  );

use base qw(Class::Accessor::Fast);

# Patterns to extract <variables> or >variables< from a string.
my $out_angled;
$out_angled = qr/ < ( [^<>] | (??{$out_angled}) )* > /x;
                  # open angle-bracket then ...
                      # non-angle chars ...
                            # or ...
                               # another angle-bracketed item ...
                                                 # if there are any ...
                                                   # and a close angle-bracket
my $in_angled;
$in_angled  = qr/ > ( [^<>] | (??{$in_angled}) )* < /x;
                  # open angle-bracket then ...
                      # non-angle chars ...
                            # or ...
                               # another angle-bracketed item ...
                                                 # if there are any ...
                                                   # and a close angle-bracket
my $in_or_out_bracketed = qr/ ($out_angled) | ($in_angled) /x;

################################
# Basic class methods.

# Create the object. 
# - load and install plugins
# - make object available to test specs for callbacks
# - clear the tests and test count
# - process the command-line options
# - return the object
sub new {
  my ($class) = @_;
  my $self = {};
  bless $self, $class;

  $self->_deps(Graph->new);
  $self->sub_engine($sub_engine);

  # initialize fields first; plugins may expect good values.
  $self->next_line_callbacks([]);
  $self->tests([]);
  $self->test_count(0);
  $self->{InputQueue} = [];

  # Load and install the plugins.
  $self->_load_plugins();
  $self->install_pragma_plugins;

  # TestSpec needs to be able to find the App object.
  App::SimpleScan::TestSpec->app($self);

  # Read the command line and process the options.
  $self->handle_options;

  return $self;
}

# Read the test specs and turn them into tests.
# Add any additional code from the plugins.
# Return the tests as a string.
sub create_tests {
  my ($self) = @_;

  $self->transform_test_specs;
  $self->finalize_tests;
  return join q{}, @{$self->tests};
}

# If the tests should be run, run them.
# Return any exceptions to the caller.
sub execute {
  my ($self, $code) = @_;
  eval $code if ${$self->run};                         ##no critic
  return $EVAL_ERROR;
}

# Actually use the object.
# - create tests from input
# - run them if we should
# - print them if we should
sub go {
  my($self) = @_;
  my $exit_code = 0;

  my $code = $self->create_tests;
  # Note the dereference of the scalars here.

  if ($self->test_count) {
    if (my $result = $self->execute($code)) {
       warn $result,"\n";
       $exit_code = 1;
    }
  } 
  else {
    if (${$self->warn}) {
      $self->stack_test(qq(fail "No tests were found in your input file.\n"));
      $exit_code = 1;
    }
  }

  if (${$self->generate}) {
    print $code,"\n";
  }

  return $exit_code;
}

# Read files from command line or standard input.
# Turn these from test specs into test code.
sub transform_test_specs {
  my ($self) = @_;
  local $_;                                             ##no critic
  while(defined($_ = $self->next_line)) {               ##no critic
    chomp;
    # Discard comments.
    /^\#/mx and next;

    # Discard blank lines.
    /^\s*$/mx and next;

    # Handle pragmas.
    /^%%      # pragma signifier
     \s*      # optional space
     (.*?)    # arbitrary identifier
     (        # either ...
      (
       (:\s+|\s+)   # an optional colon, and whitespace
       (.*)$        # then a optional value
      )|            # ... or
      $             # nothing at all
     )/mx and do {
      if (my $code = $self->pragma($1)) {
        $code->($self,$5);
      }
      else {
        # It's a substitution if it has no other meaning.
        if (defined $5) {
          my $var = $1;
          # Check if the variable name needs to be substituted.
          if ($var =~ /$in_or_out_bracketed/) {
            next if $self->_queue_substituted_lines($_);
          }
          my @data = $self->expand_backticked($5);
          my ($status, $message) = $self->_check_dependencies($var, @data);
          if ($status) {
            $self->_substitution_data($var, @data);
          }
          else {
            my @items = split $message;
            my $between = (@items < 3) ? 'between' : 'among';
            $self->stack_test( qw(fail "Cannot add substitution for $var: dependency loop $between $message";\n));
          }
        }
      }
      next;
    };

    # Commit any substitutions.
    # We use 'next' because the substituted lines
    # will have been queued on the input if there
    # where any substitutions.
    #
    # We do this *after* pragma processing because 
    # if we have this:
    #  %%foo bar baz
    #  %%quux <foo> is the value
    #
    # and we expanded pragmas in place, we'd get
    #  %%foo bar baz
    #  %%quux bar
    #  %%quux baz
    #
    # which is probably *not* what is wanted.
    # Putting this here makes sure that we only
    # substitute into actual test specs.
    next if $self->_queue_substituted_lines($_);

    # No substitutions in this line, so just process it.
    my $item = App::SimpleScan::TestSpec->new($_);

    # Store it in case a plugin needs to look at the 
    # test spec in an overriding method.
    $self->set_current_spec($item);

    if ($item->syntax_error) {
      $self->stack_code(<<"END_MSG");
# @{[$item->raw]}
# Possible syntax error in this test spec
END_MSG
    }
    else {
      $item->as_tests;
      local $_ = $item ->raw;                           ##no critic
      s/\n//mx;
    }
    # Drop the spec (there isn't one active now).
    $self->set_current_spec();
  }
  return;
}

# Calls each plugin's test_modules method
# to stack any other test modules needed to
# properly handle the test code. (Plugins may
# want to generate test code that needs 
# something like Test::Differences, etc. - 
# this lets them load that module so the
# tests actually work.)
#
# Also adds the test plan.
#
# Finally, initializes the user agent (unless
# we're specifically directed *not* to do so).
sub finalize_tests {
  my ($self) = @_;
  my @tests = @{$self->tests};
  my @prepends;
  foreach my $plugin (__PACKAGE__->plugins) {
    if ($plugin->can('test_modules')) {
      foreach my $module ($plugin->test_modules) {
        push @prepends, "use $module;\n";
      }
    }
  }
  # Handle conditional user agent initialization.
  # This was added because some servers (e.g., WAP
  # servers) refuse connections from known user agents,
  # but others (e.g., Yahoo!'s web servers) refuse 
  # login attempts from non-browser user agents.
  #
  # Set the user agent unless --no-agent was given.

  if (!$self->no_agent) {
    push @prepends, qq(mech->agent_alias("Windows IE 6");\n);
  }
 
  # Add the boilerplate testing stuff. 
  unshift @prepends, 
    (
      "use Test::More tests=>@{[$self->test_count]};\n",
      "use Test::WWW::Simple;\n",
      "use strict;\n",
      "\n",
    );
  
  
  $self->tests( [ @prepends, @tests ] );
  return;
}

#######################
# External utility methods.

# Handle backticked values in substitutions.
sub expand_backticked {
  use re 'eval';

  my ($self, $text) = @_;

  # The state machine was a really cool idea, except it didn't work. :-P
  # A little reading in Mastering Regular Expressions gave me the patterns
  # shown below for matching quoted strings.

  # For an explanation of why this works, see Friedl, p. 262 ff.
  # It's called "unrolling" the regex there.

  #  Pattern: quote (nonspecial)*(escape anything (nonspecial)*)* quote
  my $qregex  = qr/'[^'\\]*(?:\\.[^'\\]*)*'/;
  my $qqregex = qr/"[^"\\]*(?:\\.[^"\\]*)*"/;
  my $qxregex = qr/`[^`\\]*(?:\\.[^`\\]*)*`/;

  # Plus we need the cleanup tokenizer: match anything nonblank. This
  # picks up tokens that are not properly-balanced quoted strings.
  # We'll trap those later, or not. We'll see.
  my $cleanup = qr/\S+/;

  # An item is a quoted string of any flavor, or the cleanup item.
  # We turn on the capturing parens here because it we match an item,
  # we want it.
  my $item = qr/($qqregex|$qregex|$qxregex|$cleanup)/;

  # So now, to extract the items, we just match this with /g against the
  # incoming text. We know already this is a single line, so we don't need
  # any other switches. Boy, that's simpler.
  my @data = ($text =~ /$item/g);

  # Evaluate the tokens. 
  my @result;
  local $_;
  for (@data) {
    next unless defined;

    # Backticked: eval and process again.
    if (/^\`(.*)`$/mx) {
      push @result, $self->expand_backticked(eval $_);      ##no critic
    }
    # Double-quoted: eval it.
    elsif (/^"(.*)"$/mx) {
      my $to_be_evaled = $1;
      my @substituted = $self->sub_engine->expand($to_be_evaled);
      push @result, map { eval $_ } @substituted;          ##no critic
    }
    # Single-quoted: remove quotes.
    elsif (/^'(.*)'$/mx) {
      push @result, $1;
    }
    # Just an unquoted token. Save it.
    else {
      push @result, $_;
    }
  }
  return @result;
}

sub set_current_spec {
  my ($self, $testspec) = @_;
  $self->{CurrentTestSpec} = $testspec;
  return $testspec;
}

sub get_current_spec {
  my ($self) = @_;
  return $self->{CurrentTestSpec};
}

# If there are any substitutions, build them, stack them on the input,  
# and return true. Otherwise, just return false so the line will be passed on.
sub _queue_substituted_lines {
  my ($self, $line) = @_;
  my @results = $self->sub_engine->expand($line);

  if (@results != 1) {
    # substitutions definitely happened
    $self->queue_lines(@results);
    return 1;
  }
  elsif ($results[0] ne $line) {
    # single line is different, so substitution(s) happened
    $self->queue_lines(@results);
    return 1;
  }
  else {
    # nothing happened, just process it as is
    return 0;
  }
}

# Wrapper function for setter/getter that implements the
# override function (command-line substitutions override 
# substitutions in the input).
sub _substitution_data {
  my ($self, $pragma_name, @pragma_values) = @_;
  if (! defined $pragma_name) {
    croak 'No pragma specified';
  }

  if (@pragma_values) {
    if (${$self->override} and 
        $self->{Predefs}->{$pragma_name}) {
      if (${$self->debug}) {
        $self->stack_code(qq(diag "Substitution $pragma_name not altered to '@pragma_values'";\n));
      }
    }
    else {
      $self->sub_engine->substitution_value($pragma_name, @pragma_values);
    }
  }
  else {
    $self->sub_engine->substitution_value($pragma_name);
  }
  return 
    wantarray ? @{$self->sub_engine->dictionary->{$pragma_name}}
              : $self->sub_engine->dictionary->{$pragma_name};
}

sub _delete_substitution {
  my ($self, $substitution) = @_;
  return $self->sub_engine->delete_substitution($substitution);
}

########################
# Options methods

sub handle_options {
  my ($self) = @_;

  # Handle options, including ones from the plugins.
  $self->install_options(%basic_options);

  # The --define option has to be handled slightly differently.
  # We set things up so that we have a hash of predefined variables
  # in the object; that way, we can set them up appropriately, and
  # know whether or not they should be checked for override/defer
  # when a definition is found in the simple_scan input file.
  $self->{Options}->{'define=s%'} = ($self->{Predefs} = {});

  foreach my $plugin (__PACKAGE__->plugins) {
    if ($plugin->can('options')) {
      $self->install_options($plugin->options);
    }
  }

  $self->parse_command_line;

  foreach my $plugin (__PACKAGE__->plugins) {
    if ($plugin->can('validate_options')) {
      $plugin->validate_options($self);
    }
  }

  # If anything was predefined, save it in the substitutions.
  for my $def (keys %{$self->{Predefs}}) {
    $self->sub_engine->substitution_value($def, 
                            (split /\s+/mx, $self->{Predefs}->{$def}));
  }

  if (${$self->no_agent}) {
    $self->sub_engine->substitution_value('agent', 'WWW::Mechanize::Pluggable');
  }
  else {
    $self->sub_engine->substitution_value('agent', 'Windows IE 6');
    $self->stack_code("mech->agent_alias('Windows IE 6');\n");
  }
  
  $self->app_defaults;
  return;
}

# Set up application defaults.
sub app_defaults {
  my ($self) = @_;
  # Assume --run if neither --run nor --generate.
  if (!defined ${$self->generate()} and
      !defined ${$self->run()}) {
    $self->run(\1);
  }

  # Assume --defer if neither --defer nor --override.
  if (!defined ${$self->defer()} and
      !defined ${$self->override()}) {
    $self->defer(\1);
  }

  # if --cache was supplied, turn caching on.
  if (${$self->autocache}) {
    $self->stack_code(qq(cache;\n));
  }

  return;
}

# Transform the options specs (whether from here or
# from plugins) into methods that we can call to
# set/get the option values.
sub install_options {
  my ($self, @options) = @_;
  if (! defined $self->{Options}) {
    $self->{Options} = {};
  }

  # precompilation versions of the possible methods. These
  # get compiled right when we need them, causing $option
  # to be capturd as a closure.

  while (@options) {
    # This coding is deliberate.
    #
    # We want a separate copy of $option and 
    # $receiver each time; we don't want a new
    # copy of @options, because we want to keep
    # effectively shifting two values off each
    # time around the loop.
    #
    # Note that the generated method returns a 
    # reference to the variable that the option is
    # stored into; this makes it simpler to code
    # the accessor here. If you use an array or
    # hash to receive values in your Getopt spec,
    # you'll have to dereference it properly in
    # your code.
    (my($option, $receiver), @options) = @options;

    # Method names containing dashes are a no-no;
    # swap them to underscores. (This is okay because
    # no one outside this module should be trying to
    # call these methods directly.)
    $option =~ s/-/_/mxg;

    $self->{Options}->{$option} = $receiver;

    # Ensure that the variables have been cleared if we create another
    # App::SimpleScan object (normally we won't, but our tests do).
    ${ $receiver } = undef;

    # Create method if it doesn't exist.
    if (! $self->can($option)) {
      use Sub::Installer;
      __PACKAGE__->install_sub(
        { $option => sub { 
                           my ($self, $value) = @_;
                           if (defined $value) {
                             $self->{Options}->{$option} = $value;
                           }
                           return $self->{Options}->{$option};
                         }
        }
      ); 
    }
  }
  return;
}

# Load all the plugins.
sub _load_plugins {
  my($self) = @_;

  # Load plugins.
  foreach my $plugin (__PACKAGE__->plugins) {
    eval "use $plugin";                                      ##no critic
    $EVAL_ERROR and die "Plugin $plugin failed to load: $EVAL_ERROR\n";
  }

  # Install source filters
  $self->{Filters} = [];
  foreach my $plugin (__PACKAGE__->plugins) {
    if ($plugin->can('filters')) {
      push @{$self->{Filters}}, $plugin->filters();
    }
    # Initialize plugin data if possible. 
    if ($plugin->can('init')) {
      $plugin->init($self);
    }
  }

  return;
}

# Call Getopt::Long to parse the command line.
sub parse_command_line {
  my ($self) = @_;
  return GetOptions(%{$self->{Options}});
}

# Install any pragmas supplied by plugins.
# We reuse this same code to install all of
# the locally defined pragmas.
sub install_pragma_plugins {
  my ($self) = @_;

  foreach my $plugin (@local_pragma_support, 
                      __PACKAGE__->plugins) {
    if (ref $plugin eq 'ARRAY') {
      $self->pragma(@{ $plugin });
    }
    elsif ($plugin->can('pragmas')) {
      foreach my $pragma_spec ($plugin->pragmas) {
        $self->pragma(@{ $pragma_spec });
      }
    }
  }
  return;
}

########################
# Pragma methods and handlers

# Find the pragma code associated with the name.
sub pragma {
  my ($self, $name, $pragma) = @_;
  die "You forgot the pragma name\n" if ! defined $name;
  if (defined $pragma) {
    $self->{Pragma}->{$name} = $pragma;
  }
  return $self->{Pragma}->{$name};
}

# %%agent pragma handler. Verify that the argument
# is a valid WW::Mechanize agent alias string, and
# stack code to change it as appropriate.
sub _do_agent {
  my ($self, $rest) = @_;
  $rest = reverse $rest;
  my ($maybe_agent) = ($rest =~/^\s*(.*)$/mx);
  
  $maybe_agent = reverse $maybe_agent; 
  if (grep { $_ eq $maybe_agent } $reference_mech->known_agent_aliases) {
    $self->_substitution_data('agent', $maybe_agent)
  }
  $self->stack_code(qq(user_agent("$maybe_agent");\n));
  return;
}

# %%cache - turn on Test::WWW::Simple's cache.
sub _do_cache {
  my ($self,$rest) = @_;
  $self->stack_code("cache();\n");
  return;
}

# %%nocache - turn off Test::WWW::Simple's cache.
sub _do_nocache {
  my ($self,$rest) = @_;
  $self->stack_code("no_cache();\n");
  return;
}

##########################
# Input queueing

# Handle input queueing. If there's anything queued,
# return it first; otherwise, just read another line
# from the magic input filehandle.
sub next_line {
  my ($self) = shift;
  my $next_line;

  # Call and plugin-installed input callbacks.
  # These can do whatever they like to the line stack, the
  # object, etc.
  foreach my $callback (@ {$self->next_line_callbacks() }) {
    $callback->($self);
  }

  # If we have lines on the input queue, read from there.
  if (defined $self->{InputQueue}->[0] ) {
    $next_line = shift @{ $self->{InputQueue} };
  }

  # Else we read lines from the standard input.
  else {
    $next_line = <>;
    if (defined $next_line) {
      $next_line =~ s/\n//mx;
      if ($run_status) {
        print STDERR "# |Processing '$next_line' (line $.)\n";
      }
    }
  }

  # record the text of the last line read for plugins to access
  # if they need it.
  $self->last_line($next_line);

  return $next_line;
}

# Preserve current line so that plugins can look at it
# if they want to.
sub last_line {
  my ($self, $line) = @_;
  if (defined $line) {
    $self->{CurrentLine} = $line;
  }
  return $self->{CurrentLine};
}

# Handle input stacking by pragmas. Add any new lines
# to the head of the queue.
sub queue_lines {
  my ($self, @lines) = @_;
  $self->{InputQueue} = [ @lines, @{ $self->{InputQueue} } ];
  return;
}

###########################
# Output queueing

# stack_code just adds code to the array holding
# the generated program.
sub stack_code {
  my ($self, @code) = @_;
  my @old_code = @{$self->tests};
  $self->tests([@old_code, @code]);
  return
}

# stack_test adds code to the array holding
# the generated program, and bumps the test
# count so we can use the proper number of tests
# in our test plan.
sub stack_test {
  my($self, @code) = @_;
  for my $filter (@{$self->{Filters}}) {
    # Called with $self to make it appear
    # as if it's a method call from this package.
    @code = $filter->($self, @code);
  }
  $self->stack_code(@code);
  return $self->test_count($self->test_count()+1);
}

##################################
# Dependency checking

# It's necessary to make sure that the substitution pragmas
# don't have looping dependencies; these would cause the 
# input stack to grow without limit as it tries to resolve
# all of the substitutions.
#
# All we have to do is make sure that the graph of variable
# relations is a directed acyclic graph. Since actually writing
# all that would be a pain, we use Graph.pm to manage it for us.

sub _check_dependencies {
  my ($self, $var, @dependencies) = @_;
  my $graph = $self->_deps;

  # drop anything that's not a variable definition.
  @dependencies = grep { /^<.*>$/mx } @dependencies;

  # No variables, no dependencies.
  if (! @dependencies) {
    return 1, 'no dependencies';
  }

  # Add the new dependencies.
  $self->_depend($var, @dependencies);
 
  # Run a topological sort to make sure that the
  # graph remains a DAG. If not, returns a cycle.
  # Note that it's possible that there's more than one
  # cycle, though not liekely, since we're checking
  # every time we add a new variable. 
  unless ($graph->is_dag) {
    return (0, $graph->find_a_cycle);
  }

  return 1, "dependencies OK";
}

sub _depend {
  my($self, $item, @dependencies) = @_;

  if (!defined $item) {
    die "You don't want to do that anymore";
  }

  if (!@dependencies) {
    return ([ $self->_deps->successors($item) ]);
  }

  # Add these dependencies for the item.
  $self->_deps->add_edge($item, $_) for @dependencies;    ## no critic
  return;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

App::SimpleScan - simple_scan's core code


=head1 VERSION

This document describes App::SimpleScan version 0.0.1


=head1 SYNOPSIS

    use App::SimpleScan;
    my $app = new App::SimpleScan;
    $app->go;
    

  
=head1 DESCRIPTION

C<App::SimpleScan> allows us to package the core of C<simple_scan>
as a class; most importantly, this allows us to use C<Module::Pluggable>
to write extensions to this application without directly modifying
this module or this C<simple_scan> application.

=head1 IMPORTANT NOTE

The interfaces to this module are still evolving; plugin 
developers should monitor CPAN and look for new versions of
this module. Henceforth, any change to the externals of this
module will be denoted by a full version increase (e.g., from
0.34 to 1.00).

=head1 INTERFACE

=head2 Class methods

=head2 new 

Creates a new instance of the application. Also invokes
all of the basic setup so that when C<go> is called, all
of the plugins are available and all callbacks are in place.

=head2 Instance methods

=head3 Execution methods

=head4 go

Executes the application. Calls the subsidiary methods to
read input, parse it, do substitutions, and transform it into
code; loads the plugins and any code filters which they wish to
install.

After the code is created, it consults the command-line
switches and runs the generated program, prints it, or both.

=head4 create_tests

Transforms the input into code, and finalizes them, 
returning the actual test code (if any) to its caller.

=head2 transform_test_specs

Does all the work of transforming test specs into code,
including processing substitutions, test specs, and
pragmas, and handling substitutions.

=head2 finalize_tests

Adds all of the Perl modules required to run the tests to the 
test code generated by this module. This includes any
modules specified by plugins via the plugin's C<test_modules>
class method.

=head2 execute

Actually run the generated test code. Currently just C<eval>'s
the generated code.

=head3 Options methods

=head4 parse_command_line

Parses the command line and sets the corresponding fields in the
C<App::SimpleScan> object. See the X<EXTENDING SIMPLESCAN> section 
for more information.

=head4 handle_options

This method initializes your C<App::SimpleScan> object. It installs the
standard options (--run, --generate, and --warn), installs any
options defined by plugins, and then calls C<parse_command_line> to
actually parse the command line and set the options.

=head4 install_options(option => receiving_variable, "method_name")

Plugin method - optional.

Installs an entry into the options description passed
to C<GeOptions> when C<parse_command_line> is called. This 
automatically creates an accessor for the option.
The option description(s) should conform to the requirements 
of C<GetOpt::Long>.

You may specify as many option descriptions as you like in a 
single call. Remember that your option definitions will cause
a new method to be created for each option; be careful not to
accidentally override a pre-existing method ... unless you 
want to do that, for whatever reason.

=head4 app_defaults

Set up the default assumptions for the application. Simply 
turns C<run> on if neither C<run> nor C<generate> is specified.

=head2 Pragma methods

=head3 install_pragma_plugins

This installs the standard pragmas (C<cache>, C<nocache>, and 
C<agent>). Checks each plugin for a C<pragmas> method and
calls it to get the pragmas to be installed. In addition,
if any pragmas are found, calls the corresponding plugin's
C<init> method if it exists.

=head3 pragma

Provides access to pragma-processing code. Useful in plugins to 
get to the pragmas installed for the plugin concerned.

=head2 Input/output methods

=head3 next_line

Reads the next line of input, handling the possibility that a plugin
or substitution processing has stacked lines on the input queue to 
be read and processed (or perhaps reprocessed).

=head3 expand_backticked

Core and plugin method - a useful line-parsing utility.

Expands single-quoted, double-quoted, and backticked items in a
text string as follows:

=over 4 

=item * single-quoted: remove the quotes and use the string as-is.

=item * double-quoted: eval() the string in the current context and embed the result.

=item * backquoted: evaluate the string as a shell command and embed the output.

=back

=head3 queue_lines

Queues one or more lines of input ahead of the current "next line".

If no lines have been queued yet, simply adds the lines to the input
queue. If there are existing lines in the input queue, lines passed
to this routine are queued I<ahead> of those lines, like this:

  # Input queue = ()
  # $app->queue_lines("save this")
  #
  # Input queue now = ("save this")
  # $app->queue_lines("this one", "another")
  #
  # input queue now = ("this one", "another", "save this")

This is done so that if a pragma queues lines which are other pragmas,
these get processed before any other pending input does.

=head3 set_current_spec

Save the object passed as the current test spec. If no 
argument is passed, deletes the current test spec object.

=head3 get_current_spec

Plugin method.

Retrieve the current test spec. Can be used to
extract data from the parsed test spec.

=head3 last_line

Plugin and core method.

Current input line setter/getter. Can be used by
plugins to look at the current line.

=head3 stack_code

Plugin and core method.

Adds code to the final output without incrementing the number of tests.
Does I<not> go through code filters, and does I<not> increment the 
test count.

=head3 stack_test

Adds code to the final output and bumps the test count by one.
The code passes through any plugin code filters.

=head3 tests

Accessor that stores the test code generated during the run.

=head1 EXTENDING SIMPLESCAN

=head2 Adding new command-line options

Plugins can add new command-line options by defining an
C<options> class method which returns a list of 
parameter/variable pairs, like those used to define 
options with C<Getopt::Long>. 

C<App::SimpleScan> will check for the C<options> method in 
your plugin when it is loaded, and call it to install your 
options automatically.

=head2 Adding new pragmas

Plugins can install new pragmas by implementing a C<pragmas>
class method. This method should return a list of array
references, with each array reference containing a 
pragma name and a code reference which will implement the
pragma.

The actual pragma implementation will, when called by
C<transform_test_specs>, receive a reference to the 
C<App::SimpleScan> object and the arguments to the pragma
(from the pragma line in the input) as a string of text. It is
up to the pragma to parse the string; the use of 
C<expand_backticked> is recommended for pragmas which 
take a variable number of arguments, and wish to adhere
to the same syntax that standard substitutions use.

=head1 PLUGIN SUMMARY

Standard plugin methods that App::SimpleScan will look for;
none of these is required, though you should choose to
implement the ones that you actually need.

=head2 Basic callbacks

=head3 init

The C<init> class method is called by C<App:SimpleScan>
when the plugin class is loaded; the C<App::SimpleScan>
object is suppled to allow the plugin to alter or add to the
contents of the object. This allows plugins to export methods
to the base class, or to add instance variables dynamically.

Note that the class passed in to this method is the class
of the I<plugin>, not of the caller (C<App::SimpleScan>
or a derived class). You should use C<caller()> if you wish
to export subroutines into the package corresponding to the 
base class object.

=head3 pragmas

Defines any pragmas that this plugin implements. Returns a 
list of names and subroutine references. These will be called
with a reference to the C<App::SimpleScan> object.

=head3 filters

Defines any code filters that this plugin wants to add to the
output filter queue. These methods are called with a copy
of the App::SimpleScan object and an array of code that is 
about to be stacked. The filter should return an array 
containing either the unaltered code, or the code with any
changes the plugin sees fit to make.

If your filter wants to stack tests, it should call 
C<stack_code> and increment the test count itself (by
a call to test_count); trying to use C<stack_test> in 
a filter will cause it to be called again and again in
an infinite recursive loop.

=head3 test_modules

If your plugin generates code that requires other Perl modules,
its test_modules class method should return an array of the names
of these modules.

=head3 options

Defines options to be added to the command-line options.
You should return an array of items that would be suitable
for passing to C<Getopt::Long>, which is what we'll do 
with them.

=head3 validate_options

Validate your options. You can access any of the variables
you passed to C<options>; these will be initialized with 
whatever values C<Getopt::Long> got from the command line.
You should try to ignore invalid values and choose defaults 
for missing items if possible; if not, you should C<die>
with an appropriate message.

=head2 Methods to alter the input stream

=head3 next_line

If a plugin wishes to read the input stream for its own
purposes, it may do so by using C<next_line>. This returns
either a string or undef (at end of file). 

=head3 stack_input

Adds lines to the input queue ahead of the next line to 
be read from whatever source is supplying them. This allows
your plugin to process a line into multiple lines "in place".

=head2 Methods for outputting code

Your pragma will probably use one of the following methods to 
output code:

=head3 stack_code

A call to C<stack_code> will cause the string passed back to 
be emitted immediately into the code stream. The test count
will remain at its current value. 

=head3 stack_test

C<stack_test> will immediately emit the code supplied as
its argument, and will increment the test count by one. You
should use multiple calls to C<stack_test> if you need
to stack more than one test. 

Code passed to stack_test will go through all of the 
filters in the output filter queue; be careful to not
call C<stack_test> in an output filter, as this will
cause a recursive loop that will run you out of memory.

=head2 Informational methods

=head2 get_current_spec

Returns the current App::SimpleScan::TestSpec 
object, if there is one. If code in your plugin is
called when either we haven't read any lines yet,
or the last line read was a pragma, there won't be
any "current test spec".

=head2 last_line

Returns the actual text of the previous line read.
Plugin code that does not specifically involve the
current line (like output filters) may wish to look
at the current line.

=head1 DIAGNOSTICS

None as yet.

=head1 CONFIGURATION AND ENVIRONMENT

App::SimpleScan requires no configuration files or environment variables.

=head1 DEPENDENCIES

Module::Pluggable and WWW::Mechanize::Pluggable.

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-simplescan@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@yahoo-inc.com > >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Joe McMahon C<< <mcmahon@yahoo-inc.com > >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
