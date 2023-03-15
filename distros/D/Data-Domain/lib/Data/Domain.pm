#======================================================================
package Data::Domain; # documentation at end of file
#======================================================================
use 5.010;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Scalar::Does 0.007;
use Scalar::Util ();
use Try::Tiny;
use List::MoreUtils qw/part natatime any/;
use if $] < 5.037, experimental => 'smartmatch';
use overload '""' => \&_stringify, $] < 5.037 ? ('~~' => \&_matches) : ();
use match::simple ();

our $VERSION = "1.08";

our $MESSAGE;        # global var for last message from _matches()
our $MAX_DEEP = 100; # limit for recursive calls to inspect()

#----------------------------------------------------------------------
# exports
#----------------------------------------------------------------------

# lists of symbols to export
my @CONSTRUCTORS;
my %SHORTCUTS;

BEGIN {
  @CONSTRUCTORS = qw/Whatever Empty
                     Num Int Nat Date Time String Handle
                     Enum List Struct One_of All_of/;
  %SHORTCUTS = (
    True      => [ -true    => 1        ],
    False     => [ -true    => 0        ],
    Defined   => [ -defined => 1        ],
    Undef     => [ -defined => 0        ],
    Blessed   => [ -blessed => 1        ],
    Unblessed => [ -blessed => 0        ],
    Ref       => [ -ref     => 1        ],
    Unref     => [ -ref     => 0        ],
    Regexp    => [ -does    => 'Regexp' ],
    Obj       => [ -blessed => 1        ],
    Class     => [ -package => 1        ],
  );
}

# setup exports through Sub::Exporter API
use Sub::Exporter -setup => {
  exports    => [ 'node_from_path', 
                  (map {$_ => \&_wrap_domain          } @CONSTRUCTORS  ),
                  (map {$_ => \&_wrap_shortcut_options} keys %SHORTCUTS) ],
  groups     => { constructors => \@CONSTRUCTORS,
                  shortcuts    => [keys %SHORTCUTS] },
  collectors => { INIT => \&_sub_exporter_init },
  installer  => \&_sub_exporter_installer,
};

# customize Sub::Exporter to support "bang-syntax" for excluding symbols
# see https://rt.cpan.org/Public/Bug/Display.html?id=80234
{ my @dont_export;

  # detect symbols prefixed by '!' and remember them in @dont_export
  sub _sub_exporter_init {
    my ($collection, $context) = @_;
    my $args = $context->{import_args};
    my ($exclude, $regular_args) 
      = part {!ref $_->[0] && $_->[0] =~ /^!/ ? 0 : 1} @$args;
    @$args = @$regular_args;
    @dont_export = map {substr($_->[0], 1)} @$exclude;
    1;
  }

  # install symbols, except those that belong to @dont_export
  sub _sub_exporter_installer {
    my ($arg, $to_export) = @_;
    my %export_hash = @$to_export;
    delete @export_hash{@dont_export};
    Sub::Exporter::default_installer($arg, [%export_hash]);
  }
}

# constructors group : for each domain constructor, we export a closure
# that just calls new() on the corresponding subclass. For example,
# Num(@args) is just equivalent to Data::Domain::Num->new(@args).
sub _wrap_domain {
  my ($class, $name, $args, $coll) = @_;
  return sub {return "Data::Domain::$name"->new(@_)};
}


# # shortcuts group : calling 'Whatever' with various pre-built options
sub _wrap_shortcut_options {
  my ($class, $name, $args, $coll) = @_;
  return sub {return Data::Domain::Whatever->new(@{$SHORTCUTS{$name}}, @_)};
}



#----------------------------------------------------------------------
# messages
#----------------------------------------------------------------------

my $builtin_msgs = {
  english => {
    Generic => {
      UNDEFINED     => "undefined data",
      INVALID       => "invalid",
      TOO_SMALL     => "smaller than minimum '%s'",
      TOO_BIG       => "bigger than maximum '%s'",
      EXCLUSION_SET => "belongs to exclusion set",
      MATCH_TRUE    => "data true/false",
      MATCH_ISA     => "is not a '%s'",
      MATCH_CAN     => "does not have method '%s'",
      MATCH_DOES    => "does not do '%s'",
      MATCH_BLESSED => "data blessed/unblessed",
      MATCH_PACKAGE => "data is/is not a package",
      MATCH_REF     => "is/is not a reference",
      MATCH_SMART   => "does not smart-match '%s'",
      MATCH_ISWEAK  => "weak/strong reference",
      MATCH_READONLY=> "readonly data",
      MATCH_TAINTED => "tainted/untainted",
    },
    Whatever => {
      MATCH_DEFINED => "data defined/undefined",
    },
    Num    => {INVALID => "invalid number",},
    Date   => {INVALID => "invalid date",},
    String => {
      TOO_SHORT        => "less than %d characters",
      TOO_LONG         => "more than %d characters",
      SHOULD_MATCH     => "should match '%s'",
      SHOULD_NOT_MATCH => "should not match '%s'",
    },
    Handle => {INVALID     => "is not an open filehandle"},
    Enum   => {NOT_IN_LIST => "not in enumeration list",},
    List => {
      NOT_A_LIST => "is not an arrayref",
      TOO_SHORT  => "less than %d items",
      TOO_LONG   => "more than %d items",
      ANY        => "should have at least one '%s'",
    },
    Struct => {
      NOT_A_HASH      => "is not a hashref",
      FORBIDDEN_FIELD => "contains forbidden field: '%s'"
    },
  },

  "français" => {
    Generic => {
      UNDEFINED     => "donnée non définie",
      INVALID       => "incorrect",
      TOO_SMALL     => "plus petit que le minimum '%s'",
      TOO_BIG       => "plus grand que le maximum '%s'",
      EXCLUSION_SET => "fait partie des valeurs interdites",
      MATCH_TRUE    => "donnée vraie/fausse",
      MATCH_ISA     => "n'est pas un  '%s'",
      MATCH_CAN     => "n'a pas la méthode '%s'",
      MATCH_DOES    => "ne se comporte pas comme un '%s'",
      MATCH_BLESSED => "donnée blessed/unblessed",
      MATCH_PACKAGE => "est/n'est pas un package",
      MATCH_REF     => "est/n'est pas une référence",
      MATCH_SMART   => "n'obéit pas au smart-match '%s'",
      MATCH_ISWEAK  => "référence weak/strong",
      MATCH_READONLY=> "donnée readonly",
      MATCH_TAINTED => "tainted/untainted",
    },
    Whatever => {
      MATCH_DEFINED => "donnée définie/non définie",
    },
    Num    => {INVALID => "nombre incorrect",},
    Date   => {INVALID => "date incorrecte",},
    String => {
      TOO_SHORT        => "moins de %d caractères",
      TOO_LONG         => "plus de %d caractères",
      SHOULD_MATCH     => "devrait être reconnu par la regex '%s'",
      SHOULD_NOT_MATCH => "ne devrait pas être reconnu par la regex '%s'",
    },
    Handle => {INVALID     => "n'est pas une filehandle ouverte"},
    Enum   => {NOT_IN_LIST => "n'appartient pas à la liste énumérée",},
    List => {
      NOT_A_LIST => "n'est pas une arrayref",
      TOO_SHORT  => "moins de %d éléments",
      TOO_LONG   => "plus de %d éléments",
      ANY        => "doit avoir au moins un '%s'",
    },
    Struct => {
      NOT_A_HASH      => "n'est pas une hashref",
      FORBIDDEN_FIELD => "contient le champ interdit: '%s'",
    },
  },
};

# inherit Int and Nat messages from Num messages
foreach my $language (keys %$builtin_msgs) {
  $builtin_msgs->{$language}{$_} = $builtin_msgs->{$language}{Num} 
    for qw/Int Nat/;
}

# default messages : english
my $global_msgs = $builtin_msgs->{english};

#----------------------------------------------------------------------
# PUBLIC METHODS
#----------------------------------------------------------------------

sub messages { # private class method
  my ($class, $new_messages) = @_;
  croak "messages() is a class method in Data::Domain" 
    if ref $class or $class ne 'Data::Domain';

  $global_msgs = (ref $new_messages) ? $new_messages 
                                     : $builtin_msgs->{$new_messages}
    or croak "no such builtin messages ($new_messages)";
}


sub inspect {
  my ($self, $data, $context) = @_;
  no warnings 'recursion';

  if (!defined $data) {
    # success if data was optional;
    return if $self->{-optional};

    # only the 'Whatever' domain can accept undef; other domains will fail
    return $self->msg(UNDEFINED => '')
      unless $self->isa("Data::Domain::Whatever");
  }
  else { # if $data is defined
    # check some general properties
    if (my $isa = $self->{-isa}) {
      try {$data->isa($isa)}
        or return $self->msg(MATCH_ISA => $isa);
    }
    if (my $role = $self->{-does}) {
      does($data, $role)
        or return $self->msg(MATCH_DOES => $role);
    }
    if (my $can = $self->{-can}) {
      $can = [$can] unless does($can, 'ARRAY');
      foreach my $method (@$can) {
        try {$data->can($method)}
          or return $self->msg(MATCH_CAN => $method);
      }
    }
    if (my $match_target = $self->{-matches}) {
      match::simple::match($data, $match_target)
        or return $self->msg(MATCH_SMART => $match_target);
    }
    if ($self->{-has}) {
      # EXPERIMENTAL: check methods results
      my @msgs = $self->_check_has($data, $context);
      return {HAS => \@msgs} if @msgs;
    }
    if (defined $self->{-blessed}) {
      return $self->msg(MATCH_BLESSED => $self->{-blessed})
        if Scalar::Util::blessed($data) xor $self->{-blessed};
    }
    if (defined $self->{-package}) {
      return $self->msg(MATCH_PACKAGE => $self->{-package})
        if (!ref($data) && $data->isa($data)) xor $self->{-package};
    }
    if (defined $self->{-isweak}) {
      return $self->msg(MATCH_ISWEAK => $self->{-isweak})
        if Scalar::Util::isweak($data) xor $self->{-isweak};
    }
    if (defined $self->{-readonly}) {
      return $self->msg(MATCH_READONLY => $self->{-readonly})
        if Scalar::Util::readonly($data) xor $self->{-readonly};
    }
    if (defined $self->{-tainted}) {
      return $self->msg(MATCH_TAINTED => $self->{-tainted})
        if Scalar::Util::readonly($data) xor $self->{-tainted};
    }
  }

  # properties that must be checked against both defined and undef data
  if (defined $self->{-true}) {
    return $self->msg(MATCH_TRUE => $self->{-true})
      if $data xor $self->{-true};
  }
  if (defined $self->{-ref}) {
    return $self->msg(MATCH_REF => $self->{-ref})
      if ref $data xor $self->{-ref};
  }

  # now call domain-specific _inspect()
  return $self->_inspect($data, $context)
}


