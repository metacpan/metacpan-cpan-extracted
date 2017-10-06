package Applify;
use strict;
use warnings;
use Carp           ();
use File::Basename ();

use constant SUB_NAME_IS_AVAILABLE => $INC{'App/FatPacker/Trace.pm'}
  ? 0    # this will be true when running under "fatpack"
  : eval 'use Sub::Name; 1' ? 1 : 0;

our $VERSION = '0.14';
our $PERLDOC       = 'perldoc';
our $SUBCMD_PREFIX = "command";
my $ANON = 1;

sub app {
  my $self   = shift;
  my $code   = $self->{app} ||= shift;
  my $parser = $self->_option_parser;
  my (%options, @options_spec, $application_class, $app);

  # has to be run before calculating option spec.
  # cannot do ->can() as application_class isn't created yet.
  if ($self->_subcommand_activate($ARGV[0])) { shift @ARGV; }
  for my $option (@{$self->{options}}) {
    my $switch = $self->_attr_to_option($option->{name});
    push @options_spec, $self->_calculate_option_spec($option);
    $options{$switch} = $option->{default}     if exists $option->{default};
    $options{$switch} = [@{$options{$switch}}] if ref($options{$switch}) eq 'ARRAY';
  }

  unless ($parser->getoptions(\%options, @options_spec, $self->_default_options)) {
    $self->_exit(1);
  }

  if ($options{help}) {
    $self->print_help;
    $self->_exit('help');
  }
  elsif ($options{man}) {
    system $PERLDOC => $self->documentation;
    $self->_exit($? >> 8);
  }
  elsif ($options{version}) {
    $self->print_version;
    $self->_exit('version');
  }

  $application_class = $self->{application_class} ||= $self->_generate_application_class($code);
  $app = $application_class->new(
    {map { my $k = $self->_option_to_attr($_); $k => $self->_upgrade($k, $options{$_}) } keys %options});

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
  my ($class, $args) = @_;
  my $self = bless $args, $class;

  $self->{options} ||= [];
  $self->{caller} or die 'Usage: $self->new({ caller => [...], ... })';

  return $self;
}

sub option {
  my $self          = shift;
  my $type          = shift or die 'Usage: option $type => ...';
  my $name          = shift or die 'Usage: option $type => $name => ...';
  my $documentation = shift or die 'Usage: option $type => $name => $documentation, ...';
  my ($default, %args);

  if (@_ % 2) {
    $default = shift;
    %args    = @_;
  }
  else {
    %args = @_;
  }

  if ($args{alias} and !ref $args{alias}) {
    $args{alias} = [$args{alias}];
  }

  push @{$self->{options}}, {default => $default, %args, type => $type, name => $name, documentation => $documentation};

  return $self;
}

sub options { $_[0]->{options} }

sub print_help {
  my $self    = shift;
  my @options = @{$self->{options}};
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

OPTION:
  for my $option (@options) {
    my $name = $self->_attr_to_option($option->{name}) or do { print "\n"; next OPTION };

    printf(
      " %s %2s%-${width}s  %s\n",
      $option->{required} ? '*'  : ' ',
      length($name) > 1   ? '--' : '-',
      $name, $option->{documentation},
    );
  }

  return $self;
}

