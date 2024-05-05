package Carp::Object;
use 5.10.0;
use utf8;
use strict;
use warnings;
use Devel::StackTrace;
use Module::Load qw/load/;
use Clone        qw/clone/;

our $VERSION = 1.02;

my %export_groups = (carp => [qw/carp croak confess/],
                     all  => [qw/carp croak confess cluck/],  );

# ======================================================================
# METHODS
# ======================================================================

sub new {
  my ($class, %args) = @_;
  
  # create $self, consume the 'verbose' arg
  my $self = {verbose => delete $args{verbose}};

  # class for stack traces
  $self->{stacktrace_class} = delete $args{stacktrace_class} // 'Devel::StackTrace';

  # if there is a 'clan' argument, compute a frame filter -- see L<Devel::StackTrace/frame_filter>
  if (my $clan = delete $args{clan}) {
    not $args{frame_filter} or $class->new->croak("can't have arg 'clan' if arg 'frame_filter' is present");
    $args{frame_filter} = sub {my $raw_frame_ref = shift;
                               my $pkg = $raw_frame_ref->{caller}[0];
                               return $pkg !~ /$clan/};
  }

  #  handler for displaying stack frames
  $self->{display_frame}       = delete $args{display_frame} // \&_default_display_frame;
  $self->{display_frame_param} = delete $args{display_frame_param};

  # classes to be ignored by Devel::StackTrace : list supplied by caller + current class
  my $ignore_class = delete $args{ignore_class} // [];
  $ignore_class    = [$ignore_class] if not ref $ignore_class;
  push @$ignore_class, $class;
  $args{ignore_class} = $ignore_class;

  # remaining args will be passed to Devel::StackTrace->new
  $args{message} //= ''; # to avoid the 'Trace begun' string from StackTrace::Frame::as_string
  $args{indent}  //= 1;
  $self->{stacktrace_args} = \%args;

  # return the carper object
  bless $self, $class;
}

sub croak   {my $self = shift; die  $self->msg(join("", @_), 1)} # 1 means "just one frame"
sub carp    {my $self = shift; warn $self->msg(join("", @_), 1)} # idem
sub confess {my $self = shift; die  $self->msg(join("", @_)   )} # no second arg means "the whole stack"
sub cluck   {my $self = shift; warn $self->msg(join("", @_)   )} # idem

