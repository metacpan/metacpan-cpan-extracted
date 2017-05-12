#-----------------------------------------------------------------
# App::Cmdline
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see the POD.
#
# ABSTRACT: helper for writing command-line applications
# PODNAME: App::Cmdline
#-----------------------------------------------------------------
use warnings;
use strict;

package App::Cmdline;
use parent 'App::Cmd::Simple';

our $VERSION = '0.1.2'; # VERSION

BEGIN {
    # we need to say no_auto_version early
    use Getopt::Long qw(:config no_auto_version);
}
use Sub::Install;

# ----------------------------------------------------------------
# Return the command-line script usage (the 1st line of the
# Usage). The content of the usage slightly differs depending on the
# configuration options used.
# ----------------------------------------------------------------
sub usage_desc {
    my $self = shift;
    my $config = { map { $_ => 1 } @{ $self->getopt_conf() } };
    if (exists $config->{'no_bundling'}) {
        return "%c [short or long options, not bundled]";
    } else {
        return "%c %o";
    }
}

# ----------------------------------------------------------------
# Create (and return) option definitions from wanted option sets
# (given as class names). Also install the validate_args() subroutine
# that will call validate_opts() on all wanted option sets.
# ----------------------------------------------------------------
sub composed_of {
    my $self = shift;
    my @option_classes = @_;  # list of class names with wanted options sets

    # create option definitions
    my @opt_spec = ();
    foreach my $set (@option_classes) {
        push (@opt_spec, $set) and next if ref ($set);
        ## no critic
        eval "require $set";
        if ($set->can ('get_opt_spec')) {
            push (@opt_spec, $set->get_opt_spec());
        } else {
            warn "Cannot find the set of options $set. The set is, therefore, ignored.\n";
        }
    }

    # install a dispatcher of all validating methods
    Sub::Install::reinstall_sub ({
        code => sub {
            foreach my $set (@option_classes) {
                next if ref ($set);
                if ($set->can ('validate_opts')) {
                    $set->validate_opts ($self, @_);
                }
            }
        },
        as   => 'validate_args',
                               });
    # add the configuration options
    return (@opt_spec, { getopt_conf => $self->getopt_conf() } );
}

# ----------------------------------------------------------------
# Check if the given set of options has duplications. Warn if yes.
# ----------------------------------------------------------------
sub check_for_duplicates {
    my ($self, @opt_spec) = @_;
    my $already_defined = {};
    foreach my $opt (@opt_spec) {
        # e.g. $opt: [ 'check|c' => "only check the configuration"  ]
        #      or:   []
        next unless ref ($opt) eq 'ARRAY';
        next if @$opt == 0;
        my ($opt_name) = split (m{\|}, $opt->[0]);
        next unless defined $opt_name;
        if (exists $already_defined->{$opt_name}) {
            warn
                "Found duplicated definition of the option '$opt_name': [" .
                join (' => ', @$opt) . "].\n";
        } else {
            $already_defined->{$opt_name} = 1;
        }
    }
    return @opt_spec;
}

# ----------------------------------------------------------------
# Return a refarray of the Getopt configuration options.
# ----------------------------------------------------------------
sub getopt_conf {
    return [
        'no_bundling',
        'no_ignore_case',
        'auto_abbrev',
        ];
}

# ----------------------------------------------------------------
# Die with a given $error message and with the full Usage.
# ----------------------------------------------------------------
sub usage_error {
    my ( $self, $error ) = @_;
    die "Error: $error\nUsage: " . $self->usage->text;
}

1;


=pod

=head1 NAME

App::Cmdline - helper for writing command-line applications

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

In your command-line script, e.g. in F<myapp>:

   use App::myapp;
   App::myapp->run;

Such command-line script will be executed, for example, by:

  senger@ShereKhan$ myapp --version
  senger@ShereKhan$ myapp --check
  senger@ShereKhan$ myapp -c

In your module that does the full job you are implementing, e.g. in
F<App/myapp.pm>:

   package App::myapp;
   use parent 'App::Cmdline';

   # Define your own options, and/or add some predefined sets.
   sub opt_spec {
       my $self = shift;
       return $self->check_for_duplicates (
           [ 'check|c' => "only check the configuration"  ],
           $self->composed_of (
               'App::Cmdline::Options::Basic',
               'App::Cmdline::Options::DB',
           )
       );
   }

   # The main job is implemented here
   use Data::Dumper;
   sub execute {
       my ($self, $opt, $args) = @_;

       print STDERR "Started...\n" unless $opt->quiet;
       print STDOUT 'Options ($opt):    ' . Dumper ($opt);
       print STDOUT 'Arguments ($args): ' . Dumper ($args);
       ...
   }

=head1 DESCRIPTION