sub _check_has {
  my ($self, $data, $context) = @_;

  my @msgs;
  my $iterator = natatime 2, @{$self->{-has}};
  while (my ($meth_to_call, $expectation) = $iterator->()) {
    my ($meth, @args) = does($meth_to_call, 'ARRAY') ? @$meth_to_call
                                                     : ($meth_to_call);
    my $msg;
    if (does($expectation, 'ARRAY')) {
      $msg = try   {my @result = $data->$meth(@args);
                    my $domain = List(@$expectation);
                    $domain->inspect(\@result)}
             catch {(my $error_msg = $_) =~ s/\bat\b.*//s; $error_msg};
    }
    else {
      $msg = try   {my $result = $data->$meth(@args);
                    $expectation->inspect($result)}
             catch {(my $error_msg = $_) =~ s/\bat\b.*//s; $error_msg};
    }
    push @msgs, $meth_to_call => $msg if $msg;
  }
  return @msgs;
}



sub _check_returns {
  my ($self, $data, $context) = @_;

  my @msgs;
  my $iterator = natatime 2, @{$self->{-returns}};
  while (my ($args, $expectation) = $iterator->()) {
    my $msg;
    if (does($expectation, 'ARRAY')) {
      $msg = try   {my @result = $data->(@$args);
                    my $domain = List(@$expectation);
                    $domain->inspect(\@result)}
             catch {(my $error_msg = $_) =~ s/\bat\b.*//s; $error_msg};
    }
    else {
      $msg = try   {my $result = $data->(@$args);
                    $expectation->inspect($result)}
             catch {(my $error_msg = $_) =~ s/\bat\b.*//s; $error_msg};
    }
    push @msgs, $args => $msg if $msg;
  }
  return @msgs;
}




#----------------------------------------------------------------------
# METHODS FOR INTERNAL USE
#----------------------------------------------------------------------


sub msg {
  my ($self, $msg_id, @args) = @_;
  my $msgs     = $self->{-messages};
  my $subclass = $self->subclass;
  my $name     = $self->{-name} || $subclass;
  my $msg;

  # if there is a user_defined message, return it
  if (defined $msgs) { 
    for (ref $msgs) {
      /^CODE/ and return $msgs->($msg_id, @args); # user function
      /^$/    and return "$name: $msgs";          # user constant string
      /^HASH/ and do { $msg =  $msgs->{$msg_id}   # user hash of msgs
                         and return sprintf "$name: $msg", @args;
                       last; # not found in this hash - revert to $global_msgs
                     };
      croak "invalid -messages option";           # otherwise
    }
  }

  # otherwise, try global messages
  return $global_msgs->($msg_id, @args)      if ref $global_msgs eq 'CODE';
  $msg = $global_msgs->{$subclass}{$msg_id}  # otherwise
      || $global_msgs->{Generic}{$msg_id}
     or croak "no error string for message $msg_id";

  # perl v5.22 and above warns if there are too many @args for sprintf.
  # The line below prevents that warning
  no if $] ge '5.022000', warnings => 'redundant';

  return sprintf "$name: $msg", @args;
}


sub subclass { # returns the class name without initial 'Data::Domain::'
  my ($self) = @_;
  my $class = ref($self) || $self;
  (my $subclass = $class) =~ s/^Data::Domain:://;
  return $subclass;
}


sub _expand_range {
  my ($self, $range_field, $min_field, $max_field) = @_;
  my $name = $self->{-name} || $self->subclass;

  # the range field will be replaced by min and max fields
  if (my $range = delete $self->{$range_field}) {
    for ($min_field, $max_field) {
      not defined $self->{$_}
        or croak  "$name: incompatible options: $range_field / $_";
    }
    does($range, 'ARRAY') and @$range == 2
      or croak  "$name: invalid argument for $range";
    @{$self}{$min_field, $max_field} = @$range;
  }
}


sub _check_min_max {
  my ($self, $min_field, $max_field, $cmp_func) = @_;

  # choose the appropriate comparison function
  if    ($cmp_func eq '<=')       {$cmp_func = sub {$_[0] <= $_[1]}}
  elsif ($cmp_func eq 'le')       {$cmp_func = sub {$_[0] le $_[1]}}
  elsif (does($cmp_func, 'CODE')) {} # already a coderef, do nothing
  else                            {croak "inappropriate cmp_func for _check_min_max"}

  # check that min is smaller than max
  my ($min, $max) = @{$self}{$min_field, $max_field};
  if (defined $min && defined $max) {
    $cmp_func->($min, $max)
      or croak $self->subclass . ": incompatible min/max values ($min/$max)";
  }
}


sub _build_subdomain {
  my ($self, $domain, $context) = @_;
  no warnings 'recursion';

  # avoid infinite loop
  @{$context->{path}} < $MAX_DEEP
    or croak "inspect() deepness exceeded $MAX_DEEP; "
           . "modify \$Data::Domain::MAX_DEEP if you need more";

  if (does($domain, 'Data::Domain')) {
    # already a domain, nothing to do
  }
  elsif (does($domain, 'CODE')) {
    # this is a lazy domain, need to call the coderef to get a real domain
    $domain = try   {$domain->($context)} 
      catch {   # remove "at source_file, line ..." from error message
        (my $error_msg = $_) =~ s/\bat\b.*//s;
        # return an empty domain that reports the error message
        Data::Domain::Empty->new(-name => "domain parameters",
                                 -messages => $error_msg);
      };
    # did we really get a domain ?
    does($domain, "Data::Domain")
      or croak "lazy domain coderef returned an invalid domain";
  }
  elsif (!ref $domain) {
    # this is a scalar, build a constant domain with that single value
    my $subclass = Scalar::Util::looks_like_number($domain) ? 'Num' : 'String';
    $domain = "Data::Domain::$subclass"->new(-min  => $domain,
                                             -max  => $domain,
                                             -name => "constant $subclass");
  }
  else {
    croak "unknown subdomain : $domain";
  }

  return $domain;
}


#----------------------------------------------------------------------
# UTILITY FUNCTIONS (NOT METHODS) 
#----------------------------------------------------------------------

# valid options for all subclasses
my @common_options = qw/-optional -name -messages
                        -true -isa -can -does -matches -ref
                        -has -returns
                        -blessed -package -isweak -readonly -tainted/;

sub _parse_args {
  my ($args_ref, $options_ref, $default_option, $arg_type) = @_;

  my %parsed;

  # parse named arguments
  while (@$args_ref and $args_ref->[0] =~ /^-/) {
    any {$args_ref->[0] eq $_} (@$options_ref, @common_options)
      or croak "invalid argument: $args_ref->[0]";
    my ($key, $val) = (shift @$args_ref, shift @$args_ref);
    $parsed{$key}  = $val;
  }

  # remaining arguments are mapped to the default option
  if (@$args_ref) {
    $default_option or croak "too many args to new()";
    not exists $parsed{$default_option}
      or croak "can't have default args if $default_option is set";
    $parsed{$default_option} 
      = $arg_type eq 'scalar'   ? $args_ref->[0]
      : $arg_type eq 'arrayref' ? $args_ref
      : croak "unknown type for default option: $arg_type";
  }

  return \%parsed;
}


sub node_from_path {
  my ($root, $path0, @path) = @_;
  return $root if not defined $path0;
  return undef if not defined $root;
  return node_from_path($root->{$path0}, @path) 
    if does($root, 'HASH');
  return node_from_path($root->[$path0], @path) 
    if does($root, 'ARRAY');

  # otherwise
  croak "node_from_path: incorrect root/path";
}


#----------------------------------------------------------------------
# implementation for overloaded operators
#----------------------------------------------------------------------
sub _matches {
  my ($self, $data, $call_order) = @_;
  $Data::Domain::MESSAGE = $self->inspect($data);
  return !$Data::Domain::MESSAGE; # smart match successful if no error message
}

sub _stringify {
  my ($self) = @_;
  my $dumper = Data::Dumper->new([$self])->Indent(0)->Terse(1);
  return $dumper->Dump;
}



#======================================================================
package Data::Domain::Whatever;
#======================================================================
use strict;
use warnings;
use Carp;
use Scalar::Does qw/does/;
our @ISA = 'Data::Domain';

sub new {
  my $class   = shift;
  my @options = qw/-defined/;
  my $self    = Data::Domain::_parse_args( \@_, \@options );
  bless $self, $class;

  not ($self->{-defined } && $self->{-optional})
    or croak "both -defined and -optional: meaningless!";

  return $self;
}

sub _inspect {
  my ($self, $data) = @_;

  if (defined $self->{-defined}) {
    return $self->msg(MATCH_DEFINED => $self->{-defined})
      if defined($data) xor $self->{-defined};
  }

  # otherwise, success
  return;
}


#======================================================================
package Data::Domain::Empty;
#======================================================================
use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

sub new {
  my $class   = shift;
  my @options = ();
  my $self    = Data::Domain::_parse_args( \@_, \@options );
  bless $self, $class;
}

sub _inspect {
  my ($self, $data) = @_;

  return $self->msg(INVALID => ''); # always fails
}


#======================================================================
package Data::Domain::Num;
#======================================================================
use strict;
use warnings;
use Carp;
use Scalar::Util qw/looks_like_number/;
use Try::Tiny;

our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = qw/-range -min -max -not_in/;
  my $self = Data::Domain::_parse_args(\@_, \@options);
  bless $self, $class;

  $self->_expand_range(qw/-range -min -max/);
  $self->_check_min_max(qw/-min -max <=/);

  if ($self->{-not_in}) {
    try {my $vals = $self->{-not_in};
          @$vals > 0 and not grep {!looks_like_number($_)} @$vals}
      or croak "-not_in : needs an arrayref of numbers";
  }

  return $self;
}

sub _inspect {
  my ($self, $data) = @_;

  looks_like_number($data) 
    or return $self->msg(INVALID => $data);

  if (defined $self->{-min}) {
    $data >= $self->{-min} 
      or return $self->msg(TOO_SMALL => $self->{-min});
  }
  if (defined $self->{-max}) {
    $data <= $self->{-max} 
      or return $self->msg(TOO_BIG => $self->{-max});
  }
  if (defined $self->{-not_in}) {
    grep {$data == $_} @{$self->{-not_in}}
      and return $self->msg(EXCLUSION_SET => $data);
  }

  return;
}


#======================================================================
package Data::Domain::Int;
#======================================================================
use strict;
use warnings;

our @ISA = 'Data::Domain::Num';

sub _inspect {
  my ($self, $data) = @_;

  defined($data) and $data =~ /^-?\d+$/
    or return $self->msg(INVALID => $data);
  return $self->SUPER::_inspect($data);
}


#======================================================================
package Data::Domain::Nat;
#======================================================================
use strict;
use warnings;

our @ISA = 'Data::Domain::Num';

sub _inspect {
  my ($self, $data) = @_;

  defined($data) and $data =~ /^\d+$/
    or return $self->msg(INVALID => $data);
  return $self->SUPER::_inspect($data);
}


#======================================================================
package Data::Domain::String;
#======================================================================
use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = qw/-regex -antiregex
                   -range -min -max 
                   -length -min_length -max_length 
                   -not_in/;
  my $self = Data::Domain::_parse_args(\@_, \@options, -regex => 'scalar');
  bless $self, $class;

  $self->_expand_range(qw/-range -min -max/);
  $self->_check_min_max(qw/-min -max le/);

  $self->_expand_range(qw/-length -min_length -max_length/);
  $self->_check_min_max(qw/-min_length -max_length <=/);

  return $self;
}

sub _inspect {
  my ($self, $data) = @_;

  # $data must be Unref or obj with a stringification method
  !ref($data) || overload::Method($data, '""')
    or return $self->msg(INVALID => $data);
  if ($self->{-min_length}) {
    length($data) >= $self->{-min_length} 
      or return $self->msg(TOO_SHORT => $self->{-min_length});
  }
  if (defined $self->{-max_length}) {
    length($data) <= $self->{-max_length} 
      or return $self->msg(TOO_LONG => $self->{-max_length});
  }
  if ($self->{-regex}) {
    $data =~ $self->{-regex}
      or return $self->msg(SHOULD_MATCH => $self->{-regex});
  }
  if ($self->{-antiregex}) {
    $data !~ $self->{-antiregex}
      or return $self->msg(SHOULD_NOT_MATCH => $self->{-antiregex});
  }
  if (defined $self->{-min}) {
    $data ge $self->{-min} 
      or return $self->msg(TOO_SMALL => $self->{-min});
  }
  if (defined $self->{-max}) {
    $data le $self->{-max} 
      or return $self->msg(TOO_BIG => $self->{-max});
  }
  if ($self->{-not_in}) {
    grep {$data eq $_} @{$self->{-not_in}}
      and return $self->msg(EXCLUSION_SET => $data);
  }

  return;
}


#======================================================================
package Data::Domain::Date;
#======================================================================
use strict;
use warnings;
use Carp;
use Try::Tiny;
our @ISA = 'Data::Domain';


use autouse 'Date::Calc' => qw/Decode_Date_EU Decode_Date_US Date_to_Text
                               Delta_Days  Add_Delta_Days Today check_date/;

my $date_parser = \&Decode_Date_EU;

#----------------------------------------------------------------------
# utility functions 
#----------------------------------------------------------------------
sub _print_date {
  my $date = shift;
  $date = _expand_dynamic_date($date);
  return Date_to_Text(@$date);
}


my $dynamic_date = qr/^(today|yesterday|tomorrow)$/;

sub _expand_dynamic_date {
  my $date = shift;
  if (not ref $date) {
    $date = {
      today     => [Today], 
      yesterday => [Add_Delta_Days(Today, -1)],
      tomorrow  => [Add_Delta_Days(Today, +1)]
     }->{$date} or croak "unexpected date : $date";
  }
  return $date;
}

sub _date_cmp {
  my ($d1, $d2) = map {_expand_dynamic_date($_)} @_;
  return -Delta_Days(@$d1, @$d2);
}


#----------------------------------------------------------------------
# public API
#----------------------------------------------------------------------

sub parser {
  my ($class, $new_parser) = @_;
  not ref $class or croak "Data::Domain::Date::parser is a class method";

  $date_parser = 
    (ref $new_parser eq 'CODE')
    ? $new_parser
    : {US => \&Decode_Date_US,
       EU => \&Decode_Date_EU}->{$new_parser}
    or croak "unknown date parser : $new_parser";
  return $date_parser;
}


sub new {
  my $class   = shift;
  my @options = qw/-range -min -max -not_in/;
  my $self    = Data::Domain::_parse_args(\@_, \@options);
  bless $self, $class;

  $self->_expand_range(qw/-range -min -max/);

  # parse date boundaries into internal representation (arrayrefs)
  for my $bound (qw/-min -max/) {
    if ($self->{$bound} and $self->{$bound} !~ $dynamic_date) {
      my @date = $date_parser->($self->{$bound})
        or croak "invalid date ($bound): $self->{$bound}";
      $self->{$bound} = \@date;
    }
  }

  # check order of boundaries
  $self->_check_min_max(qw/-min -max/, sub {_date_cmp($_[0], $_[1]) <= 0});

  # parse dates in the exclusion set into internal representation
  if ($self->{-not_in}) {
    my @excl_dates;
    try {
      foreach my $date (@{$self->{-not_in}}) {
        if ($date =~ $dynamic_date) {
          push @excl_dates, $date;
        }
        else {
          my @parsed_date = $date_parser->($date) or die "wrong date";
          push @excl_dates, \@parsed_date;
        }
      }
      @excl_dates > 0;
    }
      or croak "-not_in : needs an arrayref of dates";
    $self->{-not_in} = \@excl_dates;
  }

  return $self;
}


sub _inspect {
  my ($self, $data) = @_;

  my @date = try {$date_parser->($data)};
  @date && check_date(@date)
    or return $self->msg(INVALID => $data);

  if (defined $self->{-min}) {
    my $min = _expand_dynamic_date($self->{-min});
    !check_date(@$min) || (_date_cmp(\@date, $min) < 0)
      and return $self->msg(TOO_SMALL => _print_date($self->{-min}));
  }

  if (defined $self->{-max}) {
    my $max = _expand_dynamic_date($self->{-max});
    !check_date(@$max) || (_date_cmp(\@date, $max) > 0)
      and return $self->msg(TOO_BIG => _print_date($self->{-max}));
  }

  if ($self->{-not_in}) {
    grep {_date_cmp(\@date, $_) == 0} @{$self->{-not_in}}
      and return $self->msg(EXCLUSION_SET => $data);
  }

  return;
}


#======================================================================
package Data::Domain::Time;
#======================================================================
use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

my $time_regex = qr/^(\d\d?):?(\d\d?)?:?(\d\d?)?$/;

sub _valid_time {
  my ($h, $m, $s) = @_;
  $m ||= 0;
  $s ||= 0;
  return ($h <= 23 && $m <= 59 && $s <= 59);
}


sub _expand_dynamic_time {
  my $time = shift;
  if (not ref $time) {
    $time eq 'now' or croak "unexpected time : $time";
    $time = [(localtime)[2, 1, 0]];
  }
  return $time;
}


sub _time_cmp {
  my ($t1, $t2) = map {_expand_dynamic_time($_)} @_;

  return  $t1->[0]       <=>  $t2->[0]        # hours
      || ($t1->[1] || 0) <=> ($t2->[1] || 0)  # minutes
      || ($t1->[2] || 0) <=> ($t2->[2] || 0); # seconds
}

sub _print_time {
  my $time = _expand_dynamic_time(shift);
  return sprintf "%02d:%02d:%02d", map {$_ || 0} @$time;
}


sub new {
  my $class = shift;
  my @options = qw/-range -min -max/;
  my $self = Data::Domain::_parse_args(\@_, \@options);
  bless $self, $class;

  $self->_expand_range(qw/-range -min -max/);

  # parse time boundaries
  for my $bound (qw/-min -max/) {
    if ($self->{$bound} and $self->{$bound} ne 'now') {
      my @time = ($self->{$bound} =~ $time_regex);
      @time && _valid_time(@time)
        or croak "invalid time ($bound): $self->{$bound}";
      $self->{$bound} = \@time;
    }
  }

  # check order of boundaries
  $self->_check_min_max(qw/-min -max/, sub {_time_cmp($_[0], $_[1]) <= 0});

  return $self;
}


sub _inspect {
  my ($self, $data) = @_;

  my @t = ($data =~ $time_regex);
  @t and _valid_time(@t)
    or return $self->msg(INVALID => $data);

  if (defined $self->{-min}) {
    _time_cmp(\@t, $self->{-min}) < 0
      and return $self->msg(TOO_SMALL => _print_time($self->{-min}));
  }

  if (defined $self->{-max}) {
    _time_cmp(\@t, $self->{-max}) > 0
      and return $self->msg(TOO_BIG => _print_time($self->{-max}));
  }

  return;
}



#======================================================================
package Data::Domain::Handle;
#======================================================================
use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = ();
  my $self = Data::Domain::_parse_args(\@_, \@options);
  bless $self, $class;
}

