# Apache::ConfigParser::Directive: A single Apache directive or start context.
#
# Copyright (C) 2001-2005 Blair Zajac.  All rights reserved.

package Apache::ConfigParser::Directive;

require 5.004_05;

use strict;
use Exporter;
use Carp;
use File::Spec     0.82;
use Tree::DAG_Node 1.04;

use vars qw(@EXPORT_OK @ISA $VERSION);
@ISA     = qw(Tree::DAG_Node Exporter);
$VERSION = '1.02';

# Determine if the filenames are case sensitive.
use constant CASE_SENSITIVE_PATH => (! File::Spec->case_tolerant);

# This is a utility subroutine to determine if the specified path is
# the /dev/null equivalent on this operating system.
use constant DEV_NULL    =>    File::Spec->devnull;
use constant DEV_NULL_LC => lc(File::Spec->devnull);
sub is_dev_null {
  if (CASE_SENSITIVE_PATH) {
    return $_[0] eq DEV_NULL;
  } else {
    return lc($_[0]) eq DEV_NULL_LC;
  }
}
push(@EXPORT_OK, qw(DEV_NULL DEV_NULL_LC is_dev_null));

# This constant is used throughout the module.
my $INCORRECT_NUMBER_OF_ARGS = "passed incorrect number of arguments.\n";

# These are declared now but defined and documented below.
use vars         qw(%directive_value_takes_abs_path
                    %directive_value_takes_rel_path
                    %directive_value_path_element_pos);
push(@EXPORT_OK, qw(%directive_value_takes_abs_path
                    %directive_value_takes_rel_path
                    %directive_value_path_element_pos));

=head1 NAME

  Apache::ConfigParser::Directive - An Apache directive or start context

=head1 SYNOPSIS

  use Apache::ConfigParser::Directive;

  # Create a new empty directive.
  my $d = Apache::ConfigParser::Directive->new;

  # Make it a ServerRoot directive.
  # ServerRoot /etc/httpd
  $d->name('ServerRoot');
  $d->value('/etc/httpd');

  # A more complicated directive.  Value automatically splits the
  # argument into separate elements.  It treats elements in "'s as a
  # single element.
  # LogFormat "%h %l %u %t \"%r\" %>s %b" common
  $d->name('LogFormat');
  $d->value('"%h %l %u %t \"%r\" %>s %b" common');

  # Get a string form of the name.
  # Prints 'logformat'.
  print $d->name, "\n";

  # Get a string form of the value.
  # Prints '"%h %l %u %t \"%r\" %>s %b" common'.
  print $d->value, "\n";

  # Get the values separated into individual elements.  Whitespace
  # separated elements that are enclosed in "'s are treated as a
  # single element.  Protected quotes, \", are honored to not begin or
  # end a value element.  In this form protected "'s, \", are no
  # longer protected.
  my @value = $d->get_value_array;
  scalar @value == 2;		# There are two elements in this array.
  $value[0] eq '%h %l %u %t \"%r\" %>s %b';
  $value[1] eq 'common';

  # The array form can also be set.  Change style of LogFormat from a
  # common to a referer style log.
  $d->set_value_array('%{Referer}i -> %U', 'referer');

  # This is equivalent.
  $d->value('"%{Referer}i -> %U" referer');

  # There are also an equivalent pair of values that are called
  # 'original' that can be accessed via orig_value,
  # get_orig_value_array and set_orig_value_array.
  $d->orig_value('"%{User-agent}i" agent');
  $d->set_orig_value_array('%{User-agent}i', 'agent');
  @value = $d->get_orig_value_array;
  scalar @value == 2;		# There are two elements in this array.
  $value[0] eq '%{User-agent}i';
  $value[1] eq 'agent';

  # You can set undef values for the strings.
  $d->value(undef);

=head1 DESCRIPTION

The C<Apache::ConfigParser::Directive> module is a subclass of
C<Tree::DAG_Node>, which provides methods to represents nodes in a
tree.  Each node is a single Apache configuration directive or root
node for a context, such as <Directory> or <VirtualHost>.  All of the
methods in that module are available here.  This module adds some
additional methods that make it easier to represent Apache directives
and contexts.