This module helps to write command-line applications, especially if
they need to be fed by some command-line options and arguments. It
extends the L<App::Cmd::Simple> module by adding the ability to use
several predefined sets of options that many real command-line
applications use and need anyway. For example, in most applications
you need a way how to print its version or how to provide a decent
help text. Once (or if) you agree with the way how it is done here,
you can spend much less time with the almost-always-repeating options.

Your module (representing the application you are writing) should
inherit from this module and implement, at least, the method
L<opt_spec|"opt_spec"> (optionally) and the method L<execute|"execute"> (mandatory).

=for :stopwords d'E<234>tre

=head1 METHODS

In order to use the ability of composing list of options from the
existing sets of predefined options (which is, after all, the main
I<raison d'E<234>tre> of this module) use the method
L<composed_of|"composed_of">. And to find out that various predefined
sets of options do not step on each other toes, use the method
L<check_for_duplicates|"check_for_duplicates">.

When writing a subclass of App::Cmdline, there are only a few methods
that you might want to overwrite (except for L<execute|"execute"> that you
B<must> overwrite). Below are those that may be of your interest, or
those that are implemented here slightly differently from the
L<App::Cmd::Simple>.

=head3 Summary of methods

=over

=item Methods that you must overwrite

   execute()

=item Methods that you should overwrite

   opt_spec()

=item Methods that you may overwrite

   usage_desc()
   validate_args()
   usage_error()
   getopt_conf()
   ...

=item Methods that you just call

   composed_of()
   check_for_duplicates()
   usage_error()

=back

=head2 B<opt_spec>

This method returns a list with option definitions, each element being
an arrayref. This returned list is passed (starting as its second
argument) to C<describe_options> from
L<Getopt::Long::Descriptive>. You need to check the documentation on
how to specify options, but mainly each element is a pair of I<option
specification> and the I<help text for this option>. For example:

   sub opt_spec {
       my $self = shift;
       return
           [ 'latitude|y=s'  => "geographical latitude"  ],
           [ 'longitude|x=s' => "geographical longitude" ],
       ;
   }

The I<option specification> (the first part of each pair) is how the
option can appear on the command-line, in its short or long version, if
it takes a value, how/if can be repeated, etc.

The option elements can be richer. Another useful piece of the option
definition is its default value - see an example of it in
L<App::Cmdline::Options::DB/OPTIONS>.

The example above, however, does not add anything new to the
L<App::Cmd::Simple>. Specifying the options this way, you could (and
probably should) inherit directly from the L<App::Cmd::Simple> without
using C<App::Cmdline>. Therefore, let's have another example:

   sub opt_spec {
       my $self = shift;
       return
           [ 'latitude|y=s'  => "geographical latitude"  ],
           [ 'longitude|x=s' => "geographical longitude" ],
           $self->composed_of (
               'App::Cmdline::Options::Basic',
               'App::Cmdline::Options::DB',
           );
   }

In this example, your command-line application will recognize the same
options (latitude and longitude) as before and, additionally, all
options that were predefined in the I<role> classes
L<App::Cmdline::Options::Basic> and L<App::Cmdline::Options::DB>. See
more about these classes in L<"PREDEFINED SETS OF OPTIONS">;

If not overridden, it returns an empty list.

=head2 B<composed_of>

The core method of this module. You call it with a list of names of
the classes that are able to give back a list of predefined options
that you may instantly use. The classes are not only specifying their
options but, for some options, they also B<do> something. For example,
the C<-h> option (defined in L<App::Cmdline::Options::Basic>) prints
the usage and exits.

This distribution contains few such classes (see the L<"PREDEFINED
SETS OF OPTIONS">). Later, they may be published other similar classes
providing different sets of options.

The method returns a list of options definitions that is suitable
for including in the returned values of the L<opt_spec|"opt_spec">
method (as it was shown in the example above). The returned value
should always be used only at the end, after your application
specifies its own options (those that are not coming from any
predefined set). This is because the last element of the returned
list is a hashref containing configuration for the L<Getopt::Long> -
as described in the L<Getopt::Long::Descriptive>. Therefore, if you
need to call this method more than once or not at the end, perhaps
because you wish to see the options in the help usage in a different
order, you need to remove its last element before you add anything
after that:

   sub opt_spec {
       my $self = shift;
       my @db_options = $self->composed_of ('App::Cmdline::Options::DB');
       pop @db_options;
       return
           @db_options,
           [ 'latitude|y=s'  => "geographical latitude"  ],
           [ 'longitude|x=s' => "geographical longitude" ],
           $self->composed_of (
               'App::Cmdline::Options::Basic',
           );
   }

The last example looks a bit inconvenient. And you do not need to do
it that way - because the C<composed_of> method accepts also any
arrayrefs, ignoring them and just passing them to its return
value. That's why you really can call this method only once and not to
be bothered with the hashref at the end. Here is an example how you
can combine class names (predefined sets) with your own option
specification and/or usage separators (the empty arrayrefs):

    return
        [ 'check|c' => "only check the configuration"  ],
        [],
        $self->composed_of (
            'App::Cmdline::Options::DB',
            [ 'show|s' => "show database access properties"  ],
            [],
            'App::Cmdline::Options::Basic',
        );

which - when called with the -h option - shows this nicely formatted
usage:

    Usage: myapp [short or long options, not bundled]
        -c --check      only check the configuration

        --dbname        database name
        --dbhost        hostname hosting database
        --dbport        database port number
        --dbuser        user name to access database
        --dbpasswd      password to access database
        --dbsocket      UNIX socket accessing the database
        -s --show       show database access properties

        -h              display a short usage message
        -v --version    display a version

=head2 B<check_for_duplicates>

When you are composing options from more sets, it is worth to check
whether, unintentionally, some options are not duplicated. It can be
done by this method that gets the list of options definitions, checks
it (warning if any duplicate was found, and returning the same list
unchanged. It can, therefore, be used like this:

   sub opt_spec {
       my $self = shift;
       return $self->check_for_duplicates (
           [ 'latitude|y=s'  => "geographical latitude"  ],
           [ 'longitude|x=s' => "geographical longitude" ],
           $self->composed_of (
               'App::Cmdline::Options::Basic',
               'App::Cmdline::Options::DB',
           )
       );
   }

=head2 B<getopt_conf>

The machinery behind the scene is done by the L<Getopt::Long>
module. This module can be configured by a list of strings in order to
achieve a different interpretation of the command-line options. Such
as to treat them case-insensitively, or to allow them to be bundled
together. For the recognized strings you need to read the
L<Getopt::Long/"Configuring Getopt::Long">. Here is shown how and
when to use them.

The C<App::Cmdline> provides a default set of strings:

   sub getopt_conf {
       return [
          'no_bundling',
          'no_ignore_case',
          'auto_abbrev',
       ];
   }

If you need it differently, override the getopt_conf method, returning
an arrayref with configuration strings you want. Here are the examples
showing the difference. Using the default configuration and having the
following options:

   sub opt_spec {
       my $self = shift;
       return
           [ 'xpoint|x' => 'make an X point'],
           [ 'ypoint|y' => 'make a  Y point'],
           [],
           $self->composed_of (
               'App::Cmdline::Options::Basic',
           );
   }

I can run (and get dumped the recognized options and arguments in the
C<execute> method:

   senger@ShereKhan2:myapp -x -y
   Executing...
   Options ($opt):    $VAR1 = bless( {
      'xpoint' => 1,
      'ypoint' => 1
       }, 'Getopt::Long::Descriptive::Opts::__OPT__::2' );
   Arguments ($args): $VAR1 = [];

You can see that both options, C<-x> and C<-y>, were recognized. But
if I bundle them (and by default, the bundling is disabled), I get no
recognized options; instead they will be shown as arguments (arguments
being everything what remained not recognized on the command-line):

   senger@ShereKhan2:myapp -x -y
   Executing...
   Options ($opt):    $VAR1 = bless( {}, 'Getopt::Long::Descriptive::Opts::__OPT__::2' );
   Arguments ($args): $VAR1 = [ '-xy' ];

But if I change the configuration by implementing:

   sub getopt_conf {
       return [ 'bundling' ];
   }

the bundled options are now recognized as options (and no argument
reminded):

   senger@ShereKhan2:myapp -xy
   Executing...
   Options ($opt):    $VAR1 = bless( {
      'xpoint' => 1,
      'ypoint' => 1
       }, 'Getopt::Long::Descriptive::Opts::__OPT__::2' );
   Arguments ($args): $VAR1 = [];

=head2 B<usage_desc>

The returned value from this method will be used as the first line of
the usage message. The full usage is returned by another method,
C<usage>, that you usually do not overwrite because its default
behaviour is to create a reasonable summary from the help texts you
provided in the L<opt_spec|"opt_spec"> method and, possibly, by this
C<usage_desc> method.

Behind the scene, the returned string is interpreted by the
L<Getopt::Long::Descriptive> which accepts also few special
constructs:

=over

=item

%c will be replaced with what C<Getopt::Long::Descriptive> thinks is
the program name (it is computed from $0).

=item

%o will be replaced with a list of the short options, as well as the
text "[long options...]" if any have been defined.

=item

Literal % characters will need to be written as %%, just like with
sprintf.

=back

By default, the C<App::Cmdline> returns slightly different usage
description depending on the bundling configuration option (see
L<getopt_conf|"getopt_conf">): if the bundling is disabled, the bundle
of all short options is not shown. Often, you want to use whatever
C<App::Cmdline> returns plus what you wish to add on the first line of
the usage. For example:

   sub usage_desc {
       return shift->SUPER::usage_desc() . ' ...and anything else';
   }

=head2 B<validate_args>

Originally, this method was meant to check (validate) the command-line
arguments (remember that arguments are whatever remains on the
command-line after options defined in the L<opt_spec|"opt_spec">
method have been processed). The options themselves could be already
validated by various subroutines and attributes given in the option
specifications (as described, sometimes only vaguely, in the
L<Getopt::Long::Descriptive>). But sometimes, it is useful to have all
validation, of options and of arguments, in one place - so we have
this method.

The method gets two parameters, C<$opt> and C<$args>. The first one is
an instance of L<Getopt::Long::Descriptive::Opts> giving you access to
all existing options, using their names (as were defined in
L<opt_spec|"opt_spec">) as the access methods. The second parameter is
an arrayref containing all remaining arguments on the command-line.

I<Important:> Some predefined sets of options (see the L<"PREDEFINED
SETS OF OPTIONS">) do also some checking (or other actions, like
printing the version and exiting) and this checking is invoked from
the C<App::Cmdline>'s validate_args method. Therefore, it is strongly
recommended that if you overwrite this method, you also call the SUPER:

   sub validate_args {
       my ($self, $opt, $args) = @_;
       $self->SUPER::validate_args ($opt, $args);
       if ($opt->number and scalar @$args != $opt->number) {
          $self->usage_error ("Option --number does not correspond with the number of arguments");
       }
   }

   senger@ShereKhan2:myapp -n 2 a b c
   Error: Option --number does not correspond with the number of arguments
   Usage: myapp [short or long options, not bundled] <some arguments...>
        -n --number     expected number of args
        -h              display a short usage message
        -v --version    display a version

The example also shows calling the method C<usage_error>. Unless you
overwrite also this method, it prints the given error message together
with the usage and dies.

=head2 B<execute>

Last but definitely not least. You B<have> to implement this method
and put here whatever your command-line application is supposed to do.

The method gets two parameters, C<$opt> and C<$args>. The first one is
an instance of L<Getopt::Long::Descriptive::Opts> giving you access to
all existing options, using their names (as were defined in
L<opt_spec|"opt_spec">) as the access methods. The second parameter is
an arrayref containing all remaining arguments on the command-line.

   sub execute {
       my ($self, $opt, $args) = @_;
       if ($opt->crystal eq 'ball') {
          print ask_ball ($args->[0]);
       } else {
          die "All is vanity...\n"
             unless $opt->godess;
       }
   }

=head1 PREDEFINED SETS OF OPTIONS

The predefined sets of options are represented by classes that are
considered rather C<roles>. You do not extend them (inherit from them)
but you just use them (by naming them in the method
L<composed_of|"composed_of">).

This distribution bundles several of such classes. See their own
documentation to find out what options they provide. Here is just a
quick summary:

=over

=item L<App::Cmdline::Options::Basic>

Provides basic options (help and version).

=item L<App::Cmdline::Options::ExtBasic>

Provides the same options as in L<App::Cmdline::Options::Basic> and
adds options for richer documentation.

=item L<App::Cmdline::Options::DB>

Provides options for accessing a database (user authentication, host and
port name, etc.).

=item L<App::Cmdline::Options::ExtDB>

Provides the same options as in L<App::Cmdline::Options::DB> and adds
an option for showing what values were given by the database-related
options.

=back

=head3 How to create a new predefined set

You may wish to create a new set of options if you want to re-use
them. For application-specific options, used only once, you do not
need to have a predefined set, you just specify them directly in the
L<opt_spec|"opt_spec"> method.

The classes that can be used as the predefined sets of options do not
inherit from any common class (so far, there was no need for it) -
unless one extends another one (as is the case of
L<App::Cmdline::Options::ExtBasic>). It is, however, recommended, to
use the namespace I<App::Cmdline::Options::> - just to find them
easier on CPAN.

Each of these classes should implement up to two methods:

=over

=item B<get_opt_spec>

Strictly speaking, it is not mandatory, but without this method the
class can hardly predefine any new options. The method should return
a list of arrayrefs, suitable to be consumed by the
L<opt_spec|"opt_spec"> method. For example (taken from the
L<App::Cmdline::Options::Basic>):

   sub get_opt_spec {
       return
           [ 'h'         => "display a short usage message"  ],
           [ 'version|v' => "display a version"              ];
   }

=item B<validate_opts>

This method, if exists, will be called from the
L<validate_args|"validate_args"> method. Its purpose is to do
something with the options belonging to (predefined by) this class.

It gets four parameters, C<$app> (the class name of your application),
C<$caller> (who is calling), C<$opts> (an object allowing to access
all options) and C<$args> (an arrayref with the remaining arguments
from the command-line).

If it finds an error, it usually dies by calling
$caller->C<usage_error>.

=back

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

I<raison d'E<234>tre>
