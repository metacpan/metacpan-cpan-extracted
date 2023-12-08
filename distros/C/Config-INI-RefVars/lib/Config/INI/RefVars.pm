package Config::INI::RefVars;
use 5.010;
use strict;
use warnings;
use Carp;

use feature ":5.10";

use File::Spec::Functions qw(catdir rel2abs splitpath);

our $VERSION = '0.04';

use constant DFLT_TOCOPY_SECTION  => "__TOCOPY__";

use constant FLD_KEY_PREFIX => __PACKAGE__ . ' __ ';

use constant {EXPANDED          => FLD_KEY_PREFIX . 'EXPANDED',

              TOCOPY_SECTION    => FLD_KEY_PREFIX . 'TOCOPY_SECTION',
              TOCOPY_VARS       => FLD_KEY_PREFIX . 'TOCOPY_VARS',
              NOT_TOCOPY        => FLD_KEY_PREFIX . 'NOT_TOCOPY',
              SECTIONS          => FLD_KEY_PREFIX . 'SECTIONS',
              SECTIONS_H        => FLD_KEY_PREFIX . 'SECTIONS_H',
              SRC_NAME          => FLD_KEY_PREFIX . 'SRC_NAME',
              VARIABLES         => FLD_KEY_PREFIX . 'VARIABLES',
              GLOBAL_VARS       => FLD_KEY_PREFIX . 'GLOBAL_VARS',
              VREF_RE           => FLD_KEY_PREFIX . 'VREF_RE',
              BACKUP            => FLD_KEY_PREFIX . 'BACKUP',
             };

my %Globals = ('=:' => catdir("", ""));


# Match punctuation chars, but not the underscores.
my $Modifier_Char = '[^_[:^punct:]]';

my ($_look_up, $_x_var_name, $_expand_vars);

