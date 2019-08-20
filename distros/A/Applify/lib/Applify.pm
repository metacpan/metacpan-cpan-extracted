package Applify;
use strict;
use warnings;

use Carp           ();
use File::Basename ();
use Scalar::Util 'blessed';

use constant SUB_NAME_IS_AVAILABLE => $INC{'App/FatPacker/Trace.pm'}
  ? 0    # this will be true when running under "fatpack"
  : eval 'use Sub::Name; 1' ? 1 : 0;

our $INSTANTIATING = 0;
our $PERLDOC       = 'perldoc';
our $SUBCMD_PREFIX = 'command';
our $VERSION = '0.17';
my $ANON = 0;

sub app {
  my $self = shift;
  $self->{app} = shift if @_;

  # Activate sub command
  local @ARGV = @ARGV;
  shift @ARGV if $self->_subcommand_activate($ARGV[0]);

  # Parse command line options
  my $parsed_options
    = $self->option_parser->getoptions(\my %argv, (map { $self->_calculate_option_spec($_) } @{$self->options}),
    $self->_default_options);

  # Check if we should abort running the app based on user argv
  if (!$parsed_options) {
    $self->_exit(1);
  }
  elsif ($argv{help}) {
    $self->print_help;
    $self->_exit('help');
  }
  elsif ($argv{man}) {
    system $PERLDOC => $self->documentation;
    $self->_exit($? >> 8);
  }
  elsif ($argv{version}) {
    $self->print_version;
    $self->_exit('version');
  }

  # Create the application and run (or return) it
  local $INSTANTIATING = 1;
  local $@;
  my $app = eval {
    $self->{application_class} ||= $self->_generate_application_class;
    $self->{application_class}->new(\%argv);
  } or do {
    $@ =~ s!\sat\s.*!!s unless $ENV{APPLIFY_VERBOSE};
    $self->print_help;
    local $! = 1;    # exit value
    die "\nInvalid input:\n\n$@\n";
  };

  return $app if defined wantarray;    # $app = do $script_file;
  $self->_exit($app->run(@ARGV));
}

sub documentation {
  return $_[0]->{documentation} if @_ == 1;
  $_[0]->{documentation} = $_[1] or die 'Usage: documentation $file|$module_name;';
  return $_[0];
}

sub extends {
  my $self = shift;
  $self->{extends} = [@_];
  return $self;
}

sub import {
  my ($class, %args) = @_;
  my @caller = caller;
  my $self   = $class->new({caller => \@caller});
  my $ns     = $caller[0] . '::';
  my %export;

  strict->import;
  warnings->import;

  $self->{skip_subs} = {app => 1, option => 1, version => 1, documentation => 1, extends => 1, subcommand => 1};

  no strict 'refs';
  for my $name (keys %$ns) {
    $self->{'skip_subs'}{$name} = 1;
  }

  for my $k (qw(app extends option version documentation subcommand)) {
    my $name = $args{$k} // $k;
    next unless $name;
    $export{$k} = $name =~ /::/ ? $name : "$caller[0]\::$name";
  }

  no warnings 'redefine';    # need to allow redefine when loading a new app
  *{$export{app}}           = sub (&) { $self->app(@_) };
  *{$export{option}}        = sub     { $self->option(@_) };
  *{$export{version}}       = sub     { $self->version(@_) };
  *{$export{documentation}} = sub     { $self->documentation(@_) };
  *{$export{extends}}       = sub     { $self->extends(@_) };
  *{$export{subcommand}}    = sub     { $self->subcommand(@_) };
}

sub new {
  my $class = shift;
  my $self  = bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;

  $self->{options} ||= [];
  $self->{caller} or die 'Usage: $self->new({ caller => [...], ... })';

  return $self;
}

sub option {
  my $self          = shift;
  my $type          = shift or die 'Usage: option $type => ...';
  my $name          = shift or die 'Usage: option $type => $name => ...';
  my $documentation = shift or die 'Usage: option $type => $name => $documentation, ...';

  my %option = @_ % 2 ? (default => @_) : @_;
  $option{alias} = [$option{alias}] if $option{alias} and !ref $option{alias};
  $option{arg}   = do { local $_ = $name; s!_!-!g; $_ } unless $option{arg};
  push @{$self->options}, {%option, type => $type, name => $name, documentation => $documentation};

  return $self;
}

sub option_parser {
  my $self = shift;
  return do { $self->{option_parser} = shift; $self } if @_;
  return $self->{option_parser} ||= do {
    require Getopt::Long;
    Getopt::Long::Parser->new(config => [qw(no_auto_help no_auto_version pass_through)]);
  };
}