sub _inspect {
  my ($self, $data) = @_;
  Scalar::Util::openhandle($data)
    or return $self->msg(INVALID => '');

  return; # otherwise OK, no error
}




#======================================================================
package Data::Domain::Enum;
#======================================================================
use strict;
use warnings;
use Carp;
use Try::Tiny;
our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = qw/-values/;
  my $self = Data::Domain::_parse_args(\@_, \@options, -values => 'arrayref');
  bless $self, $class;

  try {@{$self->{-values}}} or croak "Enum : incorrect set of values";

  not grep {! defined $_} @{$self->{-values}}
    or croak "Enum : undefined element in values";

  return $self;
}


sub _inspect {
  my ($self, $data) = @_;

  return $self->msg(NOT_IN_LIST => $data)
    if not grep {$_ eq $data} @{$self->{-values}};

  return; # otherwise OK, no error
}


#======================================================================
package Data::Domain::List;
#======================================================================
use strict;
use warnings;
use Carp;
use List::MoreUtils qw/all/;
use Scalar::Does qw/does/;
our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = qw/-items -size -min_size -max_size -any -all/;
  my $self = Data::Domain::_parse_args(\@_, \@options, -items => 'arrayref');
  bless $self, $class;

  $self->_expand_range(qw/-size -min_size -max_size/);
  $self->_check_min_max(qw/-min_size -max_size <=/);

  if ($self->{-items}) {
    does($self->{-items}, 'ARRAY')
      or croak "invalid -items for Data::Domain::List";

    # if -items is given, then both -{min,max}_size cannot be shorter
    for my $bound (qw/-min_size -max_size/) {
      croak "$bound does not match -items"
      if $self->{$bound} and $self->{$bound} < @{$self->{-items}};
    }
  }

  # check that -all or -any are domains or lists of domains
  for my $arg (qw/-all -any/) {
    if (my $dom = $self->{$arg}) {
      $dom = [$dom] unless does($dom, 'ARRAY');
      all {does($_, 'Data::Domain') || does($_, 'CODE')} @$dom
        or croak "invalid arg to $arg in Data::Domain::List";
    }
  }

  return $self;
}