my $_check_tocopy_vars = sub {
  my ($self, $tocopy_vars, $set) = @_;
  croak("'tocopy_vars': expected HASH ref") if ref($tocopy_vars) ne 'HASH';
  $tocopy_vars = { %$tocopy_vars };
  while (my ($var, $value) = each(%$tocopy_vars)) {
    croak("'tocopy_vars': value of '$var' is a ref, expected scalar") if ref($value);
    if (!defined($value)) {
      carp("'tocopy_vars': value '$var' is undef - treated as empty string");
      $tocopy_vars->{$var} = "";
    }
    croak("'tocopy_vars': variable '$var': name is not permitted")
      if ($var =~ /^\s*$/ || $var =~ /^[[=;]/);
  }
  #  @{$self->{+TOCOPY_VARS}}{keys(%$tocopy_vars)} = values(%$tocopy_vars) if $set;
  $self->{+TOCOPY_VARS} = {%$tocopy_vars} if $set;
  return $tocopy_vars;
};


my $_check_not_tocopy = sub {
  my ($self, $not_tocopy, $set) = @_;
  my $ref = ref($not_tocopy);
  if ($ref eq 'ARRAY') {
    foreach my $v (@$not_tocopy) {
      croak("'not_tocopy': undefined value in array") if !defined($v);
      croak("'not_tocopy': unexpected ref value in array") if ref($v);
    }
    $not_tocopy = {map {$_ => undef} @$not_tocopy};
  }
  elsif ($ref eq 'HASH') {
    $not_tocopy = %{$not_tocopy};
  }
  else {
    croak("'not_tocopy': unexpected type: must be ARRAY or HASH ref");
  }
  $self->{+NOT_TOCOPY}= $not_tocopy if $set;
  return $not_tocopy;
};


sub new {
  my ($class, %args) = @_;
  state $allowed_keys = {map {$_ => undef} qw(tocopy_section tocopy_vars not_tocopy
                                              separator)};
  _check_args(\%args, $allowed_keys);
  my $self = {};
  croak("'tocopy_section': must not be a reference") if ref($args{tocopy_section});
  if (exists($args{separator})) {
    state $allowed_sep_chars = "!#%&',./:~";
    my $sep = $args{separator};
    croak("'separator': unexpected ref type, must be a scalar") if ref($sep);
    croak("'separator': invalid value. Allowed chars: $allowed_sep_chars")
      if $sep !~ m{^[$allowed_sep_chars]+$};
    $self->{+VREF_RE} = qr/^(.*?)(?:\Q$sep\E)(.*)$/;
  }
  else {
    $self->{+VREF_RE} = qr/^\[\s*(.*?)\s*\](.*)$/;
  }
  $self->{+TOCOPY_SECTION} = $args{tocopy_section} // DFLT_TOCOPY_SECTION;
  $self->$_check_tocopy_vars($args{tocopy_vars}, 1) if exists($args{tocopy_vars});
  $self->$_check_not_tocopy($args{not_tocopy},   1) if exists($args{not_tocopy});
  return bless($self, $class) ;
}


my $_expand_value = sub {
  return $_[0]->$_expand_vars($_[1], undef, $_[2]);
};

#
# We assume that this is called when the target section is still empty and if
# tocopy vars exist.
#
my $_cp_tocopy_vars = sub {
  my ($self, $to_sect_name) = @_;
  my $comm_sec   = $self->{+VARIABLES}{$self->{+TOCOPY_SECTION}} // die("no tocopy vars");
  my $not_tocopy = $self->{+NOT_TOCOPY};
  my $to_sec     = $self->{+VARIABLES}{$to_sect_name} //= {};
  my $expanded   = $self->{+EXPANDED};
  foreach my $comm_var (keys(%$comm_sec)) {
    next if exists($not_tocopy->{$comm_var});
    $to_sec->{$comm_var} = $comm_sec->{$comm_var};
    my $comm_x_var_name = "[$comm_sec]$comm_var";   # see _x_var_name()
    $expanded->{"[$to_sect_name]$comm_var"} = undef if exists($expanded->{$comm_x_var_name});
  }
};


my $_parse_ini = sub {
  my ($self, $src) = @_;
  my $src_name;
  if (ref($src)) {
    croak("Internal error: argument is not an ARRAY ref") if ref($src) ne 'ARRAY';
    $src_name = $self->{+SRC_NAME};
  }
  else {
    $src_name = $src;
    $src = [do { local (*ARGV); @ARGV = ($src_name); <> }];
  }
  my $curr_section;
  my $sections    = $self->{+SECTIONS};
  my $sections_h  = $self->{+SECTIONS_H};
  my $expanded    = $self->{+EXPANDED};
  my $variables   = $self->{+VARIABLES};
  my $tocopy_sec  = $self->{+TOCOPY_SECTION};
  my $tocopy_vars = $variables->{$tocopy_sec}; # hash key need not to exist!

  my $tocopy_sec_declared;

  my $i;                        # index in for() loop
  my $_fatal = sub { croak("'$src_name': ", $_[0], " at line ", $i + 1); };

  my $set_curr_section = sub {
    $curr_section = shift;
    if ($curr_section eq $tocopy_sec) {
      $_fatal->("tocopy section '$tocopy_sec' must be first section") if @$sections;
      $tocopy_vars = $variables->{$tocopy_sec} = {} if !$tocopy_vars;
      $tocopy_sec_declared = 1;
    }
    elsif ($tocopy_vars) {
      $self->$_cp_tocopy_vars($curr_section);
    }
    else {
      $variables->{$curr_section} = {};
    }
    $_fatal->("'$curr_section': duplicate header") if exists($sections_h->{$curr_section});
    $sections_h->{$curr_section} = @$sections; # Index!
    push(@$sections, $curr_section);
  };

  for ($i = 0; $i < @$src; ++$i) {
    my $line = $src->[$i];
    if (index($line, ";!") == 0 || index($line, "=") == 0) {
      $_fatal->("directives are not yet supported");
    }
    $line =~ s/^\s+//;
    next if $line eq "" || $line =~ /^[;#]/;
    $line =~ s/\s+$//;
    # section header
    if (index($line, "[") == 0) {
      $line =~ s/\s*[#;][^\]]*$//;
      $line =~ /^\[\s*(.*?)\s*\]$/ or $_fatal->("invalid section header");
      $set_curr_section->($1);
      next;
    }

    # var = val
    $set_curr_section->($tocopy_sec) if !defined($curr_section);
    $line =~ /^(.*?)\s*($Modifier_Char*?)=(?:\s*)(.*)/ or
      $_fatal->("neither section header nor key definition");
    my ($var_name, $modifier, $value) = ($1, $2, $3);
    my $x_var_name = $self->$_x_var_name($curr_section, $var_name);
    my $exp_flag = exists($expanded->{$x_var_name});
    $_fatal->("empty variable name") if $var_name eq "";
    my $sect_vars = $variables->{$curr_section} //= {};
    if ($modifier eq "") {
      delete $expanded->{$x_var_name} if $exp_flag;
      $sect_vars->{$var_name} = $value;
    } elsif ($modifier eq '?') {
      $sect_vars->{$var_name} = $value if !exists($sect_vars->{$var_name});
    } elsif ($modifier eq '+') {
      if (exists($sect_vars->{$var_name})) {
        $sect_vars->{$var_name} .= " "
          . ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value);
      } else {
        $sect_vars->{$var_name} = $value;
      }
    } elsif ($modifier eq '.') {
      $sect_vars->{$var_name} = ($sect_vars->{$var_name} // "")
        . ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value);
    } elsif ($modifier eq ':') {
      delete $expanded->{$x_var_name} if $exp_flag; # Needed to make _expand_vars corectly!
      $sect_vars->{$var_name} = $self->$_expand_vars($curr_section, $var_name, $value);
    } elsif ($modifier eq '+>') {
      if (exists($sect_vars->{$var_name})) {
        $sect_vars->{$var_name} =
          ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value)
          . ' ' . $sect_vars->{$var_name};
      } else {
        $sect_vars->{$var_name} = $value;
      }
    } elsif ($modifier eq '.>') {
      $sect_vars->{$var_name} =
        ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value)
        . ($sect_vars->{$var_name} // "");
    } else {
      $_fatal->("'$modifier': unsupported modifier");
    }
  }
  return ($tocopy_sec_declared, $curr_section);
};


sub parse_ini {
  my $self = shift;
  my %args = (cleanup => 1,
              @_ );
  state $allowed_keys = {map {$_ => undef} qw(cleanup src src_name
                                              tocopy_section tocopy_vars not_tocopy)};
  state $dflt_src_name = "INI data";
  _check_args(\%args, $allowed_keys);
  foreach my $scalar_arg (qw(tocopy_section src_name)) {
     croak("'$scalar_arg': must not be a reference") if ref($args{$scalar_arg});
   }
  delete $self->{+SRC_NAME} if exists($self->{+SRC_NAME});  #### !!!!!!!!!!!
  $self->{+SRC_NAME} = $args{src_name} if exists($args{src_name});
  my (      $cleanup, $src, $tocopy_section, $tocopy_vars, $not_tocopy) =
    @args{qw(cleanup   src   tocopy_section   tocopy_vars   not_tocopy)};

  croak("'src': missing mandatory argument") if !defined($src);
  my $backup = $self->{+BACKUP} //= {};
  if (defined($tocopy_section)) {
    $backup->{tocopy_section} = $self->{+TOCOPY_SECTION};
    $self->{+TOCOPY_SECTION}  = $tocopy_section;
  }
  else {
    $tocopy_section = $self->{+TOCOPY_SECTION};
  }
  if ($tocopy_vars) {
    $backup->{tocopy_vars} = $self->{+TOCOPY_VARS};
    $self->$_check_tocopy_vars($tocopy_vars, 1);
  }
  if ($not_tocopy) {
    $backup->{not_tocopy} = $self->{+NOT_TOCOPY};
    $self->$_check_not_tocopy($not_tocopy, 1)
  }
  $self->{+SECTIONS}   = [];
  $self->{+SECTIONS_H} = {};
  $self->{+EXPANDED}   = {};
  $self->{+VARIABLES}  =
    {$tocopy_section => ($self->{+TOCOPY_VARS} ? {%{$self->{+TOCOPY_VARS}}} : {})};

  my $global_vars = $self->{+GLOBAL_VARS} = {%Globals};
  my $tocopy_sec_vars = $self->{+VARIABLES}{$tocopy_section};
  if (my $ref_src = ref($src)) {
    $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});
    if ($ref_src eq 'ARRAY') {
      $src = [@$src];
      foreach my $entry (@$src) {
        croak("'src': unexpected ref type in array") if ref($entry);
        if (!defined($entry)) {
          carp("'src': undef entry - treated as empty string");
          $entry = "";
        }
      }
    }
    else {
      croak("'src': $ref_src: ref type not allowed");
    }
  }
  else {
    if (index($src, "\n") < 0) {
      my $path = $src;
      $src = [do { local (*ARGV); @ARGV = ($path); <> }];
      $self->{+SRC_NAME} = $path if !exists($self->{+SRC_NAME});
      my ($vol, $dirs, $file) = splitpath(rel2abs($path));
      @{$global_vars}{'=srcfile', '=srcdir'} = ($file, catdir(length($vol // "") ? $vol : (),
                                                              $dirs));
    }
    else {
      $src = [split(/\n/, $src)];
      $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});
    }
  }
  $global_vars->{'=srcname'} = $self->{+SRC_NAME};

  my ($tocopy_sec_declared, undef) = $self->$_parse_ini($src);

  while (my ($section, $variables) = each(%{$self->{+VARIABLES}})) {
    while (my ($variable, $value) = each(%$variables)) {
      $variables->{$variable} = $self->$_expand_vars($section, $variable, $value);
    }
  }
  if ($cleanup) {
    while (my ($section, $variables) = each(%{$self->{+VARIABLES}})) {
      foreach my $var (keys(%$variables)) {
        delete $variables->{$var} if index($var, '=') >= 0;
      }
    }
    delete $self->{+VARIABLES}{$self->{+TOCOPY_SECTION}} if (!$tocopy_sec_declared &&
                                                             !%$tocopy_sec_vars);
  }
  else {
    while (my ($section, $variables) = each(%{$self->{+VARIABLES}})) {
      $variables->{'='} = $section;
      @{$variables}{keys(%$global_vars)} = values(%$global_vars);
    }
  }
  $self->{+TOCOPY_SECTION} = $backup->{tocopy_section} if exists($backup->{tocopy_section});
  $self->{+TOCOPY_VARS}    = $backup->{tocopy_vars}    if exists($backup->{tocopy_vars});
  $self->{+NOT_TOCOPY}     = $backup->{not_tocopy}     if exists($backup->{not_tocopy});
  $backup = {};
  return $self;
}