This module holds a directive or context:

  name
  value in string form
  value in array form
  a separate value termed 'original' in string form
  a separate value termed 'original' in array form
  the filename where the directive was set
  the line number in the filename where the directive was set

The 'original' value is separate from the non-'original' value and the
methods to operate on the two sets of values have distinct names.  The
'original' value can be used to store the original value of a
directive while the non-'directive' value can be a modified form, such
as changing the CustomLog filename to make it absolute.  The actual
use of these two distinct values is up to the caller as this module
does not link the two in any way.

=head1 METHODS

The following methods are available:

=over

=cut

=item $d = Apache::ConfigParser::Directive->new;

This creates a brand new C<Apache::ConfigParser::Directive> object.

It is not recommended to pass any arguments to C<new> to set the
internal state and instead use the following methods.

There actually is no C<new> method in the
C<Apache::ConfigParser::Directive> module.  Instead, due to
C<Apache::ConfigParser::Directive> being a subclass of
C<Tree::DAG_Node>, C<Tree::DAG_Node::new> will be used.

=cut

# The Apache::ConfigParser::Directive object still needs to be
# initialized.  This is done here.  Tree::DAG_Node->new calls
# Apache::ConfigParser::Directive->_init, which will call
# Tree::DAG_Node->_init.
sub _init {
  my $self                  = shift;
  $self->SUPER::_init;
  $self->{name}             = '';
  $self->{value}            = '';
  $self->{value_array}      = [];
  $self->{orig_value}       = '';
  $self->{orig_value_array} = [];
  $self->{filename}         = '';
  $self->{line_number}      = -1;
}

=item $d->name

=item $d->name($name)

In the first form get the directive or context's name.  In the second
form set the new name of the directive or context to the lowercase
version of I<$name> and return the original name.

=cut

sub name {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::name ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;
  if (@_) {
    my $old       = $self->{name};
    $self->{name} = lc($_[0]);
    return $old;
  } else {
    return $self->{name};
  }
}

=item $d->value

=item $d->value($value)

In the first form get the directive's value in string form.  In the
second form, return the previous directive value in string form and
set the new directive value to I<$value>.  I<$value> can be set to
undef.

If the value is being set, then I<$value> is saved so another call to
C<value> will return I<$value>.  If I<$value> is defined, then
I<$value> is also parsed into an array of elements that can be
retrieved with the C<value_array_ref> or C<get_value_array> methods.
The parser separates elements by whitespace, unless whitespace
separated elements are enclosed by "'s.  Protected quotes, \", are
honored to not begin or end a value element.

=item $d->orig_value

=item $d->orig_value($value)

Identical behavior as C<value>, except that this applies to a the
'original' value.  Use C<orig_value_ref> or C<get_orig_value_array> to
get the value elements.

=cut