sub _inspect {
  my ($self, $data, $context) = @_;
  no warnings 'recursion';

  does($data, 'ARRAY')
    or return $self->msg(NOT_A_LIST => $data);

  if (defined $self->{-min_size} && @$data < $self->{-min_size}) {
    return $self->msg(TOO_SHORT => $self->{-min_size});
  }

  if (defined $self->{-max_size} && @$data > $self->{-max_size}) {
    return $self->msg(TOO_LONG => $self->{-max_size});
  }

  return unless $self->{-items} || $self->{-all} || $self->{-any};

  # prepare context for calling lazy subdomains
  $context ||= {root => $data,
                flat => {},
                path => []};
  local $context->{list} = $data;

  # initializing some variables
  my @msgs;
  my $has_invalid;
  my $items   = $self->{-items} || [];
  my $n_items = @$items;
  my $n_data  = @$data;

  # check the -items conditions
  for (my $i = 0; $i < $n_items; $i++) {
    local $context->{path} = [@{$context->{path}}, $i];
    my $subdomain  = $self->_build_subdomain($items->[$i], $context)
      or next;
    $msgs[$i]      = $subdomain->inspect($data->[$i], $context);
    $has_invalid ||= $msgs[$i];
  }

  # check the -all condition (can be a single domain or an arrayref of domains)
  if (my $all = $self->{-all}) {
    $all = [$all] unless does($all, 'ARRAY');
    my $n_all = @$all;
    for (my $i = $n_items, my $j = 0; # $i iterates over @$data, $j over @$all
         $i < $n_data;
         $i++, $j = ($j + 1) % $n_all) {
      local $context->{path} = [@{$context->{path}}, $i];
      my $subdomain  = $self->_build_subdomain($all->[$j], $context);
      $msgs[$i]      = $subdomain->inspect($data->[$i], $context);
      $has_invalid ||= $msgs[$i];
    }
  }

  # stop here if there was any error message
  return \@msgs if $has_invalid; 

  # all other conditions were good, now check the "any" conditions
  if (my $any = $self->{-any}) {
    $any = [$any] unless does($any, 'ARRAY');

    # there must be data to inspect
    $n_data > $n_items
      or return $self->msg(ANY => ($any->[0]{-name} || $any->[0]->subclass));

    # inspect the remaining data for all 'any' conditions
  CONDITION:
    foreach my $condition (@$any) {
      my $subdomain;
      for (my $i = $n_items; $i < $n_data; $i++) {
        local $context->{path} = [@{$context->{path}}, $i];
        $subdomain = $self->_build_subdomain($condition, $context);
        my $error  = $subdomain->inspect($data->[$i], $context);
        next CONDITION if not $error;
      }
      return $self->msg(ANY => ($subdomain->{-name} || $subdomain->subclass));
    }
  }

  return; # OK, no error
}


#======================================================================
package Data::Domain::Struct;
#======================================================================
use strict;
use warnings;
use experimental 'smartmatch';
use Carp;
use Scalar::Does qw/does/;
our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = qw/-fields -exclude -keys -values/;
  my $self = Data::Domain::_parse_args(\@_, \@options, -fields => 'arrayref');
  bless $self, $class;

  my $fields = $self->{-fields} || [];
  if (does($fields, 'ARRAY')) {
    # transform arrayref into hashref plus an ordered list of keys
    $self->{-fields_list} = [];
    $self->{-fields}      = {};
    for (my $i = 0; $i < @$fields; $i += 2) {
      my ($key, $val) = ($fields->[$i], $fields->[$i+1]);
      push @{$self->{-fields_list}}, $key;
      $self->{-fields}{$key} = $val;
    }
  }
  elsif (does($fields, 'HASH')) {
    # keep given hashref, add list of keys
    $self->{-fields_list} = [keys %$fields];
  }
  else {
    croak "invalid data for -fields option";
  }

  # check that -exclude is an arrayref or a regex or a string
  if (my $exclude = $self->{-exclude}) {
    does($exclude, 'ARRAY') || does($exclude, 'Regexp') || !ref($exclude)
      or croak "invalid data for -exclude option";
  }


  # check that -keys or -values are List domains
  for my $arg (qw/-keys -values/) {
    if (my $dom = $self->{$arg}) {
      does($dom, 'Data::Domain::List') or does($dom, 'CODE')
        or croak "$arg in Data::Domain::Struct should be a List domain";
    }
  }

  return $self;
}


sub _inspect {
  my ($self, $data, $context) = @_;
  no warnings 'recursion';

  # check that $data is a hashref
  does($data, 'HASH')
    or return $self->msg(NOT_A_HASH => $data);

  # check if there are any forbidden fields
  if (my $exclude = $self->{-exclude}) {
  FIELD:
    foreach my $field (keys %$data) {
      next FIELD if $self->{-fields}{$field};

      return $self->msg(FORBIDDEN_FIELD => $field)
        if match::simple::match($field, $exclude)
        or match::simple::match($exclude, ['*', 'all']);
    }
  }

  my %msgs;
  my $has_invalid;

  # prepare context for calling lazy subdomains
  $context ||= {root => $data,
                flat => {},
                list => [],
                path => []};
  local $context->{flat} = {%{$context->{flat}}, %$data};

  # check fields of the domain
  foreach my $field (@{$self->{-fields_list}}) {
    local $context->{path} = [@{$context->{path}}, $field];
    my $field_spec = $self->{-fields}{$field};
    my $subdomain  = $self->_build_subdomain($field_spec, $context);
    my $msg        = $subdomain->inspect($data->{$field}, $context);
    $msgs{$field}  = $msg if $msg;
    $has_invalid ||=  $msg;
  }

  # check the List domain for keys
  if (my $keys_dom = $self->{-keys}) {
    local $context->{path} = [@{$context->{path}}, "-keys"];
    my $subdomain  = $self->_build_subdomain($keys_dom, $context);
    $msgs{-keys}   = $subdomain->inspect([keys %$data], $context)
      and $has_invalid = 1;
  }

  # check the List domain for values
  if (my $values_dom = $self->{-values}) {
    local $context->{path} = [@{$context->{path}}, "-values"];
    my $subdomain  = $self->_build_subdomain($values_dom, $context);
    $msgs{-values} = $subdomain->inspect([values %$data], $context)
      and $has_invalid = 1;
  }

  return $has_invalid ? \%msgs : undef;
}

