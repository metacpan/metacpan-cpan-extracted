#!/usr/bin/perl

=head1 NAME

App::Getconf - singleton-like config store for command-line applications

=head1 SYNOPSIS

  # main.pl

  use App::Getconf qw{ :schema };
  use YAML qw{ LoadFile };

  App::Getconf->option_schema(
    help    => opt { type => 'flag',
                     help => "this message" },
    version => opt { type => 'flag',
                     help => "print version information" },
    verbose => opt { type => 'bool',
                     help => "be verbose" },
    session => schema(
      timeout => opt { type => 'int',    value => 50 },
      path    => opt { type => 'string', value => '/' },
    ),
    # ...
  );

  App::Getconf->cmdline(\@ARGV);
  App::Getconf->options(LoadFile('/etc/myapp.yaml'));

  if (App::Getconf->getopt->help) {
    print App::Getconf->help_message();
    exit 0;
  }

  # real code...

  #-------------------------------------------------
  # My/Module.pm

  package My::Module;

  use App::Getconf;

  sub do_something {
    my ($self, %args) = @_;

    my $opts = App::Getconf->getopt;

    if ($opts->verbose) {
      print "Entering function do_something()\n";
    }

    # ...
  }

=head1 DESCRIPTION

This module is yet another command line options parser. But not only.
Actually, it's an option container. It's a response to a question: after
parsing options (from command line and from config file), how do I pass them
down the function call stack?

There are two classic approaches. One utilizes global variables. This is not
that convenient, because introduces some names treated in special way (not
defined inside the current function). The other requires passing option
container as an argument to each and every function (you can't always tell in
advance that the function will never use the options on one hand, and API
changes are tedious on the other).

App::Getconf tries a different way, which is not entirely new: the inspiration
for this module was L<Log::Log4perl(3)>, which is Perl port of log4j Java
library. The idea is simple: you need a value accessible similarly to a global
variable, but declared locally.

=head1 ARCHITECTURE

App::Getconf consists of three different types of objects: option
containers, option views and option schema nodes.

Option container (App::Getconf instance) stores all the options that were set,
either from command line or from multi-level hash (e.g. loaded config file).

Option container needs to be initialized with option schema: list of allowed
options, along with their types (int, float, string, flag and so on). Such
schema is composed of nodes created with C<opt()> function or derivatives.

Option view (L<App::Getconf::View(3)> instance) is an interface to options
list. When option is requested, view does a "lookup" to find appropriate
option. For example, view C<$v> for I<proto.client> subsystem was created.
When C<< $v->get('timeout') >> was issued, the view will return value of the
first existing option: I<proto.client.timeout>, I<proto.timeout> or
I<timeout>. Of course there's also a possibility to omit this lookup.

App::Getconf creates a default option container. This default container is
used every time when semi-static method (see L</"Semi-Static Methods">
section) is called as static one. This is how App::Getconf provides a way of
accessing options globally. However, you are not limited to this default
container. You may create your own containers with their own option schema. Of
course you will need to pass them down the call stack.

=head2 Options Lifecycle

Option container needs a schema to tell which options are legal and which are
not. Defining schema is basically the first thing to do. Schema can also
contain initial values for some options.

Next go options defined in command line and in config file. Option container
can parse command line on its own, it just needs an array of arguments.

Two above steps are only to be done once, at the application start, possibly
as early as possible. Changing option values, however, is planned in the
future to be supported after initialization process, at run-time.

From now on, C<getopt()> method may be used in any part of application.

=head2 Schema Definition

Schema is simply a hashref that contains options. Each value is a node (actual
option or alias) or a sub-schema.

Full name of an option from sub-schema is I<$schema.$option>, where
C<${schema}> is the key, under which sub-schema was stored. Command line
option that sets such option is I<--$schema-$option>.

Schemas stored under greater depth are analogous.

Example of schema:

  help    => opt { type => 'flag', ... },
  version => opt { type => 'flag', ... },
  verbose => opt { type => 'bool', ... },
  session => {
    timeout => opt { type => 'int',    ... },
    path    => opt { type => 'string', ... },
    ''      => opt { type => 'string', ... },
  },
  # ...