sub options { $_[0]->{options} }

sub print_help {
  my $self    = shift;
  my @options = @{$self->options};
  my $width   = 0;

  push @options, {name => ''};
  push @options, {name => 'help', documentation => 'Print this help text'};
  push @options, {name => 'man', documentation => 'Display manual for this application'} if $self->documentation;
  push @options, {name => 'version', documentation => 'Print application name and version'} if $self->version;
  push @options, {name => ''};

  $self->_print_synopsis;

OPTION:
  for my $option (@options) {
    my $length = length $option->{name};
    $width = $length if $width < $length;
  }

  print "Usage:\n";

  if (%{$self->{subcommands} || {}}) {
    my $subcmds = [sort { $a->{name} cmp $b->{name} } values %{$self->{subcommands}}];
    my ($width) = sort { $b <=> $a } map { length($_->{name}) } @$subcmds;
    print "\n    ", File::Basename::basename($0), " [command] [options]\n";
    print "\ncommands:\n";
    printf("    %-${width}s  %s\n", @{$_}{'name', 'desc'}) for @$subcmds;
    print "\noptions:\n";
  }

  $width += 2;

OPTION:
  for my $option (@options) {
    my $arg = $option->{arg} || $option->{name} or do { print "\n"; next OPTION };

    printf(
      " %s %-${width}s  %s\n",
      $option->{required} ? '*' : $option->{n_of} ? '+' : ' ',
      _option_with_dashes($arg),
      $option->{documentation},
    );
  }

  print "Notes:\n";
  print " * denotes a required option\n";
  print " + denotes an option that accepts multiple values\n";
  return $self;
}

sub print_version {
  my $self    = shift;
  my $version = $self->version or die 'Cannot print version without version()';

  unless ($version =~ m!^\d!) {
    local $@;
    eval "require $version; 1" or die "Could not load $version: $@";
    $version = $version->VERSION;
  }

  printf "%s version %s\n", File::Basename::basename($0), $version;
}

sub subcommand {
  my ($self, $name) = (shift, shift);
  return $self->{subcommand} unless @_;
  $self->{subcommands}{$name} = {name => $name, desc => $_[0], adaptation => $_[1]};
  return $self;
}

sub version {
  return $_[0]->{version} if @_ == 1;
  $_[0]->{version} = $_[1] or die 'Usage: version $module_name|$num;';
  return $_[0];
}

sub _app_new {
  my $self  = bless {}, shift;
  my $attrs = ref $_[0] eq 'HASH' ? shift : {@_};
  $self->$_($attrs->{$_}) for grep { $self->can($_) } keys %$attrs;
  return $self;
}

sub _app_run {
  my ($app, @extra) = @_;
  my $self = $app->_script;

  if (my @missing = grep { $_->{required} && !exists $app->{$_->{name}} } @{$self->options}) {
    my $missing = join ', ', map { _option_with_dashes($_->{arg}) } @missing;
    $self->print_help;
    die "Required attribute missing: $missing\n";
  }

  # get subcommand code - which should have a registered subroutine
  # or fallback to app {} block.
  my $code = $self->_subcommand_code($app) || $self->{app};
  return $app->$code(@extra);
}

sub _calculate_option_spec {
  my ($self, $option) = @_;
  my $spec = join '|', $option->{name}, $option->{arg};

  if (ref $option->{alias} eq 'ARRAY') {
    $spec .= join '|', '', @{$option->{alias}};
  }

  if    ($option->{type} =~ /^(?:bool|flag)/i) { $spec .= '!' }
  elsif ($option->{type} =~ /^inc/)            { $spec .= '+' }
  elsif ($option->{type} =~ /^str/)            { $spec .= '=s' }
  elsif ($option->{type} =~ /^int/i)           { $spec .= '=i' }
  elsif ($option->{type} =~ /^num/i)           { $spec .= '=f' }
  elsif ($option->{type} =~ /^file/)           { $spec .= '=s' }    # TODO
  elsif ($option->{type} =~ /^dir/)            { $spec .= '=s' }    # TODO
  else                                         { die 'Usage: option {bool|flag|inc|str|int|num|file|dir} ...' }

  # Let Types::Type handle the validation
  if (blessed $option->{isa}) {
    $spec =~ s!=\w$!=s!;
  }

  if (my $n_of = $option->{n_of}) {
    $spec .= $n_of eq '@' ? $n_of : "{$n_of}";
    $option->{default} ||= [];
  }

  return $spec;
}