sub sections        { defined($_[0]->{+SECTIONS})   ? [@{$_[0]->{+SECTIONS}}]     : undef}

sub sections_h      { defined($_[0]->{+SECTIONS_H}) ? +{ %{$_[0]->{+SECTIONS_H}} } : undef }

sub variables       { my $vars = $_[0]->{+VARIABLES} // return undef;
                      return  {map {$_ => {%{$vars->{$_}}}} keys(%$vars)};
                    }

sub src_name        {$_[0]->{+SRC_NAME}}
sub tocopy_section  {$_[0]->{+TOCOPY_SECTION}}


$_look_up = sub {
  my ($self, $curr_sect, $variable) = @_;
  my $matched = $variable =~ $self->{+VREF_RE};
  my ($v_section, $v_basename) = $matched ? ($1, $2) : ($curr_sect, $variable);
  my $v_value;
  my $variables = $self->{+VARIABLES};
  if (!exists($variables->{$v_section})) {
    $v_value = "";
  } elsif ($v_basename !~ /\S/) {
    $v_value = $v_basename;
  }
  elsif ($v_basename eq '=') {
    $v_value = $v_section;
  }
  elsif ($v_basename =~ /^=(?:ENV|env):\s*(.*)$/) {
    $v_value = $ENV{$1} // "";
  }
  elsif (exists($self->{+GLOBAL_VARS}{$v_basename})) {
    $v_value = $self->{+GLOBAL_VARS}{$v_basename};
  }
  else {
    if (exists($variables->{$v_section}{$v_basename})) {
      $v_value = $variables->{$v_section}{$v_basename};
    } else {
      $v_value = "";
    }
  }
  die("Internal error") if !defined($v_value);
  return wantarray ? ($v_section, $v_basename, $v_value) : $v_value;
};