This schema defines options I<help>, I<version>, I<verbose>,
I<session.timeout>, I<session.path> and just plain I<session>. The last one is
example of how to define option of the same name as sub-schema.

End-user can set these options using command line options, accordingly:
I<--help>, I<--version>, I<--verbose>/I<--no-verbose>,
I<--session-timeout=###>, I<--session-path=XXX> and I<--session=XXX>.

Basic way of creating node is using C<opt()> function, but there are few
shorthands, like C<opt_int()>, C<opt_flag()> and others. See
L</"Functions Defining Schema"> section for details.

Schema is also used, beside validating option correctness, for generating
message printed typically after issuing I<--help> option. Only options having
C<help> field are included in this message. Other options still may be set in
command line, but are not exposed to the user. They are meant mainly to be
specified with configuration file or with other means.

Order of options in autogenerated help message is lexicographic order. You may
provide the order by changing Perl's built-in anonymous hashref C<{}> to call
to function C<schema()>. Example:

  # ...
  session => schema(
    timeout => opt { type => 'int',    ... },
    path    => opt { type => 'string', ... },
    ''      => opt { type => 'string', ... },
  ),
  # ...

You may freely mix hashrefs and C<schema()> calls, at the same or different
nesting levels.

=cut

package App::Getconf;

#-----------------------------------------------------------------------------

use warnings;
use strict;

use base qw{Exporter};
use Carp;
use App::Getconf::View;
use App::Getconf::Node;
use Tie::IxHash;

our $VERSION = '0.20.04';

our @EXPORT_OK = qw(
  schema
  opt        opt_alias
  opt_flag   opt_bool
  opt_int    opt_float
  opt_string opt_path   opt_hostname
  opt_re     opt_sub    opt_enum
);

our %EXPORT_TAGS = (
  schema => [ 'schema', grep { /^opt/ } @EXPORT_OK ],
);

#-----------------------------------------------------------------------------

my $static = new App::Getconf();

#-----------------------------------------------------------------------------

=head1 MODULE API

Following methods are available:

=over

=cut

#-----------------------------------------------------------------------------

=item C<new(%opts)>

Constructor.

No options are used at the moment.

B<NOTE>: You don't need to use the constructor. You may (and typically would)
want to use App::Getconf's default container.

=cut

sub new {
  my ($class, %opts) = @_;

  my $self = bless {
    aliases => undef,
    options => undef,
    args    => undef,
    help    => {
      message => undef,
      order   => undef,
    },
    # each getopt() will return 
    getopt_cache  => {},
  }, $class;

  return $self;
}

#-----------------------------------------------------------------------------

=back

=head2 Semi-Static Methods

Methods from this section can be called as instance methods, when you have
created own instance of C<App::Getconf>, or as static methods, when they
operate on default instance of C<App::Getconf>. Typically you would use the
latter strategy, as passing option container down the function call stack is
somewhat troublesome.

=over

=cut

#-----------------------------------------------------------------------------

=item C<option_schema($schema_description)>

=item C<< option_schema(key => value, key => value, ...) >>

Set expected schema for the options. Schema may be either a hashref (Perl's
ordinary or created using C<schema()> function) or a list of key/value pairs.
The latter form has the same result as passing the list to C<schema()> first,
i.e., the options order will be preserved.

=cut

sub option_schema {
  my ($self, @args) = @_;

  my $schema = (@args == 1) ? $args[0] : schema(@args);;

  $self = $static unless ref $self; # static call or non-static?

  my @schema = _flatten($schema, "");
  $self->{options} = {};
  $self->{aliases} = {};
  $self->{help}{order} = [];
  for my $opt (@schema) {
    if ($opt->{opt}->alias) {
      # alias option

      $self->{aliases}{ $opt->{name} } = $opt->{opt};

    } else {
      # normal (non-alias) option

      $self->{options}{ $opt->{name} } = $opt->{opt};
      # remember the order of messages
      if ($opt->{opt}->help) {
        push @{ $self->{help}{order} }, $opt->{name};
      }
    }
  }

  # NOTE: this can't be moved to inside the previous loop, because there could
  # be an alias processed earlier than the option it points to
  for my $name (sort keys %{ $self->{aliases} }) {
    my $dest = $self->{aliases}{$name}->alias;

    # option can't be an alias and non-alias at the same time
    if ($self->{aliases}{$dest}) {
      croak "Alias \"$name\" points to another alias called \"$dest\"";
    } elsif (not $self->{options}{$dest}) {
      croak "Alias \"$name\" points to a non-existent option \"$dest\"";
    }
  }
}