sub _default_options {
  my $self = shift;
  my @default;

  push @default, 'help';
  push @default, 'man' if $self->documentation;
  push @default, 'version' if $self->version;

  return @default;
}

sub _documentation_class_handle {
  my ($self, $inc_entry, $inc_key) = @_;

  # check for FatPacked::140677333829776=HASH entry in %INC
  # You can also insert hooks into the import facility by putting Perl code
  # directly into the @INC array. There are three forms of hooks: subroutine
  # references, array references, and blessed objects.
  return $inc_entry->INC($inc_key) if ((ref($inc_entry) || 'CODE') !~ m/(CODE|ARRAY)/);
  open my $fh, '<', $inc_entry or die "Failed to read synopsis from $inc_entry: $@";
  return $fh;
}

sub _exit {
  my ($self, $reason) = @_;
  exit 0 unless ($reason =~ /^\d+$/);    # may change without warning...
  exit $reason;
}

sub _generate_attribute_accessor {
  my ($self, $option) = @_;
  my $default = ref $option->{default} eq 'CODE' ? $option->{default} : sub { $option->{default} };
  my $isa     = $option->{isa};
  my $name    = $option->{name};

  if (blessed $isa and $isa->can('check')) {
    my $assert_method = $isa->has_coercion ? 'assert_coerce'    : 'assert_return';
    my $prefix        = $isa->has_coercion ? 'Could not coerce' : 'Failed check for';
    return sub {
      @_ == 1 && return exists $_[0]{$name} ? $_[0]{$name} : ($_[0]{$name} = $_[0]->$default);
      eval { $_[0]{$name} = $isa->$assert_method($_[1]); 1 } or do {
        my $human = $INSTANTIATING ? _option_with_dashes($option->{arg}) : qq("$name");
        die qq($prefix $human: $@);
      };
    };
  }
  elsif (my $class = _load_class($isa)) {
    return sub {
      @_ == 1 && exists $_[0]{$name} && return $_[0]{$name};
      my $val = @_ > 1 ? $_[1] : $_[0]->$default;
      $_[0]{$name} = ref $val eq 'ARRAY' ? [map { $class->new($_) } @$val] : defined($val) ? $class->new($val) : undef;
    };
  }
  else {
    return sub {
      @_ == 1 && return exists $_[0]{$name} ? $_[0]{$name} : ($_[0]{$name} = $_[0]->$default);
      $_[0]{$name} = $_[1];
    };
  }
}

sub _generate_application_class {
  my ($self, $code) = @_;
  my $application_class = $self->{caller}[1];
  my $extends           = $self->{extends} || [];

  $ANON++;
  $application_class =~ s!\W!_!g;
  $application_class = join '::', ref($self), "__ANON__${ANON}__", $application_class;
  local $@;
  eval qq[package $application_class; use base qw(@$extends); 1] or die "Failed to generate application class: $@";

  _sub("$application_class\::new"     => \&_app_new) unless grep { $_->can('new') } @$extends;
  _sub("$application_class\::run"     => \&_app_run);
  _sub("$application_class\::_script" => sub {$self});

  for ('app', $self->{caller}[0]) {
    my $ns = do { no strict 'refs'; \%{"$_\::"} };

    for my $name (keys %$ns) {
      $self->{skip_subs}{$name} and next;
      my $code = eval { ref $ns->{$name} eq 'CODE' ? $ns->{$name} : *{$ns->{$name}}{CODE} } or next;
      my $fqn  = join '::', $application_class, $name;
      _sub($fqn => $code);
      delete $ns->{$name};    # may be a bit too destructive?
    }
  }

  my $meta = $application_class->meta if $application_class->isa('Moose::Object') and $application_class->can('meta');

  for my $option (@{$self->options}) {
    my $name = $option->{name};
    if ($meta) {
      my %attr_options = (is => 'rw', predicate => 1, required => $option->{required});
      $attr_options{default} = $option->{default} if $option->{default};
      $attr_options{isa}     = $option->{isa}     if $option->{isa};
      $meta->add_attribute($name => \%attr_options) unless $meta->find_attribute_by_name($name);
    }
    else {
      my $accessor = join '::', $application_class, $name;
      _sub($accessor => $self->_generate_attribute_accessor($option));
      my $predicator = join '::', $application_class, join '_', has => $name;
      _sub($predicator => sub { !!defined $_[0]->{$name} });
    }
  }

  return $application_class;
}

sub _load_class {
  my $class = shift or return undef;
  return $class if $class->can('new');
  local $@;
  return eval "require $class; 1" ? $class : "";
}