# extended var name
$_x_var_name = sub {
  my ($self, $curr_sect, $variable) = @_;

  if ($variable =~ $self->{+VREF_RE}) {
    return ($2, "[$1]$2");
  }
  else {
    return ($variable, "[$curr_sect]$variable");
  }
};


$_expand_vars = sub {
  my ($self, $curr_sect, $variable, $value, $seen) = @_;
  my $top = !$seen;
  my @result = ("");
  my $level = 0;
  my $x_variable_name;
  if (defined($variable)) {
    ((my $var_basename), $x_variable_name) = $self->$_x_var_name($curr_sect, $variable);
    return $self->$_look_up($curr_sect, $variable) if (exists($self->{+EXPANDED}{$x_variable_name})
                                                       || $var_basename =~ /^=ENV:/);
    croak("recursive variable '", $x_variable_name, "' references itself")
      if exists($seen->{$x_variable_name});
    $seen->{$x_variable_name} = undef;
  }
  foreach my $token (split(/(\$\(|\))/, $value)) {
    if ($token eq '$(') {
      ++$level;
    }
    elsif ($token eq ')' && $level) {
      # Now $result[$level] contains the name of a referenced variable.
      if ($result[$level] eq '==') {
        $result[$level - 1] .= $variable;
      }
      else {
        $result[$level - 1] .=
          $self->$_expand_vars($self->$_look_up($curr_sect, $result[$level]), $seen);
      }
      pop(@result);
      --$level;
    }
    else {
      $result[$level] .= $token;
    }
  }
  croak("'$x_variable_name': unterminated variable reference") if $level;
  $value = $result[0];
  if ($x_variable_name) {
    $self->{+EXPANDED}{$x_variable_name} = undef if $top;
    delete $seen->{$x_variable_name};
  }
  return $value;
};