=begin Internal

=pod _flatten() {{{

=item C<_flatten($root, $path)>

Function flattens schema hashref tree to a flat hash, where option names are
separated by C<.>.

C<$root> is a root of schema hashref tree to convert (recursively).
C<$path> is used to keep path so far in recursive call. It should be an empty string initially.

Returned value is a hash with two fields: I<name> contains full option path,
and I<opt> is actual L<App::Getconf::Node(3)> object.

=cut

sub _flatten {
  my ($root, $path) = @_;

  my @opts = eval { tied(%$root)->isa("Tie::IxHash") } ?
               keys %$root :
               sort keys %$root;
  my @result;
  for my $o (@opts) {
    if (eval { $root->{$o}->isa("App::Getconf::Node") }) {
      my $name = "$path.$o";
      $name =~ s/^\.|\.$//g;
      push @result, { name => $name, opt => $root->{$o} };
    } elsif (ref $root->{$o} eq 'HASH') {
      # XXX: don't try $root->{$o}{""}, it will be collected in the recursive
      # _flatten() call (note that this may leave trailing period for this
      # option)
      push @result, _flatten($root->{$o}, "$path.$o");
    }
  }
  return @result;
}

=end Internal

=pod }}}

=cut

#-----------------------------------------------------------------------------

=item C<help_message(%options)>

Return message printed when I<--help> (or similar) option was passed. Message
will be C<\n>-terminated.

Typical usage:

  if (App::Getconf->getopt->help) {
    print App::Getconf->help_message(
      screen   => 130,
      synopsis => "%0 [ options ] file ...",
    );
    exit 0;
  }

Supported options:

=over

=item C<screen> (default: 80)

Screen width, in columns.

=item C<arg0> (default: C<$0> with path stripped)

Name of the program. Usually C<$0> or a derivative.

=item C<synopsis> (default: C<%0 [ options ... ]>)

Short call summary. Any occurrence of C<%0> will be replaced with content of
C<arg0> option.

Synopsis may be also a multiline string or an array of single-line strings.

=item C<header>

=item C<description>

=item C<footer>

Three additional text fields: before synopsis, after synopsis but before
options list, after options list.

Text will be re-wrapped to fit on a terminal of C<screen> width. Empty lines
will be treated as paragraph separators, but single newline characters will
not be preserved.

Any occurrence of C<%0> will be replaced with content of C<arg0> option.

=item C<option_indent> (default: 2)

=item C<description_indent> (default: 6)

Indenting for option header ("--option" with parameter specification, if any)
and for option description.

=back

=cut