# This function manages getting and setting the string value for
# either the 'value' or 'orig_value' hash keys.
sub _get_set_value_string {
  unless (@_ > 1 and @_ < 4) {
    confess "$0: Apache::ConfigParser::Directive::_get_set_value_string ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self            = shift;
  my $string_var_name = pop;
  my $old_value       = $self->{$string_var_name};
  unless (@_) {
    return $old_value;
  }

  my $value           = shift;
  my $array_var_name  = "${string_var_name}_array";

  if (defined $value) {
    # Keep the value as a string and also create an array of values.
    # Keep content inside " as a single value and also protect \".
    my @values;
    if (length $value) {
      my $v =  $value;
      $v    =~ s/\\"/\200/g;
      while (defined $v and length $v) {
        if ($v =~ s/^"//) {
          my $quote_index = index($v, '"');
          if ($quote_index < 0) {
            $v =~ s/\200/"/g;
            push(@values, $v);
            last;
          } else {
            my $v1 =  substr($v, 0, $quote_index, '');
            $v     =~ s/^"\s*//;
            $v1    =~ s/\200/"/g;
            push(@values, $v1);
          }
        } else {
          my ($v1, $v2) = $v =~ /^(\S+)(?:\s+(.*))?$/;
          $v            = $v2;
          $v1           =~ s/\200/"/g;
          push(@values, $v1);
        }
      }
    }
    $self->{$string_var_name} = $value;
    $self->{$array_var_name}  = \@values;
  } else {
    $self->{$string_var_name} = undef;
    $self->{$array_var_name}  = undef;
  }

  $old_value;
}

sub value {
  unless (@_ and @_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::value ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  return _get_set_value_string(@_, 'value');
}

sub orig_value {
  unless (@_ and @_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::orig_value ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  return _get_set_value_string(@_, 'orig_value');
}

=item $d->value_array_ref

=item $d->value_array_ref(\@array)

In the first form get a reference to the value array.  This can return
an undefined value if an undefined value was passed to C<value> or an
undefined reference was passed to C<value_array_ref>.  In the second
form C<value_array_ref> sets the value array and value string.  Both
forms of C<value_array_ref> return the original array reference.

If you modify the value array reference after getting it and do not
use C<value_array_ref> C<set_value_array> to set the value, then the
string returned from C<value> will not be consistent with the array.

=item $d->orig_value_array_ref

=item $d->orig_value_array_ref(\@array)

Identical behavior as C<value_array_ref>, except that this applies to
the 'original' value.

=cut

# This is a utility function that takes the hash key name to place the
# value elements into, saves the array and creates a value string
# suitable for placing into an Apache configuration file.
sub _set_value_array {
  unless (@_ > 1) {
    confess "$0: Apache::ConfigParser::Directive::_set_value_array ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self            = shift;
  my $string_var_name = pop;
  my $array_var_name  = "${string_var_name}_array";
  my @values          = @_;

  my $value = '';
  foreach my $s (@values) {
    next unless length $s;

    $value .= ' ' if length $value;

    # Make a copy of the string so that the regex doesn't modify the
    # contents of @values.
    my $substring  =  $s;
    $substring     =~ s/(["\\])/\\$1/g;
    if ($substring =~ /\s/) {
      $value .= "\"$substring\"";
    } else {
      $value .= $substring;
    }
  }

  my $old_array_ref = $self->{$array_var_name};

  $self->{$string_var_name} = $value;
  $self->{$array_var_name}  = \@values;

  $old_array_ref ? @$old_array_ref : ();
}

sub value_array_ref {
  unless (@_ and @_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::value_array_ref ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;

  my $old = $self->{value_array};

  if (@_) {
    my $ref = shift;
    if (defined $ref) {
      $self->_set_value_array(@$ref, 'value');
    } else {
      $self->{value}       = undef;
      $self->{value_array} = undef;
    }
  }

  $old;
}

sub orig_value_array_ref {
  unless (@_ and @_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::orig_value_array_ref ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;

  my $old = $self->{orig_value_array};

  if (@_) {
    my $ref = shift;
    if (defined $ref) {
      $self->_set_value_array(@$ref, 'orig_value');
    } else {
      $self->{value}       = undef;
      $self->{value_array} = undef;
    }
  }

  $old;
}

=item $d->get_value_array

Get the value array elements.  If the value was set to an undefined
value using C<value>, then C<get_value_array> will return an empty
list in a list context, an undefined value in a scalar context, or
nothing in a void context.

=item $d->get_orig_value_array

This has the same behavior of C<get_value_array> except that it
operates on the 'original' value.

=cut

sub get_value_array {
  unless (@_ == 1) {
    confess "$0: Apache::ConfigParser::Directive::get_value_array ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $ref = shift->{value_array};

  if ($ref) {
    return @$ref;
  } else {
    return;
  }
}

sub get_orig_value_array {
  unless (@_ == 1) {
    confess "$0: Apache::ConfigParser::Directive::get_orig_value_array ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $ref = shift->{orig_value_array};

  if ($ref) {
    return @$ref;
  } else {
    return;
  }
}

=item $d->set_value_array(@values)

Set the value array elements.  If no elements are passed in, then the
value will be defined but empty and a following call to
C<get_value_array> will return an empty array.  This returns the value
of the array before this method was called.

After setting the value elements with this method, the string returned
from calling C<value> is a concatenation of each of the elements so
that the output could be used for an Apache configuration file.  If
any elements contain whitespace, then the "'s are placed around the
element as the element is being concatenated into the value string and
if any elements contain a " or a \, then a copy of the element is made
and the character is protected, i.e. \" or \\, and then copied into
the value string.

=item $d->set_orig_value_array(@values)

This has the same behavior as C<set_value_array> except that it
operates on the 'original' value.

=cut

sub set_value_array {
  return _set_value_array(@_, 'value');
}

sub set_orig_value_array {
  return _set_value_array(@_, 'orig_value');
}

=item Note on $d->value_is_path, $d->value_is_abs_path,
$d->value_is_rel_path, $d->orig_value_is_path,
$d->orig_value_is_abs_path and $d->orig_value_is_rel_path

These six methods are very similar.  They all check if the directive
can take a file or directory path value argument in the appropriate
index in the value array and then check the value.  For example, the
C<LoadModule> directive, i.e.

=over 4

LoadModule cgi_module libexec/mod_cgi.so

=back

does not take a path element in its first (index 0) value array
element.

If there is no argument supplied to the method call, then the
directive checks the first element of the value array that can legally
contain path.  For C<LoadModule>, it would check element 1.  You could
pass 0 to the method to check the first indexed value of
C<LoadModule>, but it would always return false, because index 0 does
not contain a path.

These are the differences between the methods:

=over 4

1) The methods beginning with the string 'value_is' apply to the
current value in the directive while the methods beginning with the
string 'orig_value_is' apply to the original value of the directive.

2) The methods '*value_is_path' test if the directive value is a path,
either absolute or relative.  The methods '*value_is_abs_path' test if
the path if an absolute path, and the methods '*value_is_rel_path'
test if the path is not an absolute path.

=back

=item $d->value_is_path

=item $d->value_is_path($index_into_value_array)

Returns true if C<$d>'s directive can take a file or directory path in
the specified value array element (indexed by $index_into_value_array
or the first path element for the particular directive if
$index_into_value_array is not provided) and if the value is either an
absolute or relative file or directory path.  Both the directive name
and the value is checked, because some directives such as ErrorLog,
can take values that are not paths (i.e. a piped command or
syslog:facility).  The /dev/null equivalent for the operating system
is not treated as a path, since on some operating systems the
/dev/null equivalent is not a file, such as nul on Windows.

The method actually does not check if its value is a path, rather it
checks if the value does not match all of the other possible non-path
values for the specific directive because different operating systems
have different path formats, such as Unix, Windows and Macintosh.

=cut

# Define these constant subroutines as the different types of paths to
# check for in _value_is_path_or_abs_path_or_rel_path.
sub CHECK_TYPE_ABS        () { 'abs' }
sub CHECK_TYPE_REL        () { 'rel' }
sub CHECK_TYPE_ABS_OR_REL () { 'abs_or_rel' }

# This is a function that does the work for value_is_path,
# orig_value_is_path, value_is_abs_path, orig_value_is_abs_path,
# value_is_rel_path and orig_value_is_rel_path.
sub _value_is_path_or_abs_path_or_rel_path {
  unless (@_ == 4) {
    confess "$0: Apache::ConfigParser::Directive::",
            "_value_is_path_or_abs_path_or_rel_path ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my ($self,
      $check_type,
      $array_var_name,
      $value_path_index) = @_;

  unless ($check_type eq CHECK_TYPE_ABS or
          $check_type eq CHECK_TYPE_REL or
          $check_type eq CHECK_TYPE_ABS_OR_REL) {
    confess "$0: Apache::ConfigParser::Directive::",
            "_value_is_path_or_abs_path_or_rel_path ",
            "passed invalid check_type value '$check_type'.\n";
  }

  if (defined $value_path_index and $value_path_index !~ /^\d+$/) {
    confess "$0: Apache::ConfigParser::Directive::",
            "_value_is_path_or_abs_path_or_rel_path ",
            "passed invalid value_path_index value '$value_path_index'.\n";
  }

  my $array_ref = $self->{$array_var_name};

  unless ($array_ref) {
    return 0;
  }

  my $directive_name = $self->name;

  unless (defined $directive_name and length $directive_name) {
    return 0;
  }

  # Check if there is an index into the value array that can take a
  # path.
  my $first_value_path_index =
    $directive_value_path_element_pos{$directive_name};
  unless (defined $first_value_path_index and length $first_value_path_index) {
    return 0;
  }

  # If the index into the value array was specified, then check if the
  # value in the index can take a path.  If the index was not
  # specified, then use the first value index that can contain a path.
  if (defined $value_path_index) {
    if (substr($first_value_path_index, 0, 1) eq '-') {
      return 0 if $value_path_index <  abs($first_value_path_index);
    } else {
      return 0 if $value_path_index != $first_value_path_index;
    }
  } else {
    $value_path_index = abs($first_value_path_index);
  }
  my $path = $array_ref->[$value_path_index];

  unless (defined $path and length $path) {
    return 0;
  }

  if (is_dev_null($path)) {
    return 0;
  }

  # Get the subroutine that will check if the directive value is a
  # path.  If there is no subroutine for the directive, then it
  # doesn't take a path.
  my $sub_ref;
  if ($check_type eq CHECK_TYPE_ABS) {
    $sub_ref = $directive_value_takes_abs_path{$directive_name};
  } elsif ($check_type eq CHECK_TYPE_REL) {
    $sub_ref = $directive_value_takes_rel_path{$directive_name};
  } elsif ($check_type eq CHECK_TYPE_ABS_OR_REL) {
    $sub_ref = $directive_value_takes_abs_path{$directive_name};
    unless (defined $sub_ref) {
      $sub_ref = $directive_value_takes_rel_path{$directive_name};
    }
  } else {
    confess "$0: internal error: check_type case '$check_type' not handled.\n";
  }

  unless ($sub_ref) {
    return 0;
  }

  my $result = &$sub_ref($path);
  if ($result) {
    return 1 if $check_type eq CHECK_TYPE_ABS_OR_REL;

    if ($check_type eq CHECK_TYPE_ABS) {
      return File::Spec->file_name_is_absolute($path) ? 1 : 0;
    } elsif ($check_type eq CHECK_TYPE_REL) {
      return File::Spec->file_name_is_absolute($path) ? 0 : 1;
    } else {
      confess "$0: internal error: check_type case ",
              "'$check_type' not handled.\n";
    }
  } else {
    return 0;
  }
}

sub value_is_path {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::value_is_path ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  _value_is_path_or_abs_path_or_rel_path($_[0],
                                         CHECK_TYPE_ABS_OR_REL,
                                         'value_array',
                                         $_[1]);
}

=item $d->orig_value_is_path

=item $d->orig_value_is_path($index_into_value_array)

This has the same behavior as C<< $d->value_is_path >> except the results
are applicable to C<$d>'s 'original' value array.

=cut

sub orig_value_is_path {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::orig_value_is_path ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  _value_is_path_or_abs_path_or_rel_path($_[0],
					 CHECK_TYPE_ABS_OR_REL,
					 'orig_value_array',
					 $_[1]);
}

=item $d->value_is_abs_path

=item $d->value_is_abs_path($index_into_value_array)

Returns true if C<$d>'s directive can take a file or directory path in
the specified value array element (indexed by $index_into_value_array
or the first path element for the particular directive if
$index_into_value_array is not provided) and if the value is an
absolute file or directory path.  Both the directive name and the
value is checked, because some directives such as ErrorLog, can take
values that are not paths (i.e. a piped command or syslog:facility).
The /dev/null equivalent for the operating system is not treated as a
path, since on some operating systems the /dev/null equivalent is not
a file, such as nul on Windows.

The method actually does not check if its value is a path, rather it
checks if the value does not match all of the other possible non-path
values for the specific directive because different operating systems
have different path formats, such as Unix, Windows and Macintosh.

=cut

sub value_is_abs_path {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::value_is_abs_path ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  _value_is_path_or_abs_path_or_rel_path($_[0],
                                         CHECK_TYPE_ABS,
                                         'value_array',
                                         $_[1]);
}

=item $d->orig_value_is_abs_path

=item $d->orig_value_is_abs_path($index_into_value_array)

This has the same behavior as C<< $d->value_is_abs_path >> except the
results are applicable to C<$d>'s 'original' value array.

=cut

sub orig_value_is_abs_path {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::orig_value_is_abs_path ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  _value_is_path_or_abs_path_or_rel_path($_[0],
					 CHECK_TYPE_ABS,
					 'orig_value_array',
					 $_[1]);
}

=item $d->value_is_rel_path

=item $d->value_is_rel_path($index_into_value_array)

Returns true if C<$d>'s directive can take a file or directory path in
the specified value array element (indexed by $index_into_value_array
or the first path element for the particular directive if
$index_into_value_array is not provided) and if the value is a
relative file or directory path.  Both the directive name and the
value is checked, because some directives such as ErrorLog, can take
values that are not paths (i.e. a piped command or syslog:facility).
The /dev/null equivalent for the operating system is not treated as a
path, since on some operating systems the /dev/null equivalent is not
a file, such as nul on Windows.

The method actually does not check if its value is a path, rather it
checks if the value does not match all of the other possible non-path
values for the specific directive because different operating systems
have different path formats, such as Unix, Windows and Macintosh.

=cut

sub value_is_rel_path {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::value_is_rel_path ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  _value_is_path_or_abs_path_or_rel_path($_[0],
                                         CHECK_TYPE_REL,
                                         'value_array',
                                         $_[1]);
}

=item $d->orig_value_is_rel_path

=item $d->orig_value_is_rel_path($index_into_value_array)

This has the same behavior as C<< $d->value_is_rel_path >> except the
results are applicable to C<$d>'s 'original' value array.

=cut

sub orig_value_is_rel_path {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::orig_value_is_rel_path ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  _value_is_path_or_abs_path_or_rel_path($_[0],
					 CHECK_TYPE_REL,
					 'orig_value_array',
					 $_[1]);
}

=item $d->filename

=item $d->filename($filename)

In the first form get the filename where this particular directive or
context appears.  In the second form set the new filename of the
directive or context and return the original filename.

=cut

sub filename {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::filename ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;
  if (@_) {
    my $old           = $self->{filename};
    $self->{filename} = $_[0];
    return $old;
  } else {
    return $self->{filename};
  }
}

=item $d->line_number

=item $d->line_number($line_number)

In the first form get the line number where the directive or context
appears in a filename.  In the second form set the new line number of
the directive or context and return the original line number.

=cut

sub line_number {
  unless (@_ < 3) {
    confess "$0: Apache::ConfigParser::Directive::line_number ",
            $INCORRECT_NUMBER_OF_ARGS;
  }

  my $self = shift;
  if (@_) {
    my $old              = $self->{line_number};
    $self->{line_number} = $_[0];
    return $old;
  } else {
    return $self->{line_number};
  }
}

=back

=head1 EXPORTED VARIABLES

The following variables are exported via C<@EXPORT_OK>.

=over 4

=item DEV_NULL

The string representation of the null device on this operating system.

=item DEV_NULL_LC

The lowercase version of DEV_NULL.

=item is_dev_null($path)

On a case sensitive system, compares $path to DEV_NULL and on a case
insensitive system, compares lc($path) to DEV_NULL_LC.

=item %directive_value_takes_abs_path

This hash is keyed by the lowercase version of a directive name.  This
hash is keyed by all directives that accept a file or directory path
value as its first value array element. The hash value is a subroutine
reference to pass the value array element containing the file,
directory, pipe or syslog entry to.  If a hash entry exists for a
particular entry, then the directive name can take either a relative
or absolute path to either a file or directory.  The hash does not
distinguish between directives that take only filenames, only
directories or both, and it does not distinguish if the directive
takes only absolute, only relative or both types of paths.

The hash value for the lowercase directive name is a subroutine
reference.  The subroutine returns 1 if its only argument is a path
and 0 otherwise.  The /dev/null equivalent (C<< File::Spec->devnull >>)
for the operating system being used is not counted as a path, since on
some operating systems the /dev/null equivalent is not a filename,
such as nul on Windows.

The subroutine actually does not check if its argument is a path,
rather it checks if the argument does not match one of the other
possible non-path values for the specific directive because different
operating systems have different path formats, such as Unix, Windows
and Macintosh.  For example, ErrorLog can take a filename, such as

  ErrorLog /var/log/httpd/error_log

or a piped command, such as

  ErrorLog "| cronolog /var/log/httpd/%Y/%m/%d/error.log"

or a syslog entry of the two forms:

  ErrorLog syslog
  ErrorLog syslog:local7

The particular subroutine for ErrorLog checks if the value is not
equal to C<< File::Spec->devnull >>, does not begin with a | or does not
match syslog(:[a-zA-Z0-9]+)?.

These subroutines do not remove any "'s before checking on the type of
value.

This hash is used by C<value_is_path> and C<orig_value_is_path>.

This is a list of directives and any special values to check for as of
Apache 1.3.20 with the addition of IncludeOptional from 2.4.x.

  AccessConfig
  AgentLog          check for "| prog"
  AuthDBGroupFile
  AuthDBMGroupFile
  AuthDBMUserFile
  AuthDBUserFile
  AuthDigestFile
  AuthGroupFile
  AuthUserFile
  CacheRoot
  CookieLog
  CoreDumpDirectory
  CustomLog         check for "| prog"
  Directory
  DocumentRoot
  ErrorLog          check for "| prog", or syslog or syslog:facility
  Include
  IncludeOptional
  LoadFile
  LoadModule
  LockFile
  MimeMagicFile
  MMapFile
  PidFile
  RefererLog        check for "| prog"
  ResourceConfig
  RewriteLock
  ScoreBoardFile
  ScriptLog
  ServerRoot
  TransferLog       check for "| prog"
  TypesConfig

=item %directive_value_takes_rel_path

This hash is keyed by the lowercase version of a directive name.  This
hash contains only those directive names that can accept both relative
and absolute file or directory names.  The hash value is a subroutine
reference to pass the value array element containing the file,
directory, pipe or syslog entry to.  The hash does not distinguish
between directives that take only filenames, only directories or both.

The hash value for the lowercase directive name is a subroutine
reference.  The subroutine returns 1 if its only argument is a path
and 0 otherwise.  The /dev/null equivalent (C<< File::Spec->devnull >>)
for the operating system being used is not counted as a path, since on
some operating systems the /dev/null equivalent is not a filename,
such as nul on Windows.

The subroutine actually does not check if its argument is a path,
rather it checks if the argument does not match one of the other
possible non-path values for the specific directive because different
operating systems have different path formats, such as Unix, Windows
and Macintosh.  For example, ErrorLog can take a filename, such as

  ErrorLog /var/log/httpd/error_log

or a piped command, such as

  ErrorLog "| cronolog /var/log/httpd/%Y/%m/%d/error.log"

or a syslog entry of the two forms:

  ErrorLog syslog
  ErrorLog syslog:local7

The particular subroutine for ErrorLog checks if the value is not
equal to C<< File::Spec->devnull >>, does not begin with a | or does not
match syslog(:[a-zA-Z0-9]+)?.

These subroutines do not remove any "'s before checking on the type of
value.

This hash is used by C<value_is_rel_path> and
C<orig_value_is_rel_path>.

This is a list of directives and any special values to check for as of
Apache 1.3.20 with the addition of IncludeOptional from 2.4.x.

AccessFileName is not a key in the hash because, while its value is
one or more relative paths, the ServerRoot is never prepended to it as
the AccessFileName values are looked up in every directory of the path
to the document being requested.

  AccessConfig
  AuthGroupFile
  AuthUserFile
  CookieLog
  CustomLog         check for "| prog"
  ErrorLog          check for "| prog", or syslog or syslog:facility
  Include
  IncludeOptional
  LoadFile
  LoadModule
  LockFile
  MimeMagicFile
  PidFile
  RefererLog        check for "| prog"
  ResourceConfig
  ScoreBoardFile
  ScriptLog
  TransferLog       check for "| prog"
  TypesConfig

=item %directive_value_path_element_pos

This hash holds the indexes into the directive value array for the
value or values that can contain either absolute or relative file or
directory paths.  This hash is keyed by the lowercase version of a
directive name.  The hash value is a string representing an integer.
The string can take two forms:

  /^\d+$/   The directive has only one value element indexed by \d+
            that takes a file or directory path.

  /^-\d+$/  The directive takes any number of file or directory path
            elements beginning with the abs(\d+) element.

For example:

  # CustomLog logs/access_log common
  $directive_value_path_element_pos{customlog}  eq '0';

  # LoadFile modules/mod_env.so libexec/mod_mime.so
  $directive_value_path_element_pos{loadfile}   eq '-0';

  # LoadModule env_module modules/mod_env.so
  $directive_value_path_element_pos{loadmodule} eq '1';

  # PidFile logs/httpd.pid
  $directive_value_path_element_pos{pidfile}    eq '0';

=back

=cut

sub directive_value_is_not_dev_null {
  !is_dev_null($_[0]);
}

sub directive_value_is_not_dev_null_and_pipe {
  if (is_dev_null($_[0])) {
    return 0;
  }

  return $_[0] !~ /^\s*\|/;
}

sub directive_value_is_not_dev_null_and_pipe_and_syslog {
  if (is_dev_null($_[0])) {
    return 0;
  }

  return $_[0] !~ /^\s*(?:(?:\|)|(?:syslog(?::[a-zA-Z0-9]+)?))/;
}

# This is a hash keyed by directive name and the value is an array
# reference.  The array element are
#   array    array
#   index    value
#       0    A string containing an integer that describes the element
#            position(s) that contains the file or directory path.
#            string =~ /^\d+/   a single element that contains a path
#            string =~ /^-\d+/  multiple elements, first is abs(\d+)
#       1    1 if the paths the directive accepts can be absolute and
#            relative, 0 if they can only be absolute
#       2    a subroutine reference to directive_value_is_not_dev_null,
#            directive_value_is_not_dev_null_and_pipe or
#            directive_value_is_not_dev_null_and_pipe_and_syslog.

my %directive_info = (
  AccessConfig      => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  AuthDBGroupFile   => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  AuthDBMGroupFile  => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  AuthDBMUserFile   => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  AuthDBUserFile    => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  AuthDigestFile    => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  AgentLog          => ['0',
                        0,
                        \&directive_value_is_not_dev_null_and_pipe],
  AuthGroupFile     => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  AuthUserFile      => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  CacheRoot         => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  CookieLog         => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  CoreDumpDirectory => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  CustomLog         => ['0',
                        1,
                        \&directive_value_is_not_dev_null_and_pipe],
  Directory         => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  DocumentRoot      => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  ErrorLog          => ['0',
                        1,
                        \&directive_value_is_not_dev_null_and_pipe_and_syslog],
  Include           => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  IncludeOptional   => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  LoadFile          => ['-0',
                        1,
                        \&directive_value_is_not_dev_null],
  LoadModule        => ['1',
                        1,
                        \&directive_value_is_not_dev_null],
  LockFile          => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  MMapFile          => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  MimeMagicFile     => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  PidFile           => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  RefererLog        => ['0',
                        1,
                        \&directive_value_is_not_dev_null_and_pipe],
  ResourceConfig    => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  RewriteLock       => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  ScoreBoardFile    => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  ScriptLog         => ['0',
                        1,
                        \&directive_value_is_not_dev_null],
  ServerRoot        => ['0',
                        0,
                        \&directive_value_is_not_dev_null],
  TransferLog       => ['0',
                        1,
                        \&directive_value_is_not_dev_null_and_pipe],
  TypesConfig       => ['0',
                        1,
                        \&directive_value_is_not_dev_null]);

# Set up the three exported hashes using the information in
# %directive_info.  Use lowercase directive names.
foreach my $key (keys %directive_info) {
  my $ref                                    = $directive_info{$key};
  my $lc_key                                 = lc($key);
  my ($index, $abs_and_rel, $sub_ref)        = @$ref;
  if ($abs_and_rel) {
    $directive_value_takes_rel_path{$lc_key} = $sub_ref;
  }
  $directive_value_takes_abs_path{$lc_key}   = $sub_ref;
  $directive_value_path_element_pos{$lc_key} = $index;
}

=head1 SEE ALSO

L<Apache::ConfigParser::Directive> and L<Tree::DAG_Node>.

=head1 AUTHOR

Blair Zajac <blair@orcaware.com>.

=head1 COPYRIGHT

Copyright (C) 2001-2005 Blair Zajac.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