#
# This is a function, not a method!
#
sub _check_args {
  my ($args, $allowed_args) = @_;
  foreach my $key (keys(%$args)) {
    croak("'$key': unsupported argument") if !exists($allowed_args->{$key});
  }
  delete @{$args}{ grep { !defined($args->{$_}) } keys(%$args) };
}


1; # End of Config::INI::RefVars



__END__


=pod


=head1 NAME

Config::INI::RefVars - INI file reader, allows the referencing of INI and environment variables within the INI file.


=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Config::INI::RefVars;

    my $ini_reader = Config::INI::RefVars->new();
    $ini_reader->parse_ini(src => $my_ini_file);
    my $variables = $ini_reader->variables;
    while (my ($section, $section_vars) = each(%$variables)) {
        # ...
    }

If the INI file contains:

   [sec A]
   foo=this value
   bar=that value

   [sec B]
   baz = yet another value

then C<< $ini_reader->variables >> returns:

   {
       'sec A' => {
                    'bar' => 'that value',
                    'foo' => 'this value'
                  },
       'sec B' => {
                    'baz' => 'yet another value'
                  }
   }


=head1 DESCRIPTION


=head2 INTRODUCTION

Minimum version of perl required to use this module: C<v5.10.1>.

This module provides an INI file reader that allows INI variables and
environment variables to be referenced within the INI file. It also supports
some additional assignment operators.


=head2 OVERVIEW

A line in an INI file should not start with an C<=> or the sequence
C<;!>. These are reserved for future extensions. Otherwise the parser throws a
"Directives are not yet supported" exception. Apart from these special cases,
the following rules apply:

=over

=item *

Spaces at the beginning and end of each line are ignored.

=item *

If the first non-white character of a line is a C<;> or a C<#>, then the line
is a comment line.

=item *

Comments can also be specified to the right of a section declaration (in this
case, the comment must not contain closing square brackets).

=item *

In a section header, spaces to the right of the opening square
bracket and to the left of the closing square bracket are ignored, i.e. a
section name always begins and ends with a non-white character. B<But>: As a
special case, the name of a section heading can be an empty character string.

=item *

Section name must be unique.

=item *

The order of the sections is retained: The C<sections> method returns an array
of sections in the order in which they appear in the INI file.

=item *

A variable name cannot be empty.

=item *

The sequence C<$(...)> is used to reference INI variables or environment
variables.

=item *

Spaces around the assignment operator are ignored. Note that there are several
assignment operators, not just C<=>.

=item *

If you want to define a variable whose name ends with an punctuation character other
than an underscore, there must be at least one space between the variable name
and the assignment operator.

=item *

The source to be parsed (argument C<src> of the method C<parse_ini>) does not
have to be a file, but can also be a string or an array.

=item *

There is no escape character.

=back

You will find further details in the following sections.


=head2 SECTIONS

A section begins with a section header:

  [section]

A line contains a section heading if the first non-blank character is a C<[>
and the last non-blank character is a C<]>. The character string in between is
the name of the section, whereby spaces to the right of C<[> and to the left
of C<]> are ignored.

   [   The name of the section   ]

This sets the section name to C<The name of the section>.

As a special case, C<[]> or C<[ ]> are permitted, which results in a section
name that is just an empty string.

Section names must be unique.

An INI file does not have to start with a section header, it can also start
with variable definitions. In this case, the variables are added to the
I<tocopy section> (default name: C<__TOCOPY__>). You can explicitly specify
the I<tocopy> section heading, but then this must be the first active line in
your INI file.


=head2 VARIABLES AND ASSIGNMENT OPERATORS

There are several assignment operators, the basic one is the C<=>, the others
are formed by a C<=> preceded by one or more punctuation characters. Thus, if
you want to define a variable whose name ends with an punctuation character,
there must be at least one space between the variable name and the assignment
operator.