sub print_version {
  my $self = shift;
  my $version = $self->version or die 'Cannot print version without version()';

  unless ($version =~ m!^\d!) {
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

sub _attr_to_option {
  local $_ = $_[1] or return;
  s!_!-!g;
  $_;
}

sub _calculate_option_spec {
  my ($self, $option) = @_;
  my $spec = $self->_attr_to_option($option->{name});

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

  if (my $n_of = $option->{n_of}) {
    $spec .= $n_of eq '@' ? $n_of : "{$n_of}";
    $option->{default}
      and ref $option->{default} ne 'ARRAY'
      and die 'Usage option ... default => [Need to be an array ref]';
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

sub _exit {
  my ($self, $reason) = @_;
  exit 0 unless ($reason =~ /^\d+$/);    # may change without warning...
  exit $reason;
}

sub _generate_application_class {
  my ($self, $code) = @_;
  my $application_class = $self->{caller}[1];
  my $extends = $self->{extends} || [];
  my ($meta, @required);

  $application_class =~ s!\W!_!g;
  $application_class = join '::', ref($self), "__ANON__${ANON}__", $application_class;
  $ANON++;

  eval qq[
    package $application_class;
    use base qw(@$extends);
    1;
  ] or die "Failed to generate application class: $@";

  {
    no strict 'refs';
    _sub("$application_class\::new" => sub { my $class = shift; bless shift, $class })
      unless grep { $_->can('new') } @$extends;
    _sub("$application_class\::_script" => sub {$self});
    _sub(
      "$application_class\::run" => sub {
        my ($app, @extra) = @_;

        if (@required = grep { not defined $app->{$_} } @required) {
          my $required = join ', ', map { '--' . $self->_attr_to_option($_) } @required;
          $app->_script->print_help;
          die "Required attribute missing: $required\n";
        }

        # get subcommand code - which should have a registered subroutine
        # or fallback to app {} block.
        $code = $app->_script->_subcommand_code($app) || $code;
        return $app->$code(@extra);
      }
    );

    for ('app', $self->{caller}[0]) {
      my $ns = \%{"$_\::"};

      for my $name (keys %$ns) {
        $self->{skip_subs}{$name} and next;
        my $code = eval { ref $ns->{$name} eq 'CODE' ? $ns->{$name} : *{$ns->{$name}}{CODE} } or next;
        my $fqn = join '::', $application_class, $name;
        _sub($fqn => $code);
        delete $ns->{$name};    # may be a bit too destructive?
      }
    }

    $meta = $application_class->meta if $application_class->isa('Moose::Object') and $application_class->can('meta');

    for my $option (@{$self->{options}}) {
      my $name = $option->{name};
      my $fqn = join '::', $application_class, $name;
      if ($meta) {
        $meta->add_attribute($name => {is => 'rw', default => $option->{default}});
      }
      else {
        _sub($fqn => sub { @_ == 2 and $_[0]->{$name} = $_[1]; $_[0]->{$name} });
      }
      push @required, $name if $option->{required};
    }
  }

  return $application_class;
}

sub _load_class {
  my $class = shift or return undef;
  return $class if $class->can('new');
  return eval "require $class; 1" ? $class : "";
}

sub _option_parser {
  $_[0]->{_option_parser} ||= do {
    require Getopt::Long;
    Getopt::Long::Parser->new(config => [qw(no_auto_help no_auto_version pass_through)]);
  };
}

sub _option_to_attr {
  local $_ = $_[1] or return;
  s!-!_!g;
  $_;
}

sub _print_synopsis {
  my $self = shift;
  my $documentation = $self->documentation or return;
  my $print;

  unless (-e $documentation) {
    eval "use $documentation; 1" or die "Could not load $documentation: $@";
    $documentation =~ s!::!/!g;
    $documentation = $INC{"$documentation.pm"};
  }

  open my $FH, '<', $documentation or die "Failed to read synopsis from $documentation: $@";

  while (<$FH>) {
    last if $print and /^=(?:cut|head1)/;
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
      Carp::confess(
        "Looks like you have a typo in your script! Cannot have app{} inside a subcommand options block.");
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

sub _upgrade {
  my ($self, $name, $input) = @_;
  return $input unless defined $input;

  my ($option) = grep { $_->{name} eq $name } @{$self->{options}};
  return $input unless my $class = _load_class($option->{isa});
  return ref $input eq 'ARRAY' ? [map { $class->new($_) } @$input] : $class->new($input);
}

1;

=encoding utf8

=head1 NAME

Applify - Write object oriented scripts with ease

=head1 VERSION

0.14

=head1 DESCRIPTION

This module should keep all the noise away and let you write scripts
very easily. These scripts can even be unittested even though they
are define directly in the script file and not in a module.

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

  app {
    my($self, @extra) = @_;
    my $exit_value = 0;

    print "Extra arguments: @extra\n" if(@extra);
    print "Will read from: ", $self->input_file, "\n";
    print "Will write files to: ", $self->output_dir, "\n";

    if($self->dry_run) {
      die 'Will not run script';
    }

    return $self->generate_exit_value;
  };

=head1 APPLICATION CLASS

This module will generate an application class, which C<$self> inside the
L</app> block refere to. This class will have:

=over 4

=item * new()

An object constructor. This method will not be auto generated if any of
the classes given to L</extends> has the method C<new()>.

=item * run()

This method is basically the code block given to L</app>.

=item * Other methods

Other methods defined in the script file will be accesible from C<$self>
inside C<app{}>.

=item * _script()

This is an accessor which return the L<Applify> object which
is refered to as C<$self> in this documentation.

NOTE: This accessor starts with an underscore to prevent conflicts
with L</options>.

=item * Other accessors

Any L</option> (application switch) will be available as an accessor on the
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
called as a method on C<$self>.

=over 4

=item * $type

Used to define value types for this input.

=over 4

=item bool, flag

=item inc

=item str

=item int

=item num

=item file (TODO)

=item dir (TODO)

=back

=item * $name

The name of an application switch. This name will also be used as
accessor name inside the application. Example:

  # define an application switch:
  option file => some_file => '...';

  # call the application from command line:
  > myapp.pl --some-file /foo/bar

  # run the application code:
  app {
    my $self = shift;
    print $self->some_file # prints "/foo/bar"
    return 0;
  };

=item * C<$documentation>

Used as description text when printing the usage text.

=item * C<@args>

=over 4

=item * C<required>

The script will not start if a required field is omitted.

=item * C<n_of>

Allow the option to hold a list of values. Examples: "@", "4", "1,3".
See L<Getopt::Long/Options-with-multiple-values> for details.

=item * C<isa>

Specify the class an option should be instantiated as. Example:

  option file => output => "output file", isa => "Mojo::File";

The C<output()> attribute will then later return an object of L<Mojo::File>,
instead of just a plain string.

=item * Other

Any other L<Moose> attribute argument may/will be supported in
future release.

=back

=back

=head2 documentation

  documentation __FILE__; # current file
  documentation '/path/to/file';
  documentation 'Some::Module';

Specifies where to retrieve documentaion from when giving the C<--man>
switch to your script.

=head2 version

  version 'Some::Module';
  version $num;

Specifies where to retrieve the version number from when giving the
C<--version> switch to your script.

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
    my ($self, @extra) = @_;
    ## do creating
    return 0;
  }

  sub command_list {
    my ($self, @extra) = @_;
    ## do listing
    return 0;
  }

  app {
    my ($self, @extra) = @_;
    ## fallback when no command given.
    $self->_script->print_help;
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
called as a method on C<$self>.

IMPORTANT: This function must be the last function called in the script file
for unittests to work. Reason for this is that this function runs the
application in void context (started from command line), but returns the
application object in list/scalar context (from L<perlfunc/do>).

=head1 ATTRIBUTES

=head2 options

  $array_ref = $self->options;

Holds the application options given to L</option>.

=head1 METHODS

=head2 new

  $self = $class->new({ options => $array_ref, ... });

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
