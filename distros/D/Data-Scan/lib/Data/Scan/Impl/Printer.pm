use strict;
use warnings FATAL => 'all';

package Data::Scan::Impl::Printer;

# ABSTRACT: Data::Scan printer implementation

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


use Moo;

use B::Deparse;
use Class::Inspector;
use Perl::OSType qw/is_os_type/;
my $_HAVE_Win32__Console__ANSI;
BEGIN {
  #
  # Will/Should success only on Win32
  #
  $_HAVE_Win32__Console__ANSI = eval 'use Win32::Console::ANSI; 1;' ## no critic qw/BuiltinFunctions::ProhibitStringyEval/
}
use Scalar::Util 1.26 qw/reftype refaddr looks_like_number/;
use Term::ANSIColor;
use Types::Standard -all;
use Types::Common::Numeric -all;
#
# My way of matching only printable ASCII characters
#
my $_ASCII_PRINT = quotemeta(join('', map { chr } (32,33..126)));
my $_NON_ASCII_PRINT_RE = qr/[^$_ASCII_PRINT]/;
#
# Avoid calls to arybase and predictible results
#
my $ARRAY_START_INDICE         = $[;
my $ARRAY_START_INDICE_PLUS_1  = $ARRAY_START_INDICE + 1;
my $ARRAY_START_INDICE_PLUS_2  = $ARRAY_START_INDICE_PLUS_1 + 1;
my $ARRAY_START_INDICE_PLUS_3  = $ARRAY_START_INDICE_PLUS_2 + 1;
my $ARRAY_START_INDICE_MINUS_1 = $ARRAY_START_INDICE - 1;



has handle            => (is => 'ro', isa => FileHandle,       default => sub { return \*STDOUT  });


has indent            => (is => 'ro', isa => Str,              default => sub { return '  '      });


has max_depth         => (is => 'ro', isa => PositiveOrZeroInt, default => sub { return 0        });


has undef             => (is => 'ro', isa => Str,              default => sub { return 'undef'   });


has unknown           => (is => 'ro', isa => Str,              default => sub { return '???'     });


has newline           => (is => 'ro', isa => Str,              default => sub { return "\n"      });


has with_ansicolor    => (is => 'ro', isa => Bool,             default => sub { return __PACKAGE__->_canColor });


has array_start       => (is => 'ro', isa => Str,              default => sub { return '['      });


has array_next        => (is => 'ro', isa => Str,              default => sub { return ','       });


has array_end         => (is => 'ro', isa => Str,              default => sub { return ']'       });


has hash_start        => (is => 'ro', isa => Str,              default => sub { return ' {'      });


has hash_next         => (is => 'ro', isa => Str,              default => sub { return ','       });


has hash_end          => (is => 'ro', isa => Str,              default => sub { return '}'       });


has hash_separator    => (is => 'ro', isa => Str,              default => sub { return ' => '    });


has indice_start          => (is => 'ro', isa => Str,              default => sub { return '['       });


has indice_end          => (is => 'ro', isa => Str,              default => sub { return '] '      });


has with_indices_full => (is => 'ro', isa => Bool,             default => sub { return !!0       });


has address_start     => (is => 'ro', isa => Str,              default => sub { return '('       });


has address_format    => (is => 'ro', isa => Str,              default => sub { return '0x%x'    });


has address_end       => (is => 'ro', isa => Str,              default => sub { return ')'       });


has ref_start         => (is => 'ro', isa => Str,              default => sub { return '\\'      });


has ref_end           => (is => 'ro', isa => Str,              default => sub { return ''        });


has with_address      => (is => 'ro', isa => Bool,             default => sub { return !!0       });


has with_array_indice => (is => 'ro', isa => Bool,             default => sub { return !!1       });


has with_hash_indice  => (is => 'ro', isa => Bool,             default => sub { return !!1       });


has with_deparse      => (is => 'ro', isa => Bool,             default => sub { return !!0       });


has with_methods      => (is => 'ro', isa => Bool,             default => sub { return !!0       });


has with_filename     => (is => 'ro', isa => Bool,             default => sub { return !!0       });


has buffered          => (is => 'ro', isa => Bool,             default => sub { return !!0       });


has colors            => (is => 'ro', isa => HashRef[Str|Undef], default => sub {
                            return {
                                    blessed         => 'bold',
                                    string          => undef,
                                    regexp          => undef,

                                    array_start     => 'blue',
                                    array_next      => 'blue',
                                    array_end       => 'blue',

                                    hash_start      => 'blue',
                                    hash_separator  => 'blue',
                                    hash_next       => 'blue',
                                    hash_end        => 'blue',

                                    ref_start       => undef,
                                    ref_end         => undef,

                                    indice_full     => 'magenta',
                                    indice_start    => 'magenta',
                                    indice_value    => 'magenta',
                                    indice_end      => 'magenta',

                                    undef           => 'red',
                                    unknown         => 'bold red',
                                    address_start   => 'magenta',
                                    address_value   => 'magenta',
                                    address_end     => 'magenta',
                                    code            => 'yellow',
                                    already_scanned => 'green'
                                   }
                          }
                         );
#
# Internal attributes - Note that they are ALL explicitely setted in dsstart()
# and because they are internal we give us the right to access them
# in the dirty way
#
has _lines                  => (is => 'rwp', isa => Undef|ArrayRef[ArrayRef]);
has _currentLevel           => (is => 'rwp', isa => Undef|PositiveOrZeroInt);
has _currentIndicePerLevel  => (is => 'rwp', isa => Undef|ArrayRef[PositiveOrZeroInt]);
has _currentReftypePerLevel => (is => 'rwp', isa => Undef|ArrayRef[Str]);
has _seen                   => (is => 'rwp', isa => Undef|HashRef[PositiveOrZeroInt]);
has _indice_start_nospace   => (is => 'rwp', isa => Undef|Str);  # C.f. BUILD
has _indice_end_nospace     => (is => 'rwp', isa => Undef|Str);
has _colors_cache           => (is => 'rwp', isa => Undef|HashRef[Str|Undef]);
has _concatenatedLevels     => (is => 'rwp', isa => Undef|ArrayRef[Str]);

#
# Required methods
#


sub dsstart  {
  my ($self, @args) = @_;

  $self->_set__lines([[]]);
  $self->_set__currentLevel(0);
  $self->_set__currentIndicePerLevel([]);
  $self->_set__currentReftypePerLevel([]);
  $self->_set__seen({});
  $self->_set__concatenatedLevels([]);

  my $indice_start_nospace = $self->indice_start;
  my $indice_end_nospace = $self->indice_end;
  $indice_start_nospace =~ s/\s//g;
  $indice_end_nospace =~ s/\s//g;
  $self->_set__indice_start_nospace($indice_start_nospace);
  $self->_set__indice_end_nospace($indice_end_nospace);
  #
  # Precompute color attributes
  #
  $self->_set__colors_cache({});
  if ($self->with_ansicolor) {
    foreach (keys %{$self->colors}) {
      my $color = $self->colors->{$_};
      if (defined($color)) {
        my $colored = colored('dummy', $color);
        #
        # ANSI color spec is clear: attributes before the string, followed by
        # the string, followed by "\e[0m". We do not support the eventual
        # $EACHLINE hack.
        #
        if ($colored =~ /(.+)dummy\e\[0m$/) {
          $self->{_colors_cache}->{$_} = substr($colored, $-[1], $+[1] - $-[1])
        } else {
          $self->{_colors_cache}->{$_} = undef
        }
      } else {
        $self->{_colors_cache}->{$_} = undef
      }
    }
  } else {
    foreach (keys %{$self->colors}) {
      $self->{_colors_cache}->{$_} = undef
    }
  }

  return
}


sub dsend {
  my ($self) = @_;

  #
  # Buffered or not, we always "flush" what remains in the _lines.
  # In fact, in the buffered mode, the previous call can be
  # a dsclose(), that may push new characters, and  there is no call
  # to _print in the later.
  #
  $self->_print;

  $self->_set__lines                 (undef);
  $self->_set__currentLevel          (undef);
  $self->_set__currentIndicePerLevel (undef);
  $self->_set__currentReftypePerLevel(undef);
  $self->_set__seen                  (undef);
  $self->_set__indice_start_nospace  (undef);
  $self->_set__indice_end_nospace    (undef);
  $self->_set__colors_cache          (undef);
  $self->_set__concatenatedLevels    (undef);

  return !!1
}

sub _print {
  my ($self) = @_;

  return if (! @{$self->{_lines}});

  my $output = join($self->newline, map { join('', @{$_}) } @{$self->{_lines}});
  my $handle = $self->handle;
  if (Scalar::Util::blessed($handle) && $handle->can('print')) {
    $handle->print($output)
  } else {
    print $handle $output
  }

  return $self->_set__lines([[]])
}


sub dsopen {
  my ($self, $item) = @_;

  my $reftype = reftype $item;
  my $blessed = Scalar::Util::blessed $item;

  if    ($reftype eq 'ARRAY') { $self->_pushDesc('array_start', $self->array_start) }
  elsif ($reftype eq 'HASH')  { $self->_pushDesc('hash_start',  $self->hash_start)  }
  else                        { $self->_pushDesc('ref_start',   $self->ref_start)   }

  #
  # Precompute the string describing previous level.
  # Here $self->{_currentLevel} is the value before we increase it
  #
  if ($self->{_currentLevel}) {
    push(@{$self->{_concatenatedLevels}},
         $self->{_concatenatedLevels}->[-1] .
         $self->_indice_start_nospace .
         $self->{_currentIndicePerLevel}->[-1] .
         $self->_indice_end_nospace)
  } else {
    push(@{$self->{_concatenatedLevels}}, '')
  }

  $self->_pushLevel($reftype);
  return
}


sub dsclose {
  my ($self, $item) = @_;

  #
  # Remove precomputed string describing this level.
  #
  pop(@{$self->{_concatenatedLevels}});

  $self->_popLevel;

  my $reftype = reftype $item;
  if    ($reftype eq 'ARRAY') { $self->_pushLine; $self->_pushDesc('array_end', $self->array_end) }
  elsif ($reftype eq 'HASH')  { $self->_pushLine; $self->_pushDesc('hash_end',  $self->hash_end)  }
  else                        {                   $self->_pushDesc('ref_end',   $self->ref_end)   }

  return
}


sub dsread {
  my ($self, $item) = @_;

  my $refaddr = refaddr($item);
  my $blessed = Scalar::Util::blessed($item) // '';
  my $reftype = reftype($item) // '';
  #
  # Precompute things that always have the same value
  #
  my $indice_start                   = $self->indice_start;
  my $indice_end                     = $self->indice_end;
  my $indice_start_nospace           = $self->_indice_start_nospace;
  my $indice_end_nospace             = $self->_indice_end_nospace;
  #
  # Increase indice if we reading something unfolded
  #
  my $currentLevel = $self->{_currentLevel};
  my $currentIndicePerLevel = $currentLevel ? ++$self->{_currentIndicePerLevel}->[-1] : undef;
  #
  # Push a newline or a '=>' and prefix with indice if in a fold
  #
  if ($currentLevel) {
    my $currentReftypePerLevel = $self->{_currentReftypePerLevel}->[-1];
    if ($currentReftypePerLevel eq 'ARRAY' or $currentReftypePerLevel eq 'HASH') {
      my $show_indice;
      if ($currentReftypePerLevel eq 'ARRAY') {
        $self->_pushDesc('array_next', $self->array_next) if ($currentIndicePerLevel > $ARRAY_START_INDICE);
        $self->_pushLine;
        $show_indice = $self->with_array_indice
      } else {
        if ($currentIndicePerLevel % 2) {
          $self->_pushDesc('hash_separator', $self->hash_separator)
        } else {
          $self->_pushDesc('hash_next', $self->hash_next) if ($currentIndicePerLevel > 0);
          $self->_pushLine
        }
        $show_indice = $self->with_hash_indice
      }
      if ($show_indice) {
        if ($self->with_indices_full) {
          #
          # We know that $self->{_concatenatedLevels} is an ArrayRef.
          # $currentLevel is a true value, this mean there is at least
          # one element in $self->{_concatenatedLevels}.
          #
          $self->_pushDesc('indice_full', $self->{_concatenatedLevels}->[-1] . $indice_start_nospace . $currentIndicePerLevel . $indice_end_nospace)
        } else {
          $self->_pushDesc('indice_start', $indice_start);
          $self->_pushDesc('indice_value', $currentIndicePerLevel);
          $self->_pushDesc('indice_end', $indice_end)
        }
      }
    }
  }
  #
  # See how this can be displayed
  #
  my $alreadyScanned;
  if ($refaddr) {
    if (exists($self->{_seen}->{$refaddr})) {
      $alreadyScanned = $self->{_seen}->{$refaddr};
      #
      # Already scanned !
      #
      $self->_pushDesc('already_scanned', $alreadyScanned)
    } else {
      #
      # Determine the "location" in terms of an hypothetical "@var" describing the tree
      #
      my $var = 'var';
      #
      # Note the if ($currentLevel) at the end
      #
      $var .= $self->{_concatenatedLevels}->[-1] . $indice_start_nospace . $currentIndicePerLevel . $indice_end_nospace if ($currentLevel);
      $self->{_seen}->{$refaddr} = $var
    }
  }
  if (! $alreadyScanned) {
    if ($blessed && $reftype ne 'REGEXP') {
      #
      # A regexp appears as being blessed in perl.
      # Priority is given to blessed name except if it is a regexp.
      #
      $self->_pushDesc('blessed', $blessed)
    } elsif ($reftype eq 'CODE' && $self->with_deparse) {
      #
      # Code deparse with B::Deparse
      #
      my $i = length($self->indent) x ($self->{_currentLevel} + 2);
      my $deparseopts = ["-sCv'Useless const omitted'"];
      my $code = eval { 'sub ' . B::Deparse->new($deparseopts)->coderef2text($item) };
      goto CODE_fallback if $@;
      my @code = split(/\R/, $code);
      #
      # First item is not aligned
      #
      $self->_pushDesc('code', shift(@code));
      #
      # The rest is aligned
      #
      if (@code) {
        $self->_pushLevel($reftype);
        map { $self->_pushLine; $self->_pushDesc('code', $_) } @code;
        $self->_popLevel
      }
    } elsif ((! $reftype)
               ||
               (
                $reftype ne 'ARRAY'  &&
                $reftype ne 'HASH'   &&
                $reftype ne 'SCALAR' &&
                $reftype ne 'REF'
               )
              ) {
      #
      # Stringify if possible everything that we do not unfold
      #
      CODE_fallback:
      if (defined($item)) {
        my $string = eval { "$item" }; ## no critic qw/BuiltinFunctions::ProhibitStringyEval/
        if (defined($string)) {
          $self->_pushDesc($reftype eq 'REGEXP' ? 'regexp' :
                           $reftype eq 'CODE' ? 'code' :
                           'string', $string)
        } else {
          $self->_pushDesc('unknown', $self->unknown)
        }
      } else {
        $self->_pushDesc('undef', $self->undef)
      }
    }
    #
    # Show address ?
    #
    if ($refaddr && $self->with_address) {
      my $address_format = $self->address_format;
      $self->_pushDesc('address_start', $self->address_start);
      $self->_pushDesc('address_value', length($address_format) ? sprintf($address_format, $refaddr) : $refaddr);
      $self->_pushDesc('address_end', $self->address_end)
    }
  }
  #
  # Eventually increase indice number
  #
  #
  # Prepare return value
  #
  my ($rc, $max_depth);
  #
  # Max depth option value ?
  #
  if (! ($max_depth = $self->max_depth) || ($currentLevel < $max_depth)) {
    #
    # Unfold if not already done and if this can be unfolded
    #
    if (! $alreadyScanned) {
      if ($reftype) {
        if ($reftype eq 'ARRAY') {
          $rc = $item
        } elsif ($reftype eq 'HASH') {
          $rc = [ map { $_ => $item->{$_} } sort { ($a // '') cmp ($b // '') } keys %{$item} ]
        } elsif ($reftype eq 'SCALAR') {
          $rc = [ ${$item} ]
        } elsif ($reftype eq 'REF') {
          $rc = [ ${$item} ]
        }
      }
      if ($blessed && $self->with_methods) {
        $rc //= [];
        my $expanded = Class::Inspector->methods($blessed, 'expanded');
        if (defined($expanded) && reftype($expanded) eq 'ARRAY') {
          my @expanded = @{$expanded};
          my %public_methods =
            map  { $_->[$ARRAY_START_INDICE_PLUS_2] => $_->[$ARRAY_START_INDICE_PLUS_3] }
            grep { $_->[$ARRAY_START_INDICE_PLUS_2] !~ /^\_/   }
            grep { $_->[$ARRAY_START_INDICE_PLUS_1] eq $blessed }
            @expanded;
          my %private_methods =
            map  { $_->[$ARRAY_START_INDICE_PLUS_2] => $_->[$ARRAY_START_INDICE_PLUS_3] }
            grep { $_->[$ARRAY_START_INDICE_PLUS_2] =~ /^\_/   }
            grep { $_->[$ARRAY_START_INDICE_PLUS_1] eq $blessed }
            @expanded;
          my %inherited_methods =
            map  { $_->[$ARRAY_START_INDICE_PLUS_2] => $_->[$ARRAY_START_INDICE_PLUS_3] }
            grep { $_->[$ARRAY_START_INDICE_PLUS_1] ne $blessed } @expanded;
          push(@{$rc}, {
                        public_methods     => \%public_methods,
                        private_methods    => \%private_methods,
                        inherited_methods  => \%inherited_methods
                       }
              )
        }
        if ($self->with_filename) {
          if (Class::Inspector->loaded($blessed)) {
            push(@{$rc}, { filename => Class::Inspector->loaded_filename($blessed) })
          } else {
            push(@{$rc}, { filename => Class::Inspector->resolved_filename($blessed) })
          }
        }
      }
    }
  }

  $self->_print unless $self->buffered;
  return $rc
}
#
# Internal methods
#
sub _pushLevel {
  my ($self, $reftype) = @_;

  push(@{$self->{_currentReftypePerLevel}}, $reftype);
  push(@{$self->{_currentIndicePerLevel}}, $ARRAY_START_INDICE_MINUS_1); # dsread() will increase it at every item
  return ++$self->{_currentLevel}
}

sub _popLevel {
  my ($self) = @_;

  pop(@{$self->{_currentReftypePerLevel}});
  pop(@{$self->{_currentIndicePerLevel}});
  return --$self->{_currentLevel}
}

sub _pushLine {
  my ($self) = @_;

  return push(@{$self->{_lines}}, [ $self->indent x $self->{_currentLevel} ]);
}

sub _pushDesc {
  my ($self, $what, $desc) = @_;

  if ($what eq 'string' && ! looks_like_number($desc)) {
    #
    # Detect any non ANSI character and enclose result within ""
    #
    $desc =~ s/$_NON_ASCII_PRINT_RE/sprintf('\\x{%x}', ord(${^MATCH}))/egpo;
    $desc = "\"$desc\""
  }
  if ($self->with_ansicolor) {
    #
    # We know that _colors_cache is a HashRef, and that _lines is an ArrayRef
    #
    my $color_cache = $self->{_colors_cache}->{$what};  # Handled below if it does not exist or its value is undef
    $desc = $color_cache . $desc . "\e[0m" if (defined($color_cache))
  }
  push(@{$self->{_lines}->[-1]}, $desc);

  return
}

sub _canColor {
  my ($class) = @_;
  #
  # Mimic Data::Printer use of $ENV{ANSI_COLORS_DISABLED}
  #
  return 0 if exists($ENV{ANSI_COLORS_DISABLED});
  #
  # Add the support of ANSI_COLORS_ENABLED
  #
  return 1 if exists($ENV{ANSI_COLORS_ENABLED});
  #
  # that has precedence on the Windows check, returning 0 if we did not load Win32::Console::ANSI
  #
  return 0 if (is_os_type('Windows') && ! $_HAVE_Win32__Console__ANSI);
  return 1
}


with 'Data::Scan::Role::Consumer';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Scan::Impl::Printer - Data::Scan printer implementation

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use Data::Scan;
    use Data::Scan::Impl::Printer;

    my $this = bless([ 'var1', 'var2', {'a' => 'b', 'c' => 'd'}, \undef, \\undef, [], sub { return 'something' } ], 'TEST');
    my $consumer = Data::Scan::Impl::Printer->new(with_deparse => 1);
    Data::Scan->new(consumer => $consumer)->process($this);

=head1 DESCRIPTION

Data::Scan::Impl::Printer is an example of an implementation of the L<Data::Scan::Role::Consumer> role.

=head1 CONSTRUCTOR OPTIONS

Here the list of supported options, every name is preceded by its type.

=head2 FileHandle handle

Handle for the output. Default is \*STDOUT.

=head2 Str indent

Indentation. Default is '  '.

=head2 PositiveOrZeroInt max_depth

Maximum unfold level. Default is 0, meaning no maximum.

=head2 Str undef

Representation of an undefined value. Default is 'undef'.

=head2 Str unknown

Representation of an unknown value. Default is '???'.

=head2 Str newline

Separator between lines. Default is "\n".

=head2 Bool with_ansicolor

Use ANSI colors. Default is a false value if $ENV{ANSI_COLORS_DISABLED} exists, else a true value if $ENV{ANSI_COLORS_ENABLED} exists, else a false value if L<Win32::Console::ANSI> cannot be loaded and you are on Windows, else a true value.

=head2 Str array_start

Representation of the start of an array. Default is '['.

=head2 Str array_next

Representation of separator between array elements. Default is ','.

=head2 Str array_end

Representation of the end of an array. Default is ']'.

=head2 Str hash_start

Representation of the start of a hash. Default is '{'.

=head2 Str hash_next

Representation of separator between hash elements, where an element is the tuple {key,value}. Default is ','.

=head2 Str hash_end

Representation of the end of a hash. Default is '}'.

=head2 Str hash_separator

Representation of hash separator between a key and a value. Default is '=>'.

=head2 Str indice_start

Representation of internal indice count start. Default is '['.

=head2 Str indice_end

Representation of internal indice count end. Default is ']'.

=head2 Bool with_indices_full

Use full internal indice representation, i.e. show indices from the top level up to current level, as if the tree would have been only composed of array references to array references, and so on. Default is a false value.

=head2 Str address_start

Representation of the start of an address. Default is '('.

=head2 Str address_format

Format of an address. Default is '0x%x'.

=head2 Str address_end

Representation of the end of an address. Default is ')'.

=head2 Str ref_start

Representation of the start of a reference. Default is '\'.

=head2 Str ref_end

Representation of the end of a reference. Default is the empty string.

=head2 Bool with_address

Show address of any reference. Default is a false value.

=head2 Bool with_array_indice

Show array indices. Default is a true value.

=head2 Bool with_hash_indice

Show hash indices. Default is a true value.

=head2 Bool with_deparse

Show deparsed subroutine references. Default is a false value.

If deparse raise an exception, the current item is shown as if with_deparse would be off, i.e. a classic stringification resulting in something like e.g. C<CODE(0x...)>.

=head2 Bool with_methods

Show public, private and inherited methods. Default is a false value.

=head2 Bool with_filename

Show loaded or resolved filename. Default is a false value.

=head2 Bool buffered

If a true value, bufferize the output and print it only at the end of the processing, otherwise print it item per item, the later is less efficient but also memory-friendly in case of large data. Default is a false value.

=head2 HashRef[Str] colors

Explicit ANSI color per functionality. The absence of a color definition means the corresponding value will be printed as-is. A color is defined following the Term::ANSIColor specification, as a string.

Supported keys of this hash and their eventual default setup is:

=over

=item string => undef

Generic stringified value.

=item blessed => 'bold'

Blessed name.

=item regexp => undef

Stringified regexp.

=item array_start => 'blue'

Array start.

=item array_next => 'blue'

Separator between array elements.

=item array_end => 'blue'

Array end.

=item hash_start => 'blue'

Hash start.

=item hash_separator => 'blue'

Separator between hash key and value.

=item hash_next => 'blue'

Separator between a hash value and the next hash key.

=item hash_end => 'blue'

Hash end.

=item ref_start => undef

Reference start.

=item ref_end => undef

Reference end.

=item indice_full => 'magenta'

Full indice.

=item indice_start => 'magenta'

Indice start.

=item indice_value => 'magenta'

Indice value.

=item indice_end => 'magenta'

Indice end.

=item undef => 'red'

The undefined value.

=item unknown => 'bold red'

An unknown value.

=item address_start => 'magenta'

Address start.

=item address_value => 'magenta'

Address value.

=item address_end => 'magenta'

Address end.

=item code => 'yellow'

Deparsed or stringified code reference.

=item already_scanned => 'green'

Already scanned reference. Such item will always be represented using "var[...]", where [...] is the full indice representation.

=back

=head1 SUBROUTINES/METHODS

=head2 dsstart

Will be called when scanning is starting. It is resetting all internal attributes used to keep the context.

=head2 dsend

Will be called when scanning is ending. Returns a true value.

=head2 dsopen

Called when an unfolded content is opened.

=head2 dsclose

Called when an unfolded content is closed.

=head2 dsread

Called when an unfolded content is read. Returns eventual unfolded content.

=head1 NOTES

If with_methods option is on, L<Class::Inspector> (and not L<Package::Stash> like what does L<Data::Printer>) is used to get public, private and other (labelled inherited, then) methods. Thus, notion of methods, usage of @ISA etc, could look different to what L<Data::Printer> say.

=head1 SEE ALSO

L<B::Deparse>, L<Class::Inspector>, L<Data::Scan::Printer>, L<Term::ANSIColor>, L<Win32::Console::ANSI>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