B<Note>: Since the use of the underscore in identifiers is so common, it is
not treated as a punctuation character here.

=over

=item C<=>

The standard assignment operator. Note: A second assignment to the same
variable simply overwrites the first.

=item C<?=>

Works like the corresponding operator of GNU Make: the assignment is only
executed if the variable is not yet defined.

=item C<:=>

Works like the corresponding operator of GNU Make: all references to other
variables are expanded when the variable is defined. See section L</"REFERENCING VARIABLES">

=item C<.=>

The right-hand side is appended to the value of the variable. If the variable
is not yet defined, this does the same as a simple C<=>.

Example:

  var=abc
  var.=123

Now C<var> has the value C<abc123>.

=item C<+=>

Works like the corresponding operator of GNU Make: the right-hand side is
appended to the value of the variable, separated by a space. If the right-hand
side is empty, a space is appended. If the variable is not yet defined, this
has the same effect as a simple C<=>.

Example:

   var=abc
   var+=123

Now C<var> has the value C<abc 123>.


=item C<< .>= >>

The right-hand side is placed in front of the value of the variable. If the
variable is not yet defined, this has the same effect as a simple C<=>.

Example:

  var=abc
  var.>=123

Now C<var> has the value C<123abc>.

=item C<< +>= >>

The right-hand side is placed in front the value of the variable, separated by
a space. If the right-hand side is empty, a space is placed in front of the
variable value. If the variable is not yet defined, this has the same effect
as a simple C<=>.

Example:

  var=abc
  var+>=123

Now C<var> has the value C<123 abc>.

=back


=head2 REFERENCING VARIABLES

=head3 Basic Referencing

The referencing of variables is similar but not identical to that in B<make>,
you use C<$(I<VARIABLE>)>. Example:

   a=hello
   b=world
   c=$(a) $(b)

Variable C<c> has the value C<hello world>. As with B<make>, lazy evaluation
is used, i.e. you would achieve exactly the same result with this:

   c=$(a) $(b)
   a=hello
   b=world

But the following would result in C<c> containing only one space:

   c:=$(a) $(b)
   a=hello
   b=world

Unlike in B<make>, the round brackets cannot be omitted for variables with
only one letter!

You can nest variable references:

   foo=the foo value
   var 1=fo
   var 2=o
   bar=$($(var 1)$(var 2))

Now the variable C<bar> has the value C<the foo value>.

A reference to a non-existent variable is always expanded to an empty
character string.

If you need a literal C<$(...)> sequence, e.g. C<$(FOO)>, as part of a
variable value, you can write:

   var = $$()(FOO)