sub _option_with_dashes { length($_[0]) > 1 ? "--$_[0]" : "-$_[0]" }

sub _print_synopsis {
  my $self          = shift;
  my $documentation = $self->documentation or return;
  my ($print, $classpath);

  unless (-e $documentation) {
    local $@;
    eval "require $documentation; 1" or die "Could not load $documentation: $@";
    $documentation =~ s!::!/!g;
    $documentation = $INC{$classpath = "$documentation.pm"};
  }

  my $FH = $self->_documentation_class_handle($documentation, $classpath);

  while (<$FH>) {
    last  if $print and /^=(?:cut|head1)/;
    print if $print;
    $print = 1 if /^=head1 SYNOPSIS/;
  }
}

sub _sub {
  my ($fqn, $code) = @_;
  no strict 'refs';
  return if *$fqn{CODE};
  *$fqn = SUB_NAME_IS_AVAILABLE ? Sub::Name::subname($fqn, $code) : $code;
}

sub _subcommand_activate {
  my ($self, $name) = @_;
  return undef unless $name and $name =~ /^\w+/;
  return undef unless $self->{subcommands}{$name};
  $self->{subcommand} = $name;
  {
    no warnings 'redefine';
    local *Applify::app = sub {
      Carp::confess("Looks like you have a typo in your script! Cannot have app{} inside a subcommand options block.");
    };
    $self->{subcommands}{$name}{adaptation}->($self);
  }
  return 1;
}

sub _subcommand_code {
  my ($self, $app, $name) = (shift, shift);
  return undef unless $name = $self->subcommand;
  return $app->can("${SUBCMD_PREFIX}_${name}");
}

1;

=encoding utf8

=head1 NAME

Applify - Write object oriented scripts with ease

=head1 VERSION

0.17

=head1 DESCRIPTION

This module should keep all the noise away and let you write scripts very
easily. These scripts can even be unit tested even though they are defined
directly in the script file and not in a module.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use Applify;

  option file => input_file => 'File to read from';
  option dir => output_dir => 'Directory to write files to';
  option flag => dry_run => 'Use --no-dry-run to actually do something', 1;

  documentation __FILE__;
  version 1.23;

  sub generate_exit_value {
    return int rand 100;
  }

  # app {...}; must be the last statement in the script
  app {
    my ($app, @extra) = @_;
    my $exit_value = 0;

    print "Extra arguments: @extra\n" if(@extra);
    print "Will read from: ", $app->input_file, "\n";
    print "Will write files to: ", $app->output_dir, "\n";

    if($app->dry_run) {
      die 'Will not run script';
    }

    return $app->generate_exit_value;
  };

=head1 APPLICATION CLASS

This module will generate an application class, which C<$app> inside the
L</app> block is an instance of. The class will have these methods:

=over 2

=item * C<new()>

An object constructor. This method will not be auto generated if any of
the classes given to L</extends> has the method C<new()>.

=item * C<run()>

This method is basically the code block given to L</app>.

=item * Other methods

Other methods defined in the script file will be accesible from C<$app>
inside C<app{}>.

=item * C<_script()>

This is an accessor which return the L<Applify> object which
is refered to as C<$script> in this documentation.

NOTE: This accessor starts with an underscore to prevent conflicts
with L</options>.

=item * Other accessors

Any L</option> (application option) will be available as an accessor on the
application object.

=back

=head1 EXPORTED FUNCTIONS

=head2 option

  option $type => $name => $documentation;
  option $type => $name => $documentation, $default;
  option $type => $name => $documentation, $default, @args;
  option $type => $name => $documentation, @args;

This function is used to define options which can be given to this
application. See L</SYNOPSIS> for example code. This function can also be
called as a method on C<$script>. Additionally, similar to
L<Moose attributes|Moose::Manual::Attributes#Predicate-and-clearer-methods>, a
C<has_$name> method will be generated, which can be called on C<$app> to
determine if the L</option> has been set, either by a user or from the
C<$default>.

=over 2

=item * C<$type>

Used to define value types for this input. Can be:

  | $type | Example             | Attribute value |
  |-------|---------------------|-----------------|
  | bool  | --foo, --no-foo     | foo=1, foo=0    |
  | flag  | --foo, --no-foo     | foo=1, foo=0    |
  | inc   | --verbose --verbose | verbose=2       |
  | str   | --name batwoman     | name=batwoman   |
  | int   | --answer 42         | answer=42       |
  | num   | --pie 3.14          | pie=3.14        |