sub msg {
  my ($self, $errstr, $n_frames) = @_;
  my $class = ref $self;
  $errstr //= "Died";

  # is this call a croak (single stackframe) or a confess (full stack) ?
  my $want_full_stack = ! defined $n_frames
                        || $self->{verbose} || do {no warnings 'once'; $Carp::Verbose || $Carp::Clan::Verbose};


  # if not doing a "confess", tell Devel::Stacktrace to skip frames from the first outside caller
  my $stacktrace_args = clone $self->{stacktrace_args};
  if (!$want_full_stack) {
    my $outside_caller;
    my $i = 0;
    do {$outside_caller = caller($i++) // ""} while $outside_caller->isa($class);
    push @{$stacktrace_args->{ignore_package}}, $outside_caller unless $outside_caller eq 'main';
  }

  # get stack frames from Devel::StackTrace and truncate the list to the requested number
  load $self->{stacktrace_class};
  my $trace   = $self->{stacktrace_class}->new(%{$stacktrace_args});
  my  @frames = $trace->frames;
  splice @frames, $n_frames  if @frames && !$want_full_stack;

  # complete the original $errstr with frame descriptions
  if (my $first_frame = shift @frames) {
    my $p    = $self->{display_frame_param};                   # see L<Devel::StackTrace/as_string>
    $errstr .= $self->{display_frame}->($first_frame, 1, $p);  # 1 means "is first"
    $errstr .= $self->{display_frame}->($_, undef, $p)  foreach @frames;
  }

  return $errstr;
}

# ======================================================================
# SUBROUTINES (NOT METHODS) -- used as callback
# ======================================================================

sub _default_display_frame {
  my ($frame, $is_first, $p) = @_;

  # let Devel::StackTrace::Frame compute a string representation
  my $str = $frame->as_string($is_first, $p);

  # if this seems to be a method call, make it look like so
  $str =~ s{^ (\t)?              # optional tab    -- capture in $1
              ([\w:]+)           # class name      -- capture in $2
              ::
              (\w+)              # method name     -- capture in $3
              \('                # beginning arg list
                 ( \2            # first arg: again the class name
                   (?: = [^']+)? # .. possibly followed by the ref addr
                 )
                '                # end of fist arg -- capture in $4
                (?: ,\h* )?      # possibly followed by a comma
            }
           {$1$4->$3(}x;         # rewrite as a method call          

  $str .= "." if $is_first;      # because Carp does add this colon to the first line

  return "$str\n";
}
  

# ======================================================================
# IMPORT API (CLASS METHOD)
# ======================================================================

sub import {
  my ($class, @import_list) = @_;
  my $calling_pkg = caller(0);

  # find out what the importer wants
  my ($exports, $options) = $class->parse_import_list(@import_list);

  # default exports : carp, croak and confess
  keys %$exports
    or $exports = { map {$_ => {name => $_}}  @{$export_groups{carp}} };

  # if required, apply prefix and suffix
  if (my $prefix = $options->{prefix}) {
    substr $exports->{$_}{name}, 0, 0, $prefix foreach keys %$exports;
  }
  if (my $suffix = $options->{suffix}) {
    $exports->{$_}{name} .= $suffix foreach keys %$exports;
  }

  # export the requested symbols into the caller
  while (my ($method, $hash) = each %$exports) {
    no strict "refs";
    my $export_as = $hash->{as} // $hash->{name};
    *{"$calling_pkg\::$export_as"} = sub (@) {

      # if present, the current value of %CARP_OBJECT_CONSTRUCTOR within the calling package
      # will be passed to the constructor
      my $constructor_args = *{"$calling_pkg\::CARP_OBJECT_CONSTRUCTOR"}{HASH} // {};

      # if present, the current value of @CARP_NOT within the calling package
      # will be passed as 'ignore_package' to the Devel::StackTrace constructor
      if (my $carp_not = *{"$calling_pkg\::CARP_NOT"}{ARRAY}) {
        $constructor_args->{ignore_package} = $carp_not;
      }

      # build a one-shot instance and call the requested method
      $class->new(%$constructor_args)->$method(@_);
    };
  }

  # install an import function into the caller if -reexport is requested
  if ($options->{reexport}) {
    no strict "refs";
    not *{"$calling_pkg\::import"}{CODE}
      or $class->new->croak("use $class -reexport => ... : $calling_pkg already has an import function");
    *{"$calling_pkg\::import"} = sub {
      my $further_calling_pkg = caller(0);
      foreach my $symbol (keys %$exports) {
        *{"$further_calling_pkg\::$symbol"} = *{"$calling_pkg\::$symbol"}{CODE};
      }
    };
  } 

  # populate %CARP_OBJECT_CONSTRUCTOR within the caller from the 'constructor_args' option
  if (my $args = $options->{constructor_args}) {
    ref $args eq 'HASH'
      or $class->new->croak("use $class {-constructor_args => ...} : must be a hashref");
    no strict 'refs';
    *{"$calling_pkg\::CARP_OBJECT_CONSTRUCTOR"} = $args;
  }
}


sub parse_import_list {
  my ($class, @import_list) = @_;

  my %exports;
  my %options;
  my $last_export;

  # loop on import args
  while (my $arg = shift @import_list) {

    # hashref : options to the exporter
    if (my $ref = ref $arg) {
      $ref eq 'HASH' or $class->new->croak("$class->import() cannot handle $ref references");
      while (my ($k, $v) = each %$arg) {
        if ($k =~ /^-(prefix|suffix|constructor_args|reexport)$/) {
          $options{$1} = $v;
        }
        elsif ($k eq '-as') {
          $last_export or $class->new->croak("use $class ... : {-as => ...} must follow the name of a symbol to import");
          $exports{$last_export}{as} = $v;
        }
        else {
          $class->new->croak("$class->import(): unknown option: '$k'");
        }
      }
    }

    # the 'reexport' option -- different syntax for better readability, for ex: use C:O -reexport => qw/carp croak/;
    elsif ($arg eq '-reexport') {
      $options{reexport} = 1;
    }

    # groups of symbols (:carp, :all)
    elsif ($arg =~ /^[:-](\w+)/) {
      undef $last_export;
      my $group = $export_groups{$1} or $class->new->croak("use $class qw/:$1/ : group '$1' is not exported");
      $exports{$_}{name} = $_ foreach @$group;
    }

    # individual symbols
    elsif ($arg =~ /^(croak|carp|confess|cluck)$/) {
      $exports{$arg}{name} = $arg;
      $last_export = $arg;
    }

    # something that looks like a regexp -- probably intended for Carp::Clan-like behaviour
    elsif ($arg =~ /^\^/ or $arg =~ /[|(]/ ) {
      $options{constructor_args}{clan} = $arg;
    }

    else {
      $class->new->croak("use $class '$arg' : this symbol is not exported");
    }

  }
  return (\%exports, \%options);
}

1;


__END__

=head1 NAME

Carp::Object - a replacement for Carp or Carp::Clan, object-oriented

=head1 SYNOPSIS

=head2 Object-oriented API

  use Carp::Object ();
  my $carper = Carp::Object->new(%options);

  # warn of error (from the perspective of caller)
  $carper->carp("this is very wrong") if some_bad_condition();

  # die of error (from the perspective of caller)
  $carper->croak("that's a dead end") if some_deadly_condition();
  
  # warn with full stacktrace
  $carper->cluck("this is very wrong");

  # die with full stacktrace
  $carper->confess("that's a dead end");

=head2 Functional API

  use Carp::Object qw/:all/;            # many other import options are available, see below
  our %CARP_OBJECT_CONSTRUCTOR = (...); # optional opportunity to tune the carping behaviour
  our @CARP_NOT = (...);                # optional opportunity to exclude packages from stack traces
  
  # warn of error (from the perspective of caller)
  carp "this is very wrong" if some_bad_condition();
  
  # die of error (from the perspective of caller)
  croak "that's a dead end" if some_deadly_condition();

  # full stacktrace
  cluck "this is very wrong";
  confess "that's a dead end";

  # temporary change some parameters, like for example the "clan" of modules to ignore
  { local %CARP_OBJECT_CONSTRUCTOR = (clan => qw(^(Foo|Bar)));
     croak "wrong call to Foo->.. or to Bar->.." if $something_is_wrong; }

=head1 DESCRIPTION

This is an object-oriented alternative to L<Carp/croak> or L<Carp::Clan/croak>,
for reporting errors in modules from the perspective of the caller instead of
reporting the internal implementation line where the error occurs.

L<Carp> or L<Carp::Clan> were designed long ago, at a time when Perl
had no support yet for object-oriented programming; therefore they only
have a functional API that is not very well suited for extensions.
The present module attemps to mimic the same behaviour, but
with an object-oriented implementation that offers more tuning options,
and also supports errors raised as Exception objects.

Unlike L<Carp> or L<Carp::Clan>, where the presentation of stack frames is hard-coded, 
here it is delegated to L<Devel::StackTrace>. This means that clients can also
take advantage of options in L<Devel::StackTrace> to tune the output -- or even replace it by
another class.

Clients can choose between the object-oriented API, presented in the next chapter,
or a traditional functional API compatible with 
L<Carp> or L<Carp::Clan>, presented in the following chapter.

B<DISCLAIMER>: this module is very young and not battle-proofed yet.
Despite many efforts to make it behave as close as possible to the original L<Carp>,
there might be some edge cases where it is not strictly equivalent.
If you encounter such situations, please open an issue at
L<https://github.com/damil/Carp-Object/issues>.


=head1 METHODS

=head2 new

  use Carp::Object (); # '()' to avoid importing any symbols
  my $carper = Carp::Object->new(%options);

This is the constructor for a "carper" object. Options are :

=over

=item verbose

if true, a 'croak' method call is treated as a 'confess', and a 'carp' is treated as a 'cluck'.

=item stacktrace_class

The class to be used for inspecting stack traces. Default is L<Devel::StackTrace>.

=item clan

A regexp for identifying packages that should be skipped in stack traces, like in L<Carp::Clan>.
This option internally computes a C<frame_filter> and therefore is incompatible with the
C<frame_filter> option.

=item display_frame

A reference to a subroutine for computing a textual representation of a stack frame.
The default is L<_default_display_frame>, which is a light wrapper
on top of L<Devel::StackTrace::Frame/as_string>, with improved representation of method calls.
The given subroutine will receive three arguments :

=over

=item 1.

a reference to a L<Devel::StackTrace::Frame> instance

=item 2.

a boolean flag telling if this is the first stack frame in the list (because
the display algorithm is usually different for the first stack frame).

=item 3.

A hashref of optional parameters. Currently there is only one option C<max_arg_length>,
discribed in L<Devel::StackTrace/as_string(\%p)>.

=back

=item display_frame_param

The optional hashref to be supplied as third parameter to the C<display_frame> subroutine.


=item ignore_class

an arrayref of classes that will be passed to L<Devel::StackTrace>; any class
that belongs to or inherits from that list will be ignored in stack traces.
C<Carp::Object> will automatically add itself to the list supplied by the client.

=back

In addition to these options, the constructor also accepts all options to L<Devel::StackTrace/new>,
like for example C<ignore_package>, C<skip_frames>, C<frame_filter>, C<indent>, etc.

=head2 croak

Die of error, from the perspective of the caller.

=head2 carp

Warn of error, from the perspective of the caller.

=head2 confess

Die of error, with full stack backtrace.

=head2 cluck

Warn of error, with full stack backtrace.

=head2 msg

  my $msg = $carper->msg($errstr, $n_frames);

Build the message to be used for dieing or warning.
C<$errstr> is the initial error message; it may be a plain
string or an exception object with a stringification method.
C<$n_frames> is the number of stack frames to display (usually 1); if undefined,
the whole stack trace is displayed.

=head1 FUNCTIONAL API: THE IMPORT() METHOD

  use Carp::Object;                # no import list => defaults to (':carp');
  # or
  use Carp::Object @import_list;

When using this functional API, subroutines equivalent to their corresponding object-oriented
methods are exported into the caller's symbol table: the caller can then call C<carp>, C<croak>, etc.
like with the venerable L<Carp> module.

=head2 Import list

The import list accepts the following items :

=over

=item C<carp>, C<croak>, C<confess> and/or C<cluck>

Individual import of specific routines

=item C<:carp>

Import group equivalent to the list C<carp>, C<croak>, C<confess>.

=item C<:all>

Import group equivalent to the list C<carp>, C<croak>, C<confess>, C<cluck>.

=item C<\%options>

A hashref within the import list is interpreted as a collection of importing options,
in the spirit of L<Sub::Exporter> or L<Exporter::Tiny>. Admitted options are :

=over

=item C<-as>

  use Carp::Object carp => {-as => 'complain'}, croak => {-as => 'explode'};

Local name for the last imported function.

=item C<-prefix>

  use Carp::Object qw/carp croak/, {-prefix => 'CO_'};
  ...
  CO_croak "aargh";

Names of imported functions will be prefixed by this string.


=item C<-suffix>

  use Carp::Object qw/carp croak/, {-suffix => '_CO'};
  ...
  croak_CO "ouch";

Names of imported functions will be suffixed by this string.


=item C<-constructor_args>

  use Carp::Object qw/carp croak/, {-constructor_args => {indent => 0}};

The given hashref will be passed to L<Carp::Object/new> at each call to an imported function.

=back

=item C<-reexport>

  use Carp::Object -reexport => qw/carp croak/;

Imported symbols will be reexported into the caller of the caller !
This is useful when several modules from a same family share a common carping module.
See L<DBIx::DataModel::Carp> for an example (actually, this was the initial motivation
for working on C<Carp::Object>().

=item I<regexp>

  use Carp::Object qw(^(MyClan::|FriendlyOther::));

If the import item "looks like a regexp", it is interpreted as 
syntactic sugar for C<< use Carp::Object {-constructor_args => {clan => ..}} >>,
in order to be compatible with the API of L<Carp::Clan>.

The import item "looks like a regexp" if it starts with a C<'^'> character,
or contains a C<'|'> or a C<'('>.

=back


=head2 Global variables

When using the functional API, customization of C<Carp::Object>
can be done indirectly through global variables in the calling package.
Such variables can be localized in inner blocks if some specific behaviour
is needed.

=head3 C<%CARP_OBJECT_CONSTRUCTOR>

  { local %CARP_OBJECT_CONSTRUCTOR = (indent => 0);
    confess "I'm a great sinner"; # for this call, stack frames will not be indented
  }

The content of this hash will be passed to L<Carp::Object/new> at each call to an imported function.


=head3 C<@CARP_NOT>

The content of this array will be passed as C<ignore_package> argument to
to L<Carp::Object/new> at each call to an imported function.

=head3 C<$Carp::Verbose>

if true, a 'croak' method call is treated as a 'confess', and a 'carp' is treated as a 'cluck'.

=head1 INTERNAL SUBROUTINES

=head2 _default_display_frame

This is the internal routine for displaying a stack frame.

It calls L<Devel::StackTrace::Frame/as_string> for doing
most of the work. An additional feature is that the presentation string
is rewritten for frames that "look like a method call" :
instead of C<< Foobar::method('Foobar=...', @other_args) >>, we
write C<< Foobar=...->method(@other_args) >>, so that method
calls become apparent within the stack trace.

A frame "looks like a method call" if the first argument to the routine
is a string identical to the class, or reference blessed into that class.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