#======================================================================
package Data::Domain::One_of;
#======================================================================
use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = qw/-options/;
  my $self = Data::Domain::_parse_args(\@_, \@options, -options => 'arrayref');
  bless $self, $class;

  Scalar::Does::does($self->{-options}, 'ARRAY')
    or croak "One_of: invalid options";

  return $self;
}


sub _inspect {
  my ($self, $data, $context) = @_;
  my @msgs;
  no warnings 'recursion';

  for my $subdomain (@{$self->{-options}}) {
    my $msg = $subdomain->inspect($data, $context)
      or return; # $subdomain was successful
    push @msgs, $msg;
  }
  return \@msgs;
}


#======================================================================
package Data::Domain::All_of;
#======================================================================
use strict;
use warnings;
use Carp;
our @ISA = 'Data::Domain';

sub new {
  my $class = shift;
  my @options = qw/-options/;
  my $self = Data::Domain::_parse_args(\@_, \@options, -options => 'arrayref');
  bless $self, $class;

  Scalar::Does::does($self->{-options}, 'ARRAY')
    or croak "All_of: invalid options";

  return $self;
}


sub _inspect {
  my ($self, $data, $context) = @_;
  my @msgs;
  no warnings 'recursion';

  for my $subdomain (@{$self->{-options}}) {
    my $msg = $subdomain->inspect($data, $context);
    push @msgs, $msg if $msg; # subdomain failed
  }
  return @msgs ? \@msgs : undef;
}


#======================================================================
1;


__END__

=encoding ISO8859-1

=head1 NAME

Data::Domain - Data description and validation

=head1 SYNOPSIS

  use Data::Domain qw/:all/;

  # some basic domains
  my $int_dom      = Int(-min => 3, -max => 18);
  my $nat_dom      = Nat(-max => 100); # natural numbers
  my $num_dom      = Num(-min => 3.33, -max => 18.5);
  my $string_dom   = String(-min_length => 2, -optional => 1);
  my $handle_dom   = Handle;
  my $enum_dom     = Enum(qw/foo bar buz/);
  my $int_list_dom = List(-min_size => 1, -all => Int);
  my $mixed_list   = List(String, Int(-min => 0), Date, True, Defined);
  my $struct_dom   = Struct(foo => String, bar => Int(-optional => 1));
  my $obj_dom      = Obj(-can => 'print');
  my $class_dom    = Class(-can => 'print');

  # using the domain to check data
  my $error_messages = $domain->inspect($some_data);
  reject_form($error_messages) if $error_messages;

  # custom name and custom messages (2 different ways)
  $domain = Int(-name => 'age', -min => 3, -max => 18, 
                -messages => "only for people aged 3-18");
  $domain = Int(-name => 'age', -min => 3, -max => 18, -messages => {
                   TOO_BIG   => "not for old people over %d",
                   TOO_SMALL => "not for babies under %d",
                 });

  # examples of subroutines for specialized domains
  sub Phone   { String(-regex    => qr/^\+?[0-9() ]+$/, 
                       -messages => "Invalid phone number", @_) }
  sub Email   { String(-regex    => qr/^[-.\w]+\@[\w.]+$/,
                       -messages => "Invalid email", @_) }
  sub Contact { Struct(-fields => [name   => String,
                                   phone  => Phone,
                                   mobile => Phone(-name => 'Mobile',
                                                   -optional => 1),
                                   emails => List(-all => Email)   ], @_) }

  # lazy subdomain
  $domain = Struct(
    date_begin => Date(-max => 'today'),
    date_end   => sub {my $context = shift;
                       Date(-min => $context->{flat}{date_begin})},
  );

  # recursive domain
  my $expr_domain;
  $expr_domain = One_of(Num, Struct(operator => String(qr(^[-+*/]$)),
                                    left     => sub {$expr_domain},
                                    right    => sub {$expr_domain}));

  # constants in deep datastructures
  $domain = Struct( foo => 123,                     # 123   becomes a domain
                    bar => List(Int, 'buz', Int) ); # 'buz' becomes a domain

  # list with repetitive structure (here : triples)
  my $domain = List(-all => [String, Int, Obj(-can => 'print')]);

=head1 DESCRIPTION

A data domain is a description of a set of values, either scalar or
structured (arrays or hashes).  The description can include many
constraints, like minimal or maximal values, regular expressions,
required fields, forbidden fields, and also contextual
dependencies. From that description, one can then invoke the domain's
C<inspect> method to check if a given value belongs to the domain or
not. In case of mismatch, a structured set of error messages is
returned, giving detailed explanations about what was wrong.

The motivation for writing this package was to be able to express in a
compact way some possibly complex constraints about structured
data. Typically the data is a Perl tree (nested hashrefs or arrayrefs)
that may come from XML, L<JSON|JSON>, from a database through
L<DBIx::DataModel|DBIx::DataModel>, or from postprocessing an HTML
form through L<CGI::Expand|CGI::Expand>. C<Data::Domain> is a kind of
tree parser on that structure, with some facilities for dealing with
dependencies within the structure, and with several options to
finely tune the error messages returned to the user.

The main usage for C<Data::Domain> is to check input from forms in
interactive applications : the structured error messages make it easy
to display a form again, highlighting which fields were rejected and
why. Another usage is for writing automatic tests, with the help of
the companion module L<Test::InDomain>.

There are several other packages in CPAN doing data validation; these
are briefly listed in the L</"SEE ALSO"> section.

=head1 EXPORTS

=head2 Domain constructors

  use Data::Domain qw/:all/;
  # or
  use Data::Domain qw/:constructors/;
  # or
  use Data::Domain qw/Whatever Empty
                      Num Int Nat Date Time String
                      Enum List Struct One_of All_of/;

Internally, domains are represented as Perl objects; however, it would
be tedious to write

  my $domain = Data::Domain::Struct->new(
    anInt => Data::Domain::Int->new(-min => 3, -max => 18),
    aDate => Data::Domain::Date->new(-max => 'today'),
    ...
  );

so for each of its builtin domain constructors, C<Data::Domain>
exports a plain function that just calls C<new> on the appropriate
subclass; these functions are all exported in in a group called
C<:constructors>, and allow us to write more compact code :

  my $domain = Struct(
    anInt => Int(-min => 3, -max => 18),
    aDate => Date(-max => 'today'),
    ...
  );

The list of available domain constructors will be expanded below
in L</"BUILTIN DOMAIN CONSTRUCTORS">.

=head2 Shortcuts (domains with predefined options)

  use Data::Domain qw/:all/;
  # or
  use Data::Domain qw/:shortcuts/;
  # or
  use Data::Domain qw/True False Defined Undef Blessed Unblessed Regexp
                      Obj Class/;

The C<:shortcuts> export group contains a number of convenience
functions that call the L</Whatever> domain constructor with
various pre-built options. Precise definitions for each of these
functions will be given below in L</"BUILTIN SHORTCUTS">.

=head2 Renaming imported functions

Short function names like C<Int>, C<String>, C<List>, C<Obj>, C<True>, etc.
are convenient but may cause name clashes with other modules. Thanks to the
powerful features of L<Sub::Exporter>, these functions can be renamed
in various ways. Here is an example :

  use Data::Domain -all => { -prefix => 'dom_' };
  my $domain = dom_Struct(
    anInt => dom_Int(-min => 3, -max => 18),
    aDate => dom_Date(-max => 'today'),
    ...
  );

There are a number of other ways to rename imported functions; see
L<Sub::Exporter> and L<Sub::Exporter::Tutorial>.

=head2 Removing symbols from the import list

To preserve backwards compatibility with L<Exporter>, the present
module also supports exclamation marks to exclude some specific symbols
from the import list. For example

  use Data::Domain qw/:all !Date/;

will import everything except the C<Date> function.



=head1 METHODS COMMON TO ALL DOMAINS

=head2 new

The C<new> method creates a new domain object, from one of the domain
constructors listed below (C<Num>, C<Int>, C<Date>, etc.).  The
C<Data::Domain> class itself has no C<new> method, because it is an
abstract class.

This method is seldom called explicitly; it is usually more
convenient to use the wrapper subroutines introduced above, i.e. to
write C<< Int(@args) >> instead of C<< Data::Domain::Int->new(@args) >>.
All examples below will use this shorter notation.

Arguments to the C<new> method may specify various options for the
domain to be constructed.  Option names always start with a dash. If
no option name is given, parameters to the C<new> method are passed to
the I<default option> defined in each constructor subclass. For
example the default option in C<Data::Domain::List> is C<-items>, so

   my $domain = List(Int, String, Int);

is equivalent to

   my $domain = List(-items => [Int, String, Int]);

So in short, the "default option" is syntactic sugar for using positional
parameters instead of named parameters.

Each domain constructor has its own list of available options; these will be
presented below, together with each subclass (for example options for
setting minimal/maximal values, regular expressions, string length,
etc.).  However, there are also some generic options, available in
every domain constructor; these are listed here, in several categories.

=head3 Options for customizing the domain behaviour

=over

=item C<-optional>

If true, the domain will accept C<undef>, without generating an
error message.

=item C<-name>

Defines a name for the domain, that will be printed in error
messages instead of the subclass name.

=item C<-messages>

Defines ad hoc messages for that domain, instead of the builtin
messages. The argument can be a string, a hashref or a coderef,
as explained in the  L</"CUSTOMIZING ERROR MESSAGES"> section.

=back


=head3 Options for checking boolean properties

Options in this category check if the data possesses, or does not
possess, a given property; hence, the argument to each option must be
a boolean. For example, here is a domain that accepts all blessed
objects that are not weak references and are not readonly :

  $domain = Whatever(-blessed => 1, -weak => 0, -readonly => 0);