=item * C<$name>

The name of an application option. This name will also be used as accessor name
inside the application. Example:

  # define an application option: 
  option file => some_file => '...';

  # call the application from command line:
  > myapp.pl --some-file /foo/bar

  # run the application code:
  app {
    my $app = shift;
    print $app->some_file # prints "/foo/bar"
    return 0;
  };

=item * C<$documentation>

Used as description text when printing the usage text.

=item * C<$default>

Either a plain value or a code ref that can be used to generate a value.

  option str => passwd => "Password file", "/etc/passwd";
  option str => passwd => "Password file", sub { "/etc/passwd" };

=item * C<@args>

=over 2

=item * C<alias>

Used to define an alias for the option. Example:

  option inc => verbose => "Output debug information", alias => "v";

=item * C<required>

The script will not start if a required field is omitted.

=item * C<n_of>

Allow the option to hold a list of values. Examples: "@", "4", "1,3".
See L<Getopt::Long/Options-with-multiple-values> for details.

=item * C<isa>

Can be used to either specify a class that the value should be instantiated
as, or a L<Type::Tiny> object that will be used for coercion and/or type
validation.

Example using a class:

  option file => output => "output file", isa => "Mojo::File";

The C<output()> attribute will then later return an object of L<Mojo::File>,
instead of just a plain string.

Example using L<Type::Tiny>:

  use Types::Standard "Int";
  option num => age => "Your age", isa => Int;

=item * Other

Any other L<Moose> attribute argument may/will be supported in
future release.

=back

=back

=head2 documentation

  documentation __FILE__; # current file
  documentation '/path/to/file';
  documentation 'Some::Module';

Specifies where to retrieve documentaion from when giving the C<--man> option
to your script.

=head2 version

  version 'Some::Module';
  version $num;

Specifies where to retrieve the version number from when giving the
C<--version> option to your script.

=head2 extends

  extends @classes;

Specify which classes this application should inherit from. These
classes can be L<Moose> based.

=head2 subcommand

  subcommand list => 'provide a listing objects' => sub {
    option flag => long => 'long listing';
    option flag => recursive => 'recursively list objects';
  };

  subcommand create => 'create a new object' => sub {
    option str => name => 'name of new object', required => 1;
    option str => description => 'description for the object', required => 1;
  };

  sub command_create {
    my ($app, @extra) = @_;
    ## do creating
    return 0;
  }

  sub command_list {
    my ($app, @extra) = @_;
    ## do listing
    return 0;
  }

  app {
    my ($app, @extra) = @_;
    ## fallback when no command given.
    $app->_script->print_help;
    return 0;
  };

This function allows for creating multiple related sub commands within the same
script in a similar fashion to C<git>. The L</option>, L</extends> and
L</documentation> exported functions may sensibly be called within the
subroutine. Calling the function with no arguments will return the running
subcommand, i.e. a valid C<$ARGV[0]>. Non valid values for the subcommand given
on the command line will result in the help being displayed.

=head2 app

  app CODE;

This function will define the code block which is called when the application
is started. See L</SYNOPSIS> for example code. This function can also be
called as a method on C<$script>.

IMPORTANT: This function must be the last function called in the script file
for unit tests to work. Reason for this is that this function runs the
application in void context (started from command line), but returns the
application object in list/scalar context (from L<perlfunc/do>).

=head1 ATTRIBUTES

=head2 option_parser

  $script = $script->option_parser(Getopt::Long::Parser->new);
  $parser = $script->option_parser;

You can specify your own option parser if you have special needs. The default
is:

  Getopt::Long::Parser->new(config => [qw(no_auto_help no_auto_version pass_through)]);

=head2 options

  $array_ref = $script->options;

Holds the application options given to L</option>.

=head1 METHODS

=head2 new

  $script = Applify->new({options => $array_ref, ...});

Object constructor. Creates a new object representing the script meta
information.

=head2 print_help

Will print L</options> to selected filehandle (STDOUT by default) in
a normalized matter. Example:

  Usage:
     --foo      Foo does this and that
   * --bar      Bar does something else

     --help     Print this help text
     --man      Display manual for this application
     --version  Print application name and version

=head2 print_version

Will print L</version> to selected filehandle (STDOUT by default) in
a normalized matter. Example:

  some-script.pl version 1.23

=head2 import

Will export the functions listed under L</EXPORTED FUNCTIONS>. The functions
will act on a L<Applify> object created by this method.

=head1 COPYRIGHT & LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Roy Storey - C<kiwiroy@cpan.org>

=cut