This results in the variable C<var> having the value C<$(FOO)>. It works
because C<$()> always expands to an empty string (see section L</"PREDEFINED
VARIABLES">).


=head3 Referencing Variables of other Sections

By default, you can reference a variable in another section by writing the
name of the section in square brackets, followed by the name of the variable:

   [sec A]
   foo=Referencing a variable from section: $([sec B]bar)

   [sec B]
   bar=Referenced!

You can switch to a different notation by specifying the constructor argument
C<separator>.

A more complex example:

   [A]
   a var = 1234567

   [B]
   b var = a var
   nested = $([$([C]c var)]$(b var))

   [C]
   c var = A

Variable C<nested> in section C<B> has the value C<1234567>.


=head2 PREDEFINED VARIABLES

=head3 Variables related to Section and Variable Names

=over

=item C<=>

C<$(=)> expands to the name of the current section.

=item C<==>

C<$(==)> expands to the name of the variable that is currently being defined.

=back

Example:

   [A]
   foo=variable $(==) of section $(=)
   ref=Reference to foo of section B: $([B]foo)

   [B]
   foo=variable $(==) of section $(=)
   bar=$(foo)

The hash returned by the C<variables> method is then:

   {
     'A' => {
             'foo' => 'variable foo of section A',
             'ref' => 'Reference to foo of section B: variable foo of section B'
            },
     'B' => {
             'foo' => 'variable foo of section B'
             'bar' => 'variable foo of section B',
            }
   }


=head3 Variables related to the Source:

=over

=item C<=srcname>

Name of the INI source. If the source is a file, this corresponds to the value
that you have passed to C<parse_ini> via the C<src> argument, otherwise it is
set to "INI data". The value can be overwritten with the argument C<src_name>.

=item C<=srcdir>, C<=srcfile>

Directory (absolute path) and file name of the INI file. These variables are
only present if the source is a file, otherwise they are not defined.

=back


=head3 Space Variables

C<$()> always expands to an empty string, C<$(E<nbsp>)>, C<$(E<nbsp>E<nbsp>)>
with any number of spaces within the parens expand to exactly these spaces. So
there are several ways to define variables with heading or trailing spaces:

   foo = abc   $()
   bar = $(   )abc

The value of C<foo> has three spaces at the end, the value of C<bar> has three
spaces at the beginning. A special use case for C<$()> is the avoidance of
unwanted variable expansion:

   var=hello!
   x=$(var)
   y=$$()(var)

With these settings, C<x> has the value C<Hello!>, but C<y> has the value
C<$(var)>.


=head3 Custom predefined Variables

Currently, custom predefined variables are not supported. But you can do
something very similar, see argument C<tocopy_vars> (of C<new> and
C<parse_ini>), see also L</"THE I<TOCOPY> SECTION">. With this argument you
can also define variables whose names contain a C<=>, which is obviously
impossible in an INI file.


=head3 Predefined Variables in resulting Hash

By default, all variables whose names contain a C<=> are removed from the
resulting hash. This means that the variables discussed above are not normally
included in the result. This behavior can be changed with the C<parse_ini>
argument C<cleanup>. The variable C<==> can of course not be included in the
result.


=head2 ACCESSING ENVIRONMENT VARIABLES

You can access environment variables with this C<$(=ENV:...)> or this
C<$(=env:...)> notation. Example:

   path = $(=ENV:PATH)

C<path> now contains the content of your environment variable C<PATH>.

The results of C<$(=ENV:...)> and C<$(=env:...)> are almost always the
same. The difference is that the parser always leaves the value of
C<$(=ENV:...)> unchanged, but tries to expand the value of C<$(=env:...)>.
For example, let's assume you have an environment variable C<FOO> with the
value C<$(var)> and you write this in your INI file:

   var=hello!
   x=$(=ENV:FOO)
   y=$(=env:FOO)

This results in C<x> having the value C<$(var)>, while C<y> has the value C<hello!>.


=head2 THE I<TOCOPY> SECTION

If specified, the C<parse_ini> method copies the variables of the I<tocopy
section> to every other section when the INI file is read. For example this

   [__TOCOPY__]
   some var=some value
   section info=$(=)

   [A]

   [B]

is exactly the same as this:

   [__TOCOPY__]
   some var=some
   section info=$(=)

   [A]
   some var=some
   section info=$(=)

   [B]
   some var=some
   section info=$(=)

Of course, you can change or overwrite a variable copied from the C<tocopy>
section locally within a section at any time without any side effects.

You can exclude variables with the argument C<not_tocopy> from copying
(methods C<new> and C<parse_ini>), but there is currently no notation to do
this in the INI file.

The I<tocopy section> is optional. If it is specified, it must be the first
section. By default, its name is C<__TOCOPY__>, this can be changed with the
argument C<tocopy_section> (methods C<new> and C<parse_ini>). You can omit the
C<[__TOCOPY__]> header and simply start your INI file with variable
definitions. These then simply become the I<tocopy section>. So this:

  [__TOCOPY__]
  a=this
  b=that

  [sec]
  x=y

is exactly the same as this:

  a=this
  b=that

  [sec]
  x=y

You can also add I<tocopy> variables via the argument C<tocopy_vars> (methods
C<new> and C<parse_ini>), these are treated as if they were at the very
beginning of the C<tocopy> section.


=head2 COMMENTS

As said, if the first non-white character of a line is a C<;> or a C<#>, then the line
is a comment line.

   # This is a comment
   ; This is also a comment
       ;! a comment, but: avoid ";!" at the very beginning of a line!
   var = value ; this is not a comment but part of the value.

Avoid C<;!> at the very beginning of a line, otherwise you will get an
error. The reason for this is that this sequence is reserved for future
extensions. However, you can use it if you precede it with spaces.

You cannot append a comment to the right of a variable definition, as your
comment would otherwise become part of the variable value. But you can append
a comment to the right of a header declaration:

   [section]  ; My fancy section

B<Attention>: if you do this, the comment must not contain a C<]> character!


=head2 PITFALLS

In most cases, the keys in the hash returned by C<variables> are the same as
the keys in the hash returned by the C<sections_h> method and the entries in
the array returned by the C<sections> method. In special cases, however, there
may be a difference with regard to the I<tocopy> section. Example:

   [A]
   a=1

   [B]
   b=2