Boolean property options are :

=over

=item C<-true>

Checks if the data is true.

=item C<-blessed>

Checks if the data is blessed, according to L<Scalar::Util/blessed>.

=item C<-package>

Checks if the data is a package. This is considered true whenever
the data is not a reference and satisfies C<< $data->isa($data) >>.

=item C<-ref>

Checks if the data is a reference.

=item C<-isweak>

Checks if the data is a weak reference, according to L<Scalar::Util/isweak>.

=item C<-readonly>

Checks if the data is readonly, according to L<Scalar::Util/readonly>.

=item C<-tainted>

Checks if the data is tainted, according to L<Scalar::Util/tainted>.

=back


=head3 Options for checking other general properties

Options in this category do not take a boolean argument, but
a class name, method name, role or smart match operand.

=over

=item C<-isa>

Checks if the data is an object or a subclass of the specified class;
this is checked through C<< eval {$data->isa($class)} >>.

=item C<-can>

Checks if the data implements the listed methods, supplied either
as an arrayref (several methods) or as a scalar (just one method);
this is checked through C<< eval {$data->can($method)} >>.

=item C<-does>

Checks if the data does the supplied role; this is checked
through L<Scalar::Does>.

=item C<-matches>

Deprecated. Was used to check if the data smart matches the supplied right operand
(i.e. C<< $data ~~ $domain->{-matches} >>).

=back

=head3 EXPERIMENTAL: options for checking return values

B<Disclaimer>: options in this section are still experimental; the call 
API or structure of returned values might change in future
versions of C<Data::Domain>.

These options call methods or coderefs within the data, and
then check the results against the supplied domains. This is
somehow contrary to the principle of "domains", because a function
call or method call not only inspects the data : I<it might also
alter the data>. However, one could also argue that peeking into
an object's internals is contrary to the principle of encapsulation,
so in this sense, method calls are more appropriate. You decide ...
but beware of side-effects in your data!


=over

=item C<-has>

  $domain = Obj(-has => [
     foo          => String,               # ->foo() must return a String
     foo          => [-all => String],     # ->foo() in list context must
                                           # return a list of Strings
     [bar => 123] => Obj(-can => 'print'), # ->bar(123) must return a printable obj
   ]);

The C<-has> option takes an arrayref argument; that arrayref must
contain pairs of C<< ($method_spec => $expected_result) >>, where

=over

=item *

C<$method_spec> is either a method name, or an arrayref containing
the method name followed by the list of arguments for calling the method.

=item *

C<$expected_result> is either a domain, or an arrayref containing
arguments for a C<< List(...) >> domain. In the former case, the method
call will be performed in scalar context; in the latter case, it will
be performed in list context, and the resulting list will be checked
against a C<List> domain built from the given arguments.

=back

Note that this property can be invoked not only on C<Obj>, but on
any domain; hence, it is possible to simultaneously check if an object
has some given internal structure, and also answers to some method calls :

  $domain = Struct(              # must be a hashref
    -fields => {foo => String}   # must have a {foo} key with a String value
    -has    => [foo => String],  # must have a ->foo method that returns a String
   );


=item C<-returns>

  $domain = Whatever(-returns => [
     []         => String,
     [123, 456] => Int,
   ]);

The C<-returns> option treats the data as a coderef.
It takes an arrayref argument; that arrayref must
contain pairs of C<< ($call_spec => $expected_result) >>, where

=over

=item *

C<$call_spec> is an arrayref containing
the list of arguments for calling the subroutine.

=item *

C<$expected_result> is either a domain, or an arrayref containing
arguments for a C<< List(...) >> domain. In the former case, the method
call will be performed in scalar context; in the latter case, it will
be performed in list context.

=back

=back


=head2 inspect

  my $messages = $domain->inspect($some_data);

This method inspects the supplied data, and returns an error message
(or a structured collection of messages) if anything is wrong.
If the data successfully passed all domain tests, the method
returns C<undef>.

For scalar domains (C<Num>, C<String>, etc.), the error message
is just a string. For structured domains (C<List>, C<Struct>),
the return value is an arrayref or hashref of the same structure, like
for example

  {anInt => "smaller than mimimum 3",
   aDate => "not a valid date",
   aList => ["message for item 0", undef, undef, "message for item 3"]}

The client code can then exploit this structure to dispatch
error messages to appropriate locations (like for example the form
fields from which the data was gathered).

=head2 stringification

When printed, domains stringify to a compact L<Data::Dumper> representation
of their internal attributes; these details can be useful for debugging or
logging purposes.


=head1 BUILTIN DOMAIN CONSTRUCTORS

=head2 Whatever

  my $just_anything = Whatever;
  my $is_defined    = Whatever(-defined => 1);
  my $is_undef      = Whatever(-defined => 0);
  my $is_true       = Whatever(-true => 1);
  my $is_false      = Whatever(-true => 0);
  my $is_of_class   = Whatever(-isa  => 'Some::Class');
  my $does_role     = Whatever(-does => 'Some::Role');
  my $has_methods   = Whatever(-can  => [qw/jump swim dance sing/]);

The C<Data::Domain::Whatever> domain can contain any kind of Perl
value, including C<undef> (actually this is the only domain that
contains C<undef>). The only specific option is :

=over

=item -defined

If true, the data must be defined. If false, the data must be undef.

=back

The C<Whatever> is mostly used together with some of the general
options described above, like C<-true>, C<-does>, C<-can>, etc.


=head2 Empty

The C<Data::Domain::Empty> domain always fails when inspecting any data.
This is sometimes useful within lazy constructors, like in this example :

  Struct(
    foo => String,
    bar => sub {
      my $context = shift;
      if (some_condition($context)) { 
        return Empty(-messages => 'your data is wrong')
      }
      else {
        ...
      }
    }
  )

The L<"LAZY CONSTRUCTORS"|/"LAZY CONSTRUCTORS (CONTEXT DEPENDENCIES)">
section gives more explanations about lazy domains.

=head2 Num

  my $domain = Num(-range =>[-3.33, 999], -not_in => [2, 3, 5, 7, 11]);

Domain for numbers (including floats). Numbers are
recognized through L<Scalar::Util/looks_like_number>.
Options for the domain are :

=over

=item -min

The data must be greater or equal to the supplied value.

=item -max

The data must be smaller or equal to the supplied value.

=item -range

C<< -range => [$min, $max] >> is equivalent to 
C<< -min => $min, -max => $max >>.

=item -not_in

The data must be different from all values in the exclusion set,
supplied as an arrayref.

=back


=head2 Int

  my $domain = Int(-min => -999, -max => 999, -not_in => [2, 3, 5, 7, 11]);

Domain for integers. Integers are recognized through the regular
expression C</^-?\d+$/>.  This domain accepts the same options as
C<Num> and returns the same error messages.


=head2 Nat

  my $domain = Nat(-max => 999);

Domain for natural numbers (i.e. positive integers).
Natural numbers are recognized through the regular
expression C</^\d+$/>.  This domain accepts the same options as
C<Num> and returns the same error messages.


=head2 Date

  Data::Domain::Date->parser('EU'); # default
  my $domain = Date(-min => '01.01.2001',
                    -max => 'today',
                    -not_in => ['02.02.2002', '03.03.2003', 'yesterday']);

Domain for dates, implemented via the L<Date::Calc|Date::Calc> module.
By default, dates are parsed according to the European format,
i.e. through the L<Decode_Date_EU|Date::Calc/Decode_Date_EU> method;
this can be changed by setting

  Data::Domain::Date->parser('US'); # will use Decode_Date_US

or

  Data::Domain::Date->parser(\&your_own_date_parsing_function);
  # that func. should return an array ($year, $month, $day)

Options to this domain are:

=over

=item -min

The data must be greater or equal to the supplied value.  That value
can be either a regular date, or one of the special keywords C<today>,
C<yesterday> or C<tomorrow>; these will be replaced by the appropriate
date when performing comparisons.

=item -max

The data must be smaller or equal to the supplied value.
Of course the same special keywords (as for C<-min>) are also
admitted.

=item -range

C<< -range => [$min, $max] >> is equivalent to 
C<< -min => $min, -max => $max >>.

=item -not_in

The data must be different from all values in the exclusion set,
supplied as an arrayref.

=back


When outputting error messages, dates will be printed 
according to L<Date::Calc|Date::Calc>'s current language (english
by default); see that module's documentation for changing
the language.


=head2 Time

  my $domain = Time(-min => '08:00', -max => 'now');

Domain for times in format C<hh:mm:ss> (minutes and seconds are optional).


Options to this domain are:

=over

=item -min

The data must be greater or equal to the supplied value.
The special keyword C<now> may be used as a value,
and will be replaced by the current local time when
performing comparisons.

=item -max

The data must be smaller or equal to the supplied value.
The special keyword C<now> may also be used as a value.

=item -range

C<< -range => [$min, $max] >> is equivalent to
C<< -min => $min, -max => $max >>.

=back



=head2 String

  my $domain = String(qr/^[A-Za-z0-9_\s]+$/);

  my $domain = String(-regex     => qr/^[A-Za-z0-9_\s]+$/,
                      -antiregex => qr/$RE{profanity}/,  # see Regexp::Common
                      -range     => ['AA', 'zz'],
                      -length    => [1, 20],
                      -not_in    => [qw/foo bar/]);

Domain for strings. Things considered as strings are either scalar
values, or objects with an overloaded stringification method; by contrast,
a hash reference is not considered to be a string, even if it can stringify
to something like "HASH(0x3f9fc4)" or "Some::Class=HASH(0x3f9fc4)"
through Perl's internal rules.