sub help_message {
  my ($self, %opts) = @_;

  $self = $static unless ref $self; # static call or non-static?

  $opts{screen}   ||= 80;
  $opts{arg0}     ||= (split m[/], $0)[-1];
  $opts{synopsis} ||= "%0 [ options ... ]";

  $opts{option_indent}      ||= 2;
  $opts{description_indent} ||= 6;

  # $opts{header}      ||= undef;
  # $opts{description} ||= undef;
  # $opts{footer}      ||= undef;

  my $help = "";
  my $line;
  my %format_markers;

  #---------------------------------------------------------
  # header {{{

  if ($opts{header}) {
    $line = _reformat($opts{header}, $opts{screen});
    $line =~ s/%0/$opts{arg0}/g;

    $help .= $line;
    $help .= "\n"; # additional empty line
  }

  # }}}
  #---------------------------------------------------------
  # synopsis {{{

  if (ref $opts{synopsis} eq 'ARRAY') {
    $line = join "\n", @{ $opts{synopsis} };
  } else {
    $line = $opts{synopsis};
  }
  $line =~ s/%0/$opts{arg0}/g;

  $line =~ s/\s+$//; # strip leading spaces

  if ($line =~ /\n./) {
    # multiline synopsis
    $format_markers{multiline_synopsis} = 1;

    $line =~ s/^[ \t]*/  /mg; # uniform indentation
    $help .= sprintf "Usage:\n%s\n", $line;

  } else {
    # single line synopsis

    $line =~ s/^\s+//; # strip leading spaces
    if (length($line) < $opts{screen} - 1 - length("Usage: ")) {
      $help .= sprintf "Usage: %s\n", $line;
    } else {
      $format_markers{multiline_synopsis} = 1;
      $help .= sprintf "Usage:\n%s\n", $line;
    }

  }

  # }}}
  #---------------------------------------------------------
  # description (below synopsis) {{{

  if ($opts{description}) {
    $line = _reformat($opts{description}, $opts{screen});
    $line =~ s/%0/$opts{arg0}/g;

    $help .= "\n";
    $help .= $line;

    $format_markers{multiline_synopsis} = 1;
  }

  # }}}
  #---------------------------------------------------------
  # options {{{

  if ($self->{help}{order} && @{ $self->{help}{order} }) {
    $line = "Options available:\n";

    for my $opt (@{ $self->{help}{order} }) {
      my $dash_opt = (length $opt > 1) ? "--$opt" : "-$opt";
      $dash_opt =~ tr/./-/;

      my $node = $self->option_node($opt);

      my $init_val = "";
      if ($node->has_value) {
        $init_val = $node->get;
        $init_val = "<undef>" if not defined $init_val;
        $init_val = " (initially: $init_val)";
      }

      # option header (indented "--option") {{{
      # TODO: aliases
      if ($node->type eq 'flag') {
        $line .= sprintf "%*s%s\n", $opts{option_indent}, "", $dash_opt;
      } elsif ($node->type eq 'bool') {
        my $neg_dash_opt = "--no-$opt";
        $neg_dash_opt =~ tr/./-/;
        $line .= sprintf "%*s%s, %s\n",
                         $opts{option_indent}, "",
                         ($node->get ?
                           ($neg_dash_opt, $dash_opt) :
                           ($dash_opt, $neg_dash_opt));
      } elsif ($node->has_default) {
        my $type = $node->type;
        if ($node->enum) {
          $type = join "|", @{ $node->enum };
        }
        $line .= sprintf "%*s%s, %s=%s%s\n",
                         $opts{option_indent}, "",
                         $dash_opt,
                         $dash_opt, $type,
                         $init_val;
      } else {
        my $type = $node->type;
        if ($node->enum) {
          $type = join "|", @{ $node->enum };
        }

        $line .= sprintf "%*s%s=%s%s\n",
                         $opts{option_indent}, "",
                         $dash_opt, $type,
                         $init_val;
      }
      # }}}

      # option description (reformatted help message) # {{{
      $line .= _reformat(
        $node->help,
        $opts{screen}, $opts{description_indent}
      );
      # }}}
    }

    if (_nlines($line) > 16 || $format_markers{multiline_synopsis} ||
        $opts{header} || $opts{description}) {
      # additional empty line between synopsis and options description
      $help .= "\n";
    }

    $help .= $line;
    $format_markers{has_options} = 1;
  }

  # }}}
  #---------------------------------------------------------
  # footer {{{

  if ($opts{footer}) {
    $line = _reformat($opts{footer}, $opts{screen});
    $line =~ s/%0/$opts{arg0}/g;

    $help .= "\n";
    $help .= $line;
  }

  # }}}
  #---------------------------------------------------------

  return $help;
}

=begin Internal

=pod _nlines(), _reformat() {{{

=item C<_nlines($string)>

Calculate number of lines in C<$string>.

=cut

sub _nlines {
  my ($str) = @_;

  my $nlines =()= ($str =~ /\n/g);

  return $nlines;
}

=item C<_reformat($string, $max_width, $indent)>

Reformat a multiparagraph string to include maximum of C<$width-1> characters
per line, including indentation.

=cut

sub _reformat {
  my ($str, $width, $indent) = @_;

  $indent ||= 0;

  my @result;

  $str =~ s/^\s+//;
  for my $para (split /\n\s*\n[ \t]*/, $str) {
    my $r = "";
    my $line = "";
    for my $w (split /\s+/, $para) {
      if ($line eq "") {
        $line = (" " x $indent) . $w;
      } elsif (length($line) + 1 + length($w) < $width) {
        $line .= " " . $w;
      } else {
        $r .= $line . "\n";
        $line = (" " x $indent) . $w;
      }
    }
    $r .= $line . "\n";
    push @result, $r;
  }

  return join "\n", @result;
}

=end Internal

=pod }}}