If you parse this INI source like this:

  my $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => $src, tocopy_vars => {'foo' => 'xyz'});

then the C<variables> method returns this:

   'A' => {
           'a' => '1',
           'foo' => 'xyz'
          },
   'B' => {
           'b' => '2',
           'foo' => 'xyz'
          },
   '__TOCOPY__' => {
                    'foo' => 'xyz'
                   }

but C<sections_h> returns

   { 'A' => '0',
     'B' => '1' }

and C<sections> returns

   ['A', 'B']

No C<__TOCOPY__>. The reason for this is that the return values of
C<sections_h> and C<sections> refer to what is contained in the source, and in
this case C<__TOCOPY__> is not contained in the source, but comes from a
method argument.


=head2 METHODS

=head3 new

The constructor takes the following optional named arguments:

=over

=item C<tocopy_section>

Optional, a string. Specifies a different name for the I<tocopy>
section. Default is C<__TOCOPY__>. See accessor C<tocopy_section>.

=item C<tocopy_vars>

Optional, a hash reference. If specified, its keys become variables of the
I<tocopy> section, the hash values become the corresponding variable values. This
allows you to specify variables that you cannot specify in the INI file,
e.g. variables with a C<=> in the name.

Keys with C<=> or C<;> as the first character are not permitted.

Default is C<undef>.

=item C<not_tocopy>

Optional, a reference to a hash or an array of strings. The hash keys or array
entries specify a list of variables that should not be copied from the
I<tocopy> section to the other sections. It does not matter whether these
variables actually occur in the I<tocopy> section or not.

Default is C<undef>.

=item C<separator>

Optional, a character string. If specified, an alternative notation can be
used for referencing variables in another section. Example:

   my $obj = Config::INI::RefVars->new(separator => '::');

Then you can write:

    [A]
    y=27
    
    [B]
    a var=$(A::y)

This gives the variable C<a var> the value C<27>.

The following characters are permitted for C<separator>:

   !#%&',./:~

=back



=head3 tocopy_section

Returns the name of the I<tocopy> section that will be used as the default for
the next call to C<parse_ini>.


=head3 parse_ini

Parses an INI source. The method takes the following optional named arguments:

=over

=item C<src>

Mandatory, a string or an array reference. This specifies the source to
parse. If it is a character string that does not contain a newline character,
it is treated as the name of an INI file. Otherwise, its content is parsed
directly.

=item C<cleanup>

Optional, a boolean. If this value is set to I<false>, variables with a C<=>
in their name are not removed from the resulting hash that is returned by the
C<variables> method.

Default is 1 (I<true)>

=item C<tocopy_section>

Optional, a string. Specifies a different name for the I<tocopy> section for
this run only. The previous value is restored before the method
returns. Default is the string returned by accessor C<tocopy_section>.

See constructor argument of the same name.

=item C<tocopy_vars>

Optional, overwrites the corresponding setting saved in the object for this
run only. The previous setting is restored before the method returns.

See constructor argument of the same name.

=item C<not_tocopy>

Optional, overwrites the corresponding setting saved in the object for this
run only. The previous setting is restored before the method returns.

See constructor argument of the same name.

=item C<src_name>

Optional, overwrites the corresponding setting saved in the object for this
run only. The previous setting is restored before the method returns.

See constructor argument of the same name, see also the accessor os the same
name.

=back


=head3 sections

Returns a reference to an array of section names from the INI source, in the
order in which they appear there.

=head3 sections_h

Returns a reference to a hash whose keys are the section names from the INI
source, the values are the corresponding indices in the array returned by
C<sections>.

=head3 src_name

Returns the name of the INI source (file name that you have passed to
C<parse_ini> via the argument C<src>, or the one that you have passed via the
argument C<src_name>, or "C<INI data>", see section L</"Variables in relation
to the source">.

=head3 variables

Returns a reference to a hash of hashes. The keys are the section names, each
value is the corresponding hash of varibales (key: variable name, value:
variable value). By default, variables with a C<=> in their name are not
included; this can be changed with the C<cleanup> argument.


=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>



=head1 BUGS

Please report any bugs or feature requests to C<bug-config-ini-accvars at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-INI-RefVars>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::INI::RefVars


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-INI-RefVars>

=item * Search CPAN

L<https://metacpan.org/release/Config-INI-RefVars>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Config-INI-RefVars>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