Options to this domain are:

=over

=item -regex

The data must match the supplied compiled regular expression.  Don't
forget to put C<^> and C<$> anchors if you want your regex to check
the whole string.

C<-regex> is the default option, so you may just pass the regex as a single
unnamed argument to C<String()>.

=item -antiregex

The data must not match the supplied regex.

=item -min

The data must be greater or equal to the supplied value.

=item -max

The data must be smaller or equal to the supplied value.

=item -range

C<< -range => [$min, $max] >> is equivalent to
C<< -min => $min, -max => $max >>.

=item -min_length

The string length must be greater or equal to the supplied value.

=item -max_length

The string length must be smaller or equal to the supplied value.

=item -length

C<< -length => [$min, $max] >> is equivalent to
C<< -min_length => $min, -max_length => $max >>.


=item -not_in

The data must be different from all values in the exclusion set,
supplied as an arrayref.

=back


=head2 Handle

  my $domain = Handle();

Domain for filehandles. This domain has no options.
Domain membership is checked through L<Scalar::Util/openhandle>.


=head2 Enum

  my $domain = Enum(qw/foo bar buz/);

Domain for a finite set of scalar values.
Options are:


=over

=item -values

Ref to an array of values admitted in the domain. 
This would be called as C<< Enum(-values => [qw/foo bar buz/]) >>,
but since this it is the default option, it can be
simply written as C<< Enum(qw/foo bar buz/) >>.

Undefined values are not allowed in the list (use
the C<-optional> argument instead).

=back



=head2 List

  my $domain = List(String, Int, String, Num);

  my $domain = List(-items => [String, Int, String, Num]); # same as above

  my $domain = List(-all  => String(qr/^[A-Z]+$/),
                    -any  => String(-min_length => 3),
                    -size => [3, 10]);

  my $domain = List(-all => [String, Int, Whatever(-can => 'print')]);

Domain for lists of values (stored as Perl arrayrefs).
Options are:

=over

=item -items

Ref to an array of domains; then the first I<n> items in the data must
match those domains, in the same order.

This is the default option, so item domains may be passed directly
to the C<new> method, without the C<-items> keyword.

=item -min_size

The data must be a ref to an array with at least that number of entries.

=item -max_size

The data must be a ref to an array with at most that number of entries.

=item -size

C<< -size => [$min, $max] >> is equivalent to 
C<< -min_size => $min, -max_size => $max >>.


=item -all

All remaining entries in the array, after the first I<n> entries
as specified by the C<-items> option (if any), must satisfy the
C<-all> specification. That specification can be

=over

=item *

a single domain : in that case, all remaining items in the data must
belong to that domain

=item *

an arrayref of domains : in that case, remaining items in the data
are grouped into tuples, and each tuple must satisfy the specification.
So the last example above says that the list must contain triples
where the first item is a string, the second item is an integer
and the third item is an object with a C<print> method.

=back

=item -any

At least one remaining entry in the array, after the first I<n> entries
as specified by the C<-items> option (if any), must satisfy that
domain specification. A list domain can have both an C<-all> and
an C<-any> constraint.

The argument to C<-any> can also be an arrayref of domains, as in

   List(-any => [String(qr/^foo/), Num(-range => [1, 10]) ])