=cut

#-----------------------------------------------------------------------------

=item C<options($options)>

Set options read from configuration file (hashref).

Example usage:

  App::Getconf->options(YAML::LoadFile("/etc/myapp.yaml"));

=cut

sub options {
  my ($self, $options) = @_;

  $self = $static unless ref $self; # static call or non-static?

  $self->set_verify($options);
}

#-----------------------------------------------------------------------------

=item C<cmdline($arguments)>

Set options based on command line arguments (arrayref). If C<$arguments> was
not specified, C<@ARGV> is used.

Method returns list of messages (single line, no C<\n> at end) for errors that
were found, naturally empty if nothing was found.

Arguments that were not options can be retrieved using C<args()> method.

Example usage:

  App::Getconf->cmdline(\@ARGV);
  # the same: App::Getconf->cmdline();
  for my $arg (App::Getconf->args()) {
    # ...
  }

=cut

sub cmdline {
  my ($self, $arguments) = @_;

  $self = $static unless ref $self; # static call or non-static?

  my @args = @{ $arguments || \@ARGV };
  my @left;
  my @errors;

  OPTION:
  for (my $i = 0; $i < @args; ++$i) {
    my $option;
    my $option_name;
    my $option_arg; # undef only when no argument, with argument at least ""

    if ($args[$i] =~ /^--([a-zA-Z0-9-]+)=(.*)$/) {
      # long option with parameter {{{

      $option_name = $1;
      $option_arg  = $2;
      $option = "--$option_name";

      push @errors, $self->_try_set($option, $option_name, $option_arg);

      # }}}
    } elsif ($args[$i] =~ /^--([a-zA-Z0-9-]+)$/) {
      # long option, possible parameter in next argument {{{

      $option_name = $1;
      $option = $args[$i];

      # there's no option of exactly the same name, but the --option looks
      # like a negation of Boolean
      if (!$self->has_option($option_name) && $option_name =~ /^no-/) {
        my $negated_name = substr $option_name, 3;

        # there is an option without "--no-" prefix and that option is
        # a Boolean, so it might be actually negated
        if ($self->has_option($negated_name) &&
            $self->option_node($negated_name)->type() eq 'bool') {
          $option_name = $negated_name;
          $option = "--$negated_name";
          $option_arg = 0;
        }
      }

      if ($self->has_option($option_name) &&
          $self->option_node($option_name)->requires_arg()) {
        # consume the next argument, if this is possible; if not, report an
        # error
        if ($i < $#args) {
          # TODO: if $args[++$i] =~ /^-/, don't consume it (require people to
          # use "--foo=-arg" form)
          $option_arg = $args[++$i];
        } else {
          push @errors, {
            option => $option,
            cause => "missing argument",
          };
        }
      }

      push @errors, $self->_try_set($option, $option_name, $option_arg);

      # }}}
    } elsif ($args[$i] =~ /^-([a-zA-Z0-9]+)$/) {
      # set of short options {{{

      my @short_opts = split //, $1;

      for my $sopt (@short_opts) {
        # XXX: short options can't have arguments specified
        push @errors, $self->_try_set("-$sopt", $sopt);
      }

      next OPTION;

      # }}}
    } elsif ($args[$i] eq "--") {
      # end-of-options marker {{{

      # mark all the rest of arguments as non-options
      push @left, @args[$i + 1 .. $#args];
      last OPTION;

      # }}}
    } elsif ($args[$i] =~ /^-/) {
      # anything beginning with dash (e.g. "-@", "--()&*^&^") {{{

      push @errors, {
        option => $args[$i],
        cause => "unknown option",
      };

      # }}}
    } else {
      # non-option {{{

      push @left, $args[$i];
      next OPTION;

      # }}}
    }
  }

  $self->{args} = \@left;

  if (@errors) {
    # TODO: use $_->{"eval"}
    return map { "$_->{option}: $_->{cause}" } @errors;
  } else {
    return;
  }
}

#-----------------------------------------------------------------------------

=item C<has_option($name)>

Check if the schema contains a command line option called C<$name> (aliases
are resolved).

B<NOTE>: This is a semi-internal API.

=cut

sub has_option {
  my ($self, $name) = @_;

  $self = $static unless ref $self; # static call or non-static?

  $name =~ tr/-/./;

  return defined $self->{options}{$name} || defined $self->{aliases}{$name};
}

=item C<option_node($name)>

Retrieve an option node (L<App::Getconf::Node(3)>) corresponding to C<$name>.

Method C<die()>s when no such option is defined in schema.

B<NOTE>: This is a semi-internal API.

=cut

sub option_node {
  my ($self, $name) = @_;

  $self = $static unless ref $self; # static call or non-static?

  $name =~ tr/-/./;

  if ($self->{options}{$name}) {
    return $self->{options}{$name};
  }

  if ($self->{aliases}{$name}) {
    my $target = $self->{aliases}{$name}->alias;
    return $self->{options}{$target};
  }

  croak "No option called $name in schema";
}

=begin Internal

=pod _try_set() {{{

=item C<_try_set($option, $option_name, $option_argument)>

Try setting option C<$option_name> (C<$option> was the actual name, under
which it was specified -- mainly I<-X> or I<--long-X>). If the option was
given a parameter (empty string counts here, too), it should be specified as
C<$option_argument>, otherwise C<$option_argument> should be left C<undef>.

In case of success, returned value is empty list. In case of failure,
returned value is a hashref with two keys: I<option> containing C<$option> and
I<cause> containing an error message. There could be third key I<eval>,
containing C<$@>. Method is suitable for
C<< push @errors, $o->_try_set(...) >>.

=cut

sub _try_set {
  my ($self, $option, $opt_name, $opt_arg) = @_;

  if (not $self->has_option($opt_name)) {
    return {
      option => $option,
      cause => "unknown option",
    };
  }

  my $node = $self->option_node($opt_name);

  if (defined $opt_arg) {
    if (not eval { $node->set($opt_arg); "OK" }) {
      chomp $@;
      return {
        option => $option,
        cause => "invalid option argument: $opt_arg",
        eval => $@,
      };
    }
  } else { # not defined $opt_arg
    # XXX: this is important not to pass an argument to $node->set() here, as
    # it would try to set undef
    if (not eval { $node->set(); "OK" }) {
      chomp $@;
      return {
        option => $option,
        cause => "invalid option argument: <undef>",
        eval => $@,
      };
    }
  }

  return ();
}

=end Internal

=pod }}}

=cut

#-----------------------------------------------------------------------------

=item C<set_verify($data)>

=item C<set_verify($data, $path)>

Set value(s) with verification against schema. If C<$path> was specified,
options start with this prefix. If values were verified successfully, they are
saved in internal storage.

B<NOTE>: This is a semi-internal API.

=cut

sub set_verify {
  my ($self, $data, $path) = @_;

  $self = $static unless ref $self; # static call or non-static?

  $path ||= "";

  my $datum_type = lc(ref $data) || "scalar";

  if ($datum_type ne 'hash') {
    # this is an option, but there's no corresponding schema node
    if (not $self->has_option($path)) {
      # $path: unknown option ($datum_type)
      croak "Unexpected $datum_type option ($path)";
    }

    $self->option_node($path)->set($data);

    return;
  }

  # more complex case: data is a hash

  # if no corresponding node in schema, just go deeper
  # if there is corresponding node, but it's not a hash, just go deeper, too
  if (!$self->has_option($path) ||
      $self->option_node($path)->storage() ne 'hash') {
    for my $o (keys %$data) {
      my $new_path = "$path.$o";
      $new_path =~ s/^\.|\.$//g;

      $self->set_verify($data->{$o}, $new_path);
    }

    return;
  }

  # it's sure that option called $path exists and it's storage type is "hash"
  # also, this option's type is hash

  my $node = $self->option_node($path);
  for my $k (keys %$data) {
    $node->set($k, $data->{$k});
  }
}

#-----------------------------------------------------------------------------

=item C<args()>

Retrieve non-option arguments (e.g. everything after "--") passed from command
line.

Values returned by this method are set by C<cmdline()> method.

=cut

sub args {
  my ($self) = @_;

  $self = $static unless ref $self; # static call or non-static?

  return @{ $self->{args} };
}

#-----------------------------------------------------------------------------

=item C<getopt($package)>

Retrieve a view of options (L<App::Getconf::View(3)>) appropriate for
package or subsystem called C<$package>.

If C<$package> was not provided, caller's package name is used.

C<$package> sets option search path. See C<new()>, C<prefix> option
description in L<App::Getconf::View(3)> for details.

Typical usage:

  sub foo {
    my (@args) = @_;

    my $opts = App::Getconf->getopt(__PACKAGE__);

    if ($opts->ssl) {
      # ...

=cut

sub getopt {
  my ($self, $package) = @_;

  $self = $static unless ref $self; # static call or non-static?
  if (not defined $package) {
    $package = caller;
    if (!defined $package || $package eq 'main') {
      $package = '';
    }
  }

  $package =~ s{/|::}{.}g;
  $package = lc $package;

  if (not $self->{getopt_cache}{$package}) {
    $self->{getopt_cache}{$package} = new App::Getconf::View(
      prefix  => $package,
      options => $self->{options},
    );
  }

  return $self->{getopt_cache}{$package};
}

#-----------------------------------------------------------------------------

=back

=cut

#-----------------------------------------------------------------------------

=head2 Functions Defining Schema

=over

=cut

#-----------------------------------------------------------------------------

=item C<< schema(key => value, key => value, ...) >>

Create a hashref from key/value pairs. The resulting hash is tied to
L<Tie::IxHash(3)>, so the order of keys is preserved.

Main use is for defining order of options in I<--help> message, otherwise it
acts just like anonymous hashref creation (C<< { key => value, ... } >>).

=cut

sub schema {
  my (@args) = @_;

  tie my %h, 'Tie::IxHash';
  %h = @args;

  return \%h;
}

#-----------------------------------------------------------------------------

=item C<opt($data)>

Generic option specification.

Possible data:

  opt {
    type    => 'flag' | 'bool' | 'int' | 'float' | 'string',
    check   => qr// | sub {} | ["enum", "value", ...],
    storage => undef | \$foo | [] | {},
    help    => "message displayed on --help",
    value   => "initial value",
    default => "default value",
  }

If type is not specified, the option is treated as a string.

Check is for verifying correctness of specified option. It may be a regexp,
callback function (it gets the value to check as a first argument and in C<$_>
variable) or list of possible string values.

Types of options:

=over

=item C<flag>

Simple option, like I<--help> or I<--version>. Flag's value tells how many
times it was encountered.

=item C<bool>

ON/OFF option. May be turned on (I<--verbose>) or off (I<--no-verbose>).

=item C<int>

Option containing an integer.

=item C<float>

Option containing a floating point number.

=item C<string>

Option containing a string. This is the default.

=back

Storage tells if the option is a single-value (default), multi-value
accumulator (e.g. may be specified in command line multiple times, and the
option arguments will be stored in an array) or multi-value hash accumulator
(similar, but option argument is specified as C<key=value>, and the value part
is validated). Note that this specify only type of storage, not the actual
container.

B<NOTE>: Don't specify option with a hash storage and that has sub-options
(see L</"Schema Definition">). Verification can't tell whether the value is
meant for the hash under this option or for one of its sub-options.

Presence of C<help> key indicates that this option should be exposed to
end-users in I<--help> message. Options lacking this key will be skipped (but
stil honoured by App::Getconf).

Except for flags (I<--help>) and bool (I<--no-verbose>) options, the rest of
types require an argument. It may be specified as I<--timeout=120> or as
I<--timeout 120>. This requirement may be loosened by providing
C<default> value. This way end-user may just provide I<--timeout> option, and
the argument to the option is taken from default. (Of course, only
I<--timeout=120> form is supported if the argument needs to be provided.)

Initial value (C<value> key) is the value set for the option just after
defining schema. It may or may not be changed with command line options (which
is different from C<default>, for which the option still needs to be
specified).

Initial and default values are both subject to check that was specified, if
any.

Help message will not retain any formatting, all whitespaces are converted to
single space (empty lines are squeezed to single empty line). On the other
hand, the message will be pretty wrapped and indented, while you don't need to
worry about formatting the string if it is longer and broken to separate lines
in your source code, so I think it's a good trade-off.

=cut

sub opt($) {
  my ($data) = @_;

  my $type    = $data->{type} || "string";
  my $check   = $data->{check};
  my $storage = $data->{storage};
  my $help    = $data->{help};
  my $value   = $data->{value};   # not necessary, but kept for convention
  my $default = $data->{default}; # not necessary, but kept for convention

  if (ref $storage) {
    # make sure the store is not a reference to something outside of this
    # function
    if (ref $storage eq 'ARRAY') {
      $storage = 'array';
    } elsif (ref $storage eq 'HASH') {
      $storage = 'hash';
    } elsif (ref $storage eq 'SCALAR') {
      $storage = 'scalar';
    } # TODO: else die?
  } else {
    $storage = 'scalar';
  }

  return new App::Getconf::Node(
    type    => $type,
    check   => $check,
    storage => $storage,
    help    => $help,
    # XXX: this way undefs are possible to represent as undefs
    (exists $data->{value}   ? (value   => $value  ) : ()),
    (exists $data->{default} ? (default => $default) : ()),
  );
}

=item C<opt_alias($option)>

Create an alias for C<$option>. Note that aliases are purely for command line.
L<App::Getconf::View(3)> and C<options()> method don't honour them.

Aliases may only point to non-alias options.

=cut

sub opt_alias($) {
  my ($dest_option) = @_;

  return new App::Getconf::Node(alias => $dest_option);
}

=item C<opt_flag()>

Flag option (like I<--help>, I<--verbose> or I<--debug>).

=cut

sub opt_flag() {
  return opt { type => 'flag' };
}

=item C<opt_bool()>

Boolean option (like I<--recursive>). Such option gets its counterpart
called I<--no-${option}> (mentioned I<--recursive> gets I<--no-recursive>).

=cut

sub opt_bool() {
  return opt { type => 'bool' };
}

=item C<opt_int()>

Integer option (I<--retries=3>).

=cut

sub opt_int() {
  return opt { type => 'int' };
}

=item C<opt_float()>

Option specifying a floating point number.

=cut

sub opt_float() {
  return opt { type => 'float' };
}

=item C<opt_string()>

Option specifying a string.

=cut

sub opt_string() {
  return opt { type => 'string' };
}

=item C<opt_path()>

Option specifying a path in local filesystem.

=cut

sub opt_path() {
  # TODO: some checks on how this looks like
  #   * existing file
  #   * existing directory
  #   * non-existing file (directory exists)
  #   * Maasai?
  return opt { type => 'string' };
}

=item C<opt_hostname()>

Option specifying a hostname.

B<NOTE>: This doesn't check DNS for the hostname to exist. This only checks
hostname's syntactic correctness (and only to some degree).

=cut

sub opt_hostname() {
  return opt { check => qr/^[a-z0-9-]+(\.[a-z0-9-]+)*$/i };
}

=item C<opt_re(qr/.../)>

Option specifying a string, with check specified as regexp.

=cut

sub opt_re($) {
  my ($re) = @_;

  return opt { check => $re };
}

=item C<opt_sub(sub {...})>

=item C<opt_sub {...}>

Option specifying a string, with check specified as function (code ref).

Subroutine will have C<$_> set to value to check, and the value will be the
only argument (C<@_>) passed.

Subroutine should return C<TRUE> when option value should be accepted,
C<FALSE> otherwise.

=cut

sub opt_sub(&) {
  my ($sub) = @_;

  return opt { check => $sub };
}

=item C<opt_enum ["first", ...]>

Option specifying a string. The string must be one of the specified in the
array.

=cut

sub opt_enum($) {
  my ($choices) = @_;

  return opt { check => $choices };
}

#-----------------------------------------------------------------------------

=back

=cut

#-----------------------------------------------------------------------------

=head1 AUTHOR

Stanislaw Klekot, C<< <cpan at jarowit.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stanislaw Klekot.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<App::Getconf::View(3)>, L<Getopt::Long(3)>, L<Tie::IxHash(3)>.

=cut

#-----------------------------------------------------------------------------
1;
# vim:ft=perl:foldmethod=marker