This means that one member of the list must be a string
starting with C<foo>, and one member of the list
must be a number between 1 and 10.
Note that this is different from 

   List(-any => One_of(String(qr/^foo/), Num(-range => [1, 10]))

which says that one member of the list must be I<either>
a string starting with C<foo> I<or> a number between 1 and 10.

=back


=head2 Struct

  my $domain = Struct(foo => Int, bar => String);
  my $domain = Struct(-fields => {foo => Int, bar => String}); # same as above
  
  my $domain = Struct(-fields  => [foo => Int, bar => String],
                      -exclude => '*'); # only 'foo' and 'bar', nothing else
  
  my $domain = Struct(-keys   => List(-all => String(qr/^[abc])),
                      -values => List(-all => Int));

Domain for associative structures (stored as Perl hashrefs).
Options are:

=over

=item -fields

Supplies a list of keys with their associated domains. The list might
be given either as a hashref or as an arrayref.  Specifying it as an
arrayref is useful for controlling the order in which field checks
will be performed; this may make a difference when there are context
dependencies (see 
L<"LAZY CONSTRUCTORS"|/"LAZY CONSTRUCTORS (CONTEXT DEPENDENCIES)"> below ).


=item -exclude

Specifies which keys are not allowed in the structure. The exclusion
may be specified as an arrayref of key names, as a compiled regular
expression, or as the string constant 'C<*>' or 'C<all>' (meaning that
no key will be allowed except those explicitly listed in the
C<-fields> option.

=item -keys

Specifies a List domain, for inspecting the list of keys in the hash.

=item -values

Specifies a List domain, for inspecting the list of values in the hash.

=back


=head2 One_of

  my $domain = One_of($domain1, $domain2, ...);

Union of domains : successively checks the member domains,
until one of them succeeds. 
Options are:


=over

=item -options

List of domains to be checked. This is the default option, so
the keyword may be omitted.

=back


=head2 All_of

  my $domain = All_of($domain1, $domain2, ...);

Intersection of domains : checks all member domains,
and requires that all of them succeed. Options are:


=over

=item -options

List of domains to be checked. This is the default option, so
the keyword may be omitted.

=back


=head1 BUILTIN SHORTCUTS

Below are the precise definition for the shortcut functions
exported in the C<:shortcuts> group. Each of these functions
sets some initial options, but also accepts further options as
arguments, so for example it is possible to write something like
C<< Obj(-does => 'Storable', -optional => 1) >>, which is equivalent to
C<< Whatever(-blessed => 1, -does => 'Storable', -optional => 1) >>.



=head2 True

C<< Whatever(-true => 1) >>

=head2 False

C<< Whatever(-true => 0) >>

=head2 Defined

C<< Whatever(-defined => 1) >>

=head2 Undef

C<< Whatever(-defined => 0) >>

=head2 Blessed

C<< Whatever(-blessed => 1) >>

=head2 Unblessed

C<< Whatever(-blessed => 0) >>

=head2 Regexp

C<< Whatever(-does => 'Regexp') >>

=head2 Obj

C<< Whatever(-blessed => 1) >> (synonym to C<Blessed>)

=head2 Class

C<< Whatever(-blessed => 0, -isa => 'UNIVERSAL') >>


=head1 LAZY CONSTRUCTORS (CONTEXT DEPENDENCIES)

=head2 Principle

If an element of a structured domain (C<List> or C<Struct>) depends on
another element, then we need to I<lazily> construct that subdomain.
Consider for example a struct in which the value of field C<date_end>
must be greater than C<date_begin> : 
the subdomain for C<date_end> can only be constructed 
when the argument to C<-min> is known, namely when
the domain inspects an actual data structure.

Lazy domain construction is achieved by supplying a subroutine reference
instead of a domain object. That subroutine will be called with some
I<context> information, and should return the domain object.
So our example becomes :

  my $domain = Struct(
       date_begin => Date,
       date_end   => sub {my $context = shift;
                          Date(-min => $context->{flat}{date_begin})}
     );

=head2 Structure of context

The supplied context is a hashref containing the following information:

=over

=item root

the overall root of the inspected data

=item path

the sequence of keys or array indices that led to the current
data node. With that information, the subdomain is able to jump
to other ancestor or sibling data nodes within the tree (see also
the L</node_from_path> helper function).

=item flat

a flat hash containing an entry for any hash key met so far while
traversing the tree. In case of name clashes, most recent keys
(down in the tree) override previous keys.

=item list

a reference to the last list (arrayref) encountered
while traversing the tree.


=back

To illustrate this, the following code :

  my $domain = Struct(
     foo => List(Whatever, 
                 Whatever, 
                 Struct(bar => sub {my $context = shift;
                                    print Dumper($context);
                                    String;})
                )
     );
  my $data = {foo => [undef, 99, {bar => "hello, world"}]};
  $domain->inspect($data);

will print :

  $VAR1 = {
    'root' => {'foo' => [undef, 99, {'bar' => 'hello, world'}]},
    'path' => ['foo', 2, 'bar'],
    'list' => $VAR1->{'root'}{'foo'},
    'flat' => {
      'bar' => 'hello, world',
      'foo' => $VAR1->{'root'}{'foo'}
    }
  };


=head2 Examples of lazy domains

=head3 Contextual sets

The domain below accepts hashrefs with a C<country> and a C<city>,
but also checks that the city actually belongs to the given country :

  %SOME_CITIES = {
     Switzerland => [qw/Genève Lausanne Bern Zurich Bellinzona/],
     France      => [qw/Paris Lyon Marseille Lille Strasbourg/],
     Italy       => [qw/Milano Genova Livorno Roma Venezia/],
  };
  my $domain = Struct(
     country => Enum(keys %SOME_CITIES),
     city    => sub {
        my $context = shift;
        Enum(-values => $SOME_CITIES{$context->{flat}{country}});
      });


=head3 Ordered lists

A domain for ordered lists of integers:

  my $domain = List(-all => sub {
      my $context = shift;
      my $index = $context->{path}[-1];
      return $index == 0 ? Int
                         : Int(-min => $context->{list}[$index-1]);
    });

The subdomain for the first item in the list has no specific
constraint; but the next subdomains have a minimal bound that 
comes from the previous list item.

=head3 Recursive domain

A domain for expression trees, where leaves are numbers,
and intermediate nodes are binary operators on subtrees :

  my $expr_domain;
  $expr_domain = One_of(Num, Struct(operator => String(qr(^[-+*/]$)),
                                    left     => sub {$expr_domain},
                                    right    => sub {$expr_domain}));

Observe that recursive calls to the domain are encapsulated within
C<< sub {...} >> so that they are treated as lazy domains.

=head1 WRITING NEW DOMAIN CONSTRUCTORS

Implementing new domain constructors is fairly simple : create
a subclass of C<Data::Domain> and implement a C<new> method and
an C<_inspect> method. See the source code of C<Data::Domain::Num> or 
C<Data::Domain::String> for short examples.

However, before writing such a class, consider whether the existing
mechanisms are not enough for your needs. For example, many domains
could be expressed as a C<String> constrained by a regular
expression; therefore it is just a matter of writing a subroutine
that wraps a call to the domain constructor, while supplying some
of its arguments :

  sub Phone   { String(-regex    => qr/^\+?[0-9() ]+$/, 
                       -messages => "Invalid phone number", @_) }
  sub Email   { String(-regex    => qr/^[-.\w]+\@[\w.]+$/,
                       -messages => "Invalid email", @_) }
  sub Contact { Struct(-fields => [name   => String,
                                   phone  => Phone,
                                   mobile => Phone(-optional => 1),
                                   emails => List(-all => Email)   ], @_) }

Observe that these examples always pass C<@_> to the domain call :
this is so that the client can still add its own arguments to the call,
like

  $domain = Phone(-name     => 'private phone',
                  -optional => 1,
                  -not_in   => [ 1234567, 9999999 ]);


=head1 CONSTANT SUBDOMAINS

For convenience, elements of C<List()> or C<Struct()> may be plain
scalar constants, and are automatically translated into constant domains :

  $domain = Struct(foo => 123,
                   bar => List(Int, 'buz', Int));

This is exactly equivalent to

  $domain = Struct(foo => Int(-min => 123, -max => 123),
                   bar => List(Int, String(-min => 'buz', -max => 'buz'), Int));

=head1 CUSTOMIZING ERROR MESSAGES

Messages returned by validation rules have default values,
but can be customized in several ways.

=head2 General structure of error messages

Each error message has an internal string identifier, like
C<TOO_SHORT>, C<NOT_A_HASH>, etc. The section L</Message identifiers>
below tells which message identifiers may be generated by each domain
constructor.

Message identifiers are then associated with user-friendly
strings, either within the domain itself, or via a global table.
Such strings are actually L<sprintf|perlfunc/sprintf>
format strings, with placeholders for printing some specific
details about the validation rule : for example the C<String>
domain defines default messages such as 

      TOO_SHORT    => "less than %d characters",
      SHOULD_MATCH => "should match '%s'",

=head2 The C<-messages> option to domain constructors

Any domain constructor may receive a 
C<-messages> option to locally override the 
messages for that domain. The argument may be

=over

=item *

a plain string : that string will be returned for any kind of 
validation error within the domain

=item *

a hashref : keys of the hash should be message identifiers, and
values should be the associated error strings.

=item *

a coderef : the referenced subroutine is called, and should
return the error string. The called subroutine receives
the message identifier as argument.

=back

Here is an example :

  sub Phone { 
    String(-regex      => qr/^\+?[0-9() ]+$/, 
           -min_length => 7,
           -messages   => {
             TOO_SHORT    => "phone number should have at least %d digits",
             SHOULD_MATCH => "invalid chars in phone number",
            }, @_);
  }


=head2 The C<messages> class method

Default strings associated with message identifiers are stored in a
global table. The C<Data::Domain> distribution contains builtin tables
for english (the default) and for french : these can be chosen through
the C<messages> class method :

  Data::Domain->messages('english');  # the default
  Data::Domain->messages('français');

The same method can also receive  a custom table.

  my $custom_table = {...};
  Data::Domain->messages($custom_table);

This should be a two-level hashref : first-level entries in the hash
correspond to C<Data::Domain> subclasses (i.e C<< Num => {...} >>, C<<
String => {...} >>), or to the constant C<Generic>; for each of those,
the second-level entries should correspond to message identifiers as
specified in the doc for each subclass (for example C<TOO_SHORT>,
C<NOT_A_HASH>, etc.).  Values should be strings suitable to be fed to
L<sprintf>.  Look at C<$builtin_msgs> in the source code to see an
example.

Finally, it is also possible to write your own message generation 
handler : 

  Data::Domain->messages(sub {my ($msg_id, @args) = @_;
                              return "you just got it wrong ($msg_id)"});

What is received in 
C<@args> depends on which validation rule is involved;
it can be for example the minimal or maximal bounds,
or the regular expression being checked.

=head2 The C<-name> option to domain constructors

The name of the domain is prepended in front of error 
messages. The default name is the subclass of C<Data::Domain>, 
so a typical error message for a string would be 

  String: less than 7 characters

However, if a C<-name> is supplied to the domain constructor,
that name will be printed instead;

  my $dom = String(-min_length => 7, -name => 'Phone');
  # now error would be: "Phone: less than 7 characters"


=head2 Message identifiers

This section lists all possible message identifiers generated
by the builtin constructors.

=over

=item C<Whatever>

C<MATCH_DEFINED>, C<MATCH_TRUE>, C<MATCH_ISA>, C<MATCH_CAN>,
C<MATCH_DOES>, C<MATCH_BLESSED>, C<MATCH_SMART>.

=item C<Num>

C<INVALID>, C<TOO_SMALL>, C<TOO_BIG>, C<EXCLUSION_SET>.

=item C<Date>

C<INVALID>, C<TOO_SMALL>, C<TOO_BIG>, C<EXCLUSION_SET>.


=item C<Time>

C<INVALID>, C<TOO_SMALL>, C<TOO_BIG>.


=item C<String>

C<TOO_SHORT>, C<TOO_LONG>, C<TOO_SMALL>, C<TOO_BIG>,
C<EXCLUSION_SET>, C<SHOULD_MATCH>, C<SHOULD_NOT_MATCH>.

=item C<Enum>

C<NOT_IN_LIST>.

=item C<List>

The domain will first check if the supplied array is of appropriate
shape; in case of of failure, it will return one of the following scalar
messages :  C<NOT_A_LIST>, C<TOO_SHORT>, C<TOO_LONG>.

Then it will check all items in the supplied array according to 
the C<-items> and C<-all> specifications; in case of failure,
an arrayref of messages is returned, where message positions correspond 
to the positions of offending data items.

Finally, the domain will check the C<-any> constraint; in 
case of failure, it returns an C<ANY> scalar message.
Since that message contains the name of the missing domain,
it is a good idea to use the C<-name> option so that the 
message is easily comprehensible, as for example in 

  List(-any => String(-name => "uppercase word", 
                      -regex => qr/^[A-Z]$/))

Here the error message would be : I<should have at least one uppercase word>.


=item C<Struct>

The domain will first check if the supplied hash is of appropriate
shape; in case of of failure, it will return one of the following scalar
messages :  C<NOT_A_HASH>, C<FORBIDDEN_FIELD>.

Then it will check all entries in the supplied hash according to 
the C<-fields> specification, and return a
hashref of messages, where keys correspond to the
keys of offending data items.

=item C<One_of>

If all member domains failed to accept the data, an arrayref
or error messages is returned, where the order of messages
corresponds to the order of the checked domains.

=item C<All_of>

If any member domain failed to accept the data, an arrayref
or error messages from all failing subdomains is returned,
where the order of messages corresponds to the order of
the checked domains.


=back


=head1 INTERNALS

=head2 Variables

=head3 MAX_DEEP

In order to avoid infinite loops, the L</inspect> method will
raise an exception if C<$MAX_DEEP> recursive calls were exceeded.
The default limit is 100, but it can be changed like this :

  local $Data::Domain::MAX_DEEP = 999;

=head2 Methods

=head3 node_from_path

  my $node = node_from_path($root, @path);

Convenience function to find a given node in a data tree, starting
from the root and following a I<path> (a sequence of hash keys or
array indices). Returns C<undef> if no such path exists in the tree.
Mainly useful for contextual constraints in lazy constructors.

=head3 msg

Internal utility method for generating an error message.

=head3 subclass

Method that returns the short name of the subclass of C<Data::Domain> (i.e.
returns 'Int' for C<Data::Domain::Int>).

=head3 _expand_range

Internal utility method for converting a "range" parameter
into "min" and "max" parameters.

=head3 _build_subdomain

Internal utility method for dynamically converting
lazy domains (coderefs) into domains.


=head1 SEE ALSO

Doc and tutorials on complex Perl data structures:
L<perlref>, L<perldsc>, L<perllol>.

Other CPAN modules doing data validation :
L<Data::FormValidator|Data::FormValidator>,
L<CGI::FormBuilder|CGI::FormBuilder>,
L<HTML::Widget::Constraint|HTML::Widget::Constraint>,
L<Jifty::DBI|Jifty::DBI>,
L<Data::Constraint|Data::Constraint>,
L<Declare::Constraints::Simple|Declare::Constraints::Simple>,
L<Moose::Manual::Types>,
L<Smart::Match>, L<Test::Deep>, L<Params::Validate>,
L<Validation::Class>.

Among those, C<Declare::Constraints::Simple> is the closest to
C<Data::Domain>, because it is also designed to deal with
substructures; yet it has a different approach to combinations
of constraints and scope dependencies.

Some inspiration for C<Data::Domain> came from the wonderful
L<Parse::RecDescent|Parse::RecDescent> module, especially
the idea of passing a context where individual rules can grab
information about neighbour nodes. Ideas for some features were
borrowed from L<Test::Deep> and from L<Moose::Manual::Types>.

=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006, 2007, 2012 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
