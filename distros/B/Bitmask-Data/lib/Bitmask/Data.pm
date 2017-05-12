# ============================================================================
package Bitmask::Data;
# ============================================================================
use strict;
use warnings;

use parent qw(Class::Data::Inheritable);
use 5.010;

use Carp;
use Config;
use List::Util qw(reduce);
use Scalar::Util qw(blessed);

our $VERSION = version->new('2.04');
our $AUTHORITY = 'cpan:MAROS';

our $ZERO = chr(0);
our $ONE = chr(1);

=encoding utf8

=head1 NAME

Bitmask::Data - Handle unlimited length bitmasks in an easy and flexible way

=head1 SYNOPSIS

 # Create a simple bitmask class
 package MyBitmask;
 use base qw(Bitmask::Data);
 __PACKAGE__->bitmask_length(18);
 __PACKAGE__->bitmask_default('0b000000000000000011');
 __PACKAGE__->init(
    'value1' => '0b000000000000000001',
    'value2' => '0b000000000000000010',
    'value2' => '0b000000000000000100',
    'value4' => '0b000000000000001000',
    'value5' => '0b000000000000010000',
    ...
 );
 
 ## Somewhere else in your code
 use MyBitmask;
 my $bm1 = MyBitmask->new('value1','value3');
 my $bm2 = MyBitmask->new('0b000000000000010010');
 $bm1->add('value3');
 my $bm3 = $bm1 | $bm2; 
 $bm3->string;

=head1 DESCRIPTION

This package helps you dealing with bitmasks. First you need to subclass
Bitmask::Data and set the bitmask values and length. (If you are only working
with a single bitmask in a simple application you might also initialize
the bitmask directly in the Bitmask::Data module).

After the initialization you can create an arbitrary number of bitmask 
objects which can be accessed and manipulated with convenient methods and
overloaded arithmetic and bit operators.

Bitmask::Data does not store bitmasks as integers internally, but as 
strings conststing of \0 and \1, hence makinging unlimited length bitmasks
possible (32-bit perl can handle integer bitmasks only up to 40 bits).

=head1 METHODS

=head2 Class Methods

=head3 bitmask_length

Set/Get the length of the bitmask. Do not change this value after the 
initialization.

Bitmask length is unlimited.

Default: 16

=head3 bitmask_default

Set/Get the default bitmask for empty Bitmask::Data objects.

Default: undef

=head3 bitmask_lazyinit

If true value that disables warnings for lazy initialization. (Lazy 
initialization = call of init without bitmask bit values).

Default: 0

 __PACKAGE__->bitmask_lazyinit(1);
 __PACKAGE__->bitmask_length(6);
 __PACKAGE__->init(
    'value1', # will be 0b000001
    'value2', # will be 0b000010
    'value3'  # will be 0b000100
 );
 
If bitmask_lazyinit is 2 then bit values will be filled from left to right, 
otherwise from right to left
 
 __PACKAGE__->bitmask_lazyinit(2);
 __PACKAGE__->bitmask_length(6);
 __PACKAGE__->init(
    'value1', # will be 0b100000
    'value2', # will be 0b010000
    'value3'  # will be 0b001000
 );

=head3 bitmask_items

HASHREF of all bitmask items, with values as keys and bitmask as values.

=head3 init

    CLASS->init(LIST of VALUES);

Initializes the bitmask class. You can supply a list of possible values.
Optionally you can also specify the bits for the mask by adding bit values
after the value. 
 
    CLASS->init(
        'value1' => 0b000001,
        'value2' => 0b000010,
        'value3' => 0b001000,
        'value4' => 0b010000,
    );
    
With C<bitmask_lazyinit> enabled you can also skip the bitmask bit values

    CLASS->bitmask_lazyinit(1);
    CLASS->init(
        'value1',
        'value2',
        'value3',
        'value4',
    );

Bits may be supplied as integers, strings or Math::BigInt objects 
(not recommended).

    CLASS->init(
        'value1' => 0b000001,               # integer
        'value2' => 2,                      # integer
        'value3' => '0b000100'              # string starting with '0b'
        'value4' => '0B001000'              # string starting with '0B'
        'value5' => '\0\1\0\0\0\0'          # string consisting of \0 and \1
        'value6' => Math::BigInt->new("32") # Math::BigInt object
    );

=cut

__PACKAGE__->mk_classdata( bitmask_length   => 16 );
__PACKAGE__->mk_classdata( bitmask_items    => {} );
__PACKAGE__->mk_classdata( bitmask_default  => undef );
__PACKAGE__->mk_classdata( bitmask_lazyinit => 0 );
__PACKAGE__->mk_classdata( bitmask_empty    => undef );
__PACKAGE__->mk_classdata( bitmask_full     => undef );

use overload 
    '<=>'   => '_compare',
    'cmp'   => '_compare',
    '=='    => '_equals',
    'eq'    => '_equals',
    '~~'    => sub {
        my ($self,$value) = @_; 
        my $bitmask = $self->any2bitmask($value);
        return (($bitmask & $self->{bitmask}) ne $self->bitmask_empty)  ? 1:0;
    },
    'bool'  => sub {
         my ($self) = @_; 
         return ($self->{bitmask} ne $self->bitmask_empty) ? 1:0;
    },
    '0+'    => 'integer',
    '""'    => 'string',
    '+='    => 'add',
    '-='    => 'remove',
    '+'     => sub {
        my ($self,$value) = @_;
        return $self->clone->add($value);
    },
    '-'     => sub {
        my ($self,$value) = @_;
        return $self->clone->remove($value);
    },
    '&'     => sub {
        my ($self,$value) = @_;
        my $bitmask = $self->any2bitmask($value);
        return $self->new_from_bitmask($self->{bitmask} & $bitmask);
    },
    '^'     => sub {
        my ($self,$value) = @_;
        my $bitmask = $self->any2bitmask($value);
        return $self->new_from_bitmask($self->{bitmask} ^ $bitmask);
    },
    '|'     => sub {
        my ($self,$value) = @_;
        my $bitmask = $self->any2bitmask($value);
        return $self->new_from_bitmask($self->{bitmask} | $bitmask);
    },    
    '&='    => sub {
        my ($self,$value) = @_;
        my $bitmask = $self->any2bitmask($value);
        $self->{bitmask} &= $bitmask;
        #$self->{cache} = undef;
        return $self;
    },
    '^='    => sub {
        my ($self,$value) = @_;
        my $bitmask = $self->any2bitmask($value);
        $self->{bitmask} ^= $bitmask;
        #$self->{cache} = undef;
        return $self;
    },
    '|='    => sub {
        my ($self,$value) = @_;
        my $bitmask = $self->any2bitmask($value);
        $self->{bitmask} |= $bitmask;
        #$self->{cache} = undef;
        return $self;
    },  
    "~"     => sub {
        my ($self) = @_;
        return $self->clone->neg();
    };
    
sub _equals {
    my ($self,$value) = @_;
    my $bitmask = $self->any2bitmask($value);
    return ($self->{bitmask} eq $bitmask);
}
    
sub _compare {
    my ($self,$value) = @_;

    my $bitmask = $self->any2bitmask($value);
    
    return $self->{bitmask} cmp $bitmask;
}

sub init {
    my ($class,@params) = @_;

    my $length = $class->bitmask_length;

    croak('Bitmask length not set')
        unless $length && $length > 0;
        
    $class->bitmask_empty($ZERO x $length);

    my $items = {};
    my $count = 0;
    my $bitmask_full = $class->bitmask_empty();
    
    # Take first element from @params
    while (my $name = shift(@params)) {
        my ($bit,$bit_readable);

        $count++;
        
        croak(sprintf('Too many values in bitmask: max <%i>',$class->bitmask_length))
            if $count > $class->bitmask_length;

        given ( $params[0] // '' ) {
            when (blessed $_ && $_->isa('Math::BigInt')) {
                $bit = $class->string2bit(shift(@params)->as_bin());
            }
            when (m/^\d+$/) {
                $bit = $class->int2bit(shift(@params));
            }
            when (m/^0[bB][01]+$/) {
                $bit = $class->string2bit(shift(@params));
            }
            when (m/^[$ZERO$ONE]+$/) {
                $bit = $class->bit2bit(shift(@params));
            }
            default {
                carp( "Lazy bitmask initialization detected: Please enable"
                        . " <bitmask_lazyinit> or change init parameters" )
                    unless ( $class->bitmask_lazyinit );
                $bit = $class->bitmask_empty;
                
                if ($class->bitmask_lazyinit == 2) {
                    substr($bit,($count-1),1,$ONE);
                } else {
                    substr($bit,($length-$count),1,$ONE);
                }
                
            }
        }
    
        $bit_readable = $bit;
        $bit_readable =~ tr/\0\1/01/;
        
        croak(sprintf('Invalid bit value <%s>',$bit_readable))
            unless $bit =~ /^[$ZERO$ONE]{$length}$/;

        croak(sprintf('Duplicate value <%s> in bitmask',$name))
            if exists $items->{$name};

        croak(sprintf('Duplicate bit <%s> in bitmask',$bit_readable))
            if grep { ($_ & $bit) ne $class->bitmask_empty } values %{$items};

        $bitmask_full |= $bit;
        $items->{$name} = $bit;
    }

    $class->bitmask_full($bitmask_full);
    $class->bitmask_items($items);
    $class->bitmask_default($class->any2bitmask($class->bitmask_default))
        if defined $class->bitmask_default;
    return;
}

=head3 int2bit

    my $bitmask_string = CLASS->int2bit(INTEGER);

Helper method that turns an integer into the internal bitmask representation

=cut

sub int2bit {
    my ($class,$integer) = @_;
    
    my $bit = sprintf( '%0' . $class->bitmask_length . 'b', $integer );
    $bit =~ tr/01/\0\1/;
    return $bit;
}

=head3 string2bit

    my $bitmask_string = CLASS->string2bit(STRING);

Helper method that takes a string like '0B001010' or '0b010101' and turns it 
into the internal bitmask representation

=cut

sub string2bit {
    my ($class,$string) = @_;

    $string =~ s/^0[bB]//;
    $string = sprintf( '%0' . $class->bitmask_length . 's', $string );
    $string =~ tr/01/\0\1/;
    return $string;
}

sub bit2bit {
    my ($class,$bit) = @_;
    
    $bit = $ZERO x ($class->bitmask_length - length($bit)) . $bit;
    return $bit;
}

=head3 any2bitmask

    my $bitmask_string = CLASS->any2bitmask(ANYTHING);

Helper method that tries to turn a data into the internal bitmask 
representation. This method can hanle

=over

=item * any Bitmask::Data object

=item * Math::BigInt object

=item * a string matching on of the bitmask values

=item * a bitmask string consisting of \0 and \1 characters

=item * a bitmask string starting with '0b' or '0B' and containing only 0 and 1

=item * an integer

=back

=cut

sub any2bitmask {
    my ($class,$param) = @_;

    croak "Bitmask, Item or integer expected"
        unless defined $param;

    my $length = $class->bitmask_length;
    my $bit;    
    given ($param) {
        when (blessed $param && $param->isa('Bitmask::Data')) {
            $bit = $class->bit2bit($param->{bitmask});
        }
        when (blessed $param && $param->isa('Math::BigInt')) {
            $bit = $class->string2bit($param->as_bin());
        }
        when ($param ~~ $class->bitmask_items) {
            $bit = $class->bitmask_items->{$param};
        }
        when (m/^[$ZERO$ONE]+$/) {
            $bit = $class->bit2bit($param);
        }
        when (m/^[01]{$length}$/) {
            $bit = $class->string2bit($param);
        }
        when (m/^0[bB][01]+$/) {
            $bit = $class->string2bit($param);
        }
        when (m/^\d+$/) {
            $bit = $class->int2bit($param);
        }
        default {
            croak sprintf('Could not turn <%s> into something meaningful',$param);
        }
    }
    
    if (length $bit > $class->bitmask_length) {
        croak sprintf('<%s> exceeds maximum lenth of %i',$param,$class->bitmask_length);
    }
    
    if (($class->bitmask_full | $bit) ne $class->bitmask_full) {
        croak sprintf('<%s> tries to set undefined bits',$param);
    }

    return $bit;
}

=head3 _parse_params

    my $bitmask_string = CLASS->_parse_params(LIST)

Helper method for parsing params passed to various methods.

=cut

sub _parse_params {
    my ($class,@params) = @_;
    
    my $result_bitmask = $class->bitmask_empty;
    
    foreach my $param (@params) {
        next 
            unless defined $param;
            
        my $bitmask;
        if ( ref $param eq 'ARRAY' ) {
            $bitmask = $class->_parse_params(@$param);
        }
        else {
            $bitmask = $class->any2bitmask($param);
        }

        $result_bitmask = $result_bitmask | $bitmask;
    }

    return $result_bitmask;
}

# TODO : method to return ordered bitmask items

=head2 Overloaded operators

Bitmask::Data uses overload by default. 

=over

=item * Numeric context

Returns bitmask integer value (see L<integer> method). For large bitmasks 
(> 40 bits) this will allways be a L<Math::BigInt> object (hence using this
method is not recommended).

=item * Scalar context

Returns bitmask string representation (see L<string> method)

=item * ==, eq, <=>, cmp

Works like 'has_any'

=item * Smartmatch

Works like L<has_any>.

 $bm = new Somebitmask->new('v1','v2');
 $bm ~~ ['v1','v3'] # true, because 'v1' matches even if 'v3' is not set

=item * +, -

Adds/Removes bits to/from the bitmask without changing the current object.
The result is returned as a new Bitmask::Data object.

=item * -=, +=

Adds/Removes bits to/from the current bitmask object.

=item * ~, ^, &, |

Performs the bitwise operations without changing the current object. 
The result is returned as a new Bitmask::Data object.

=item * ^=, &=, |=

Performs the bitwise operations on the current bitmask object.

=back

=head2 Constructors

=head3 new

    my $bm = MyBitmask->new();
    my $bm = MyBitmask->new('value1');
    my $bm = MyBitmask->new('0b00010000010000');
    my $bm = MyBitmask->new(124);
    my $bm = MyBitmask->new(0b00010000010000);
    my $bm = MyBitmask->new(0x2);
    my $bm = MyBitmask->new($another_bm_object);
    my $bm = MyBitmask->new("\0\1\0\0\1");
    my $bm = MyBitmask->new('value2', 'value3');
    my $bm = MyBitmask->new([32, 'value1', 0b00010000010000]);

Create a new bitmask object. You can supply almost any combination of 
ARRAYREFS, bits, Bitmask::Data objects, Math::BigInt objects, bitmasks and 
values, even mix different types. See L<any2bitmask> for details on possible
formats.

=cut

sub new {
    my ( $class, @args ) = @_;

    croak('Bitmask not initialized')
        unless scalar keys %{ $class->bitmask_items };

    my $self = $class->new_from_bitmask($class->bitmask_empty);

    if (scalar @args) {
        $self->set( @args );
    } else {
        $self->set( $class->bitmask_default );    
    }

    return $self;
}

=head3 new_from_bitmask

    my $bm = MyBitmask->new_from_bitmask($bitmask_string);

Create a new bitmask object from a bitmask string (as returned by many
helper methods).

=cut

sub new_from_bitmask {
    my ( $class, $bitmask ) = @_;
    
    $class = ref($class)
        if ref($class);
    
    my $self = bless {
        #cache   => undef,
        bitmask => $bitmask, 
    },$class;
    
    return $self;
}

=head2 Public Methods

=head3 clone

    my $bm_new = $bm->clone();

Clones an existing Bitmask::Data object and.

=cut

sub clone {
    my ( $self ) = @_;
    
    my $new = $self->new_from_bitmask($self->{bitmask});
    #$new->{cache} = $self->{cache};
    return $new;
}

=head3 set

    $bm->set(PARAMS);
    
This methpd resets the current bitmask and sets the supplied arguments. 
Takes the same arguments as C<new>. 

Returns the object.

=cut

sub set {
    my ( $self, @args ) = @_;

    $self->{bitmask} = $self->bitmask_empty;
    $self->add( @args );

    return $self;
}

=head3 remove 

    $bm->remove(PARAMS)
    
Removes the given values/bits from the bitmask. Takes the same arguments 
as C<new>. 

Returns the object.

=cut

sub remove {
    my ( $self, @args ) = @_;

    my $bitmask = $self->_parse_params(@args);

    $self->{bitmask} = $self->{bitmask} ^ ($self->{bitmask} & $bitmask);
    #$self->{cache} = undef;
    
    return $self;
}


=head3 add 

    $bm->add(PARAMS)
    
Adds the given values/bits to the bitmask. Takes the same arguments 
as C<new>. 

Returns the object.

=cut

sub add {
    my ( $self, @args ) = @_;

    my $bitmask = $self->_parse_params(@args);
    
    $self->{bitmask} = $self->{bitmask} | $bitmask;
    #$self->{cache} = undef;

    return $self;
}

=head3 reset 

    $bm->reset()
    
Resets the bitmask to the default (or empty) bitmask.

Returns the object.

=cut

sub reset {
    my ($self) = @_;
    
    $self->{bitmask} = $self->bitmask_default || $self->bitmask_empty;
    #$self->{cache} = undef;
    
    return $self;
}


=head3 set_all 

    $bm->set_all()
    
Sets all defined bits in the bitmask.

Returns the object.

=cut

sub set_all {
    my ($self) = @_;
    
    $self->{bitmask} = $self->bitmask_full;
    #$self->{cache} = undef;
    
    return $self;
}
*setall = \&set_all;

=head3 neg 

    $bm->neg()
    
Negates/Inverts the bitmask

Returns the object.

=cut

sub neg {
    my ( $self ) = @_;

    $self->{bitmask} =~ tr/\0\1/\1\0/;
    $self->{bitmask} = $self->{bitmask} & $self->bitmask_full;
    #$self->{cache} = undef;
    
    return $self;
}

=head3 list

    my @values = $bm->list();
    OR
    my $values = $bm->list();

In list context, this returns a list of the set values in scalar context, 
this returns an array reference to the list of values.

=cut

sub list {
    my ($self) = @_;
    
    #return (wantarray ? @{$self->{cache}} : $self->{cache})
    #    if defined $self->{cache};
    
    my @data;
    while (my ($value,$bit) = each %{$self->bitmask_items()}) {
        push @data,$value
            if (($bit & $self->{bitmask}) ne $self->bitmask_empty); 
    }
    
    #$self->{cache} = \@data;
    
    return wantarray ? @data : \@data;
}

=head3 length

    my $length = $bm->length();

Number of set bitmask values.

=cut

sub length {
    my ($self) = @_;
    
    my @list = $self->list;
    return scalar @list;
}

=head3 first 

    my $value = $bm->first()
    
Returns the first set value. The order is determined by the bit value.

=cut

sub first {
    my ($self) = @_;
    
    my $bitmask_items = $self->bitmask_items();
    foreach my $key (sort { $bitmask_items->{$a} cmp $bitmask_items->{$b} } keys %{$bitmask_items}) {
        return $key
            if (($bitmask_items->{$key} & $self->{bitmask}) ne $self->bitmask_empty); 
    }
    return;
}

=head3 integer

    my $integer = $bm->integer();

Returns the bitmask as an integer. For bitmasks with a length > 40 this will
always be a L<Math::BigInt> object.

=cut

*mask = \&integer;
sub integer {
    my ($self) = @_;
    
    my $bitmask = $self->{bitmask};
    $bitmask =~ tr/\0\1/01/;
    
    if ($self->bitmask_length > 64 || ($self->bitmask_length > 32 && ! $Config{use64bitint})) {
        require Math::BigInt;
        return Math::BigInt->from_bin("0b".$bitmask);
    } else {
        no warnings 'portable';
        return oct("0b".$bitmask);
    }
}

=head3 string

    my $string = $bm->string();

Returns the bitmask as a string of 0 and 1.

=cut

sub string {
    my ($self) = @_;
    my $bitmask = $self->{bitmask};
    $bitmask =~ tr/\0\1/01/;
    return $bitmask;
}

=head3 bitmask

    my $string = $bm->bitmask();

Returns the bitmask in the internal representation: A string of \0 and \1

=cut

sub bitmask {
    my ($self) = @_;
    return $self->{bitmask};
}

=head3 sqlfilter_all

This method can be used for database searches in conjunction with 
L<SQL::Abstract> an POSTGRESQL (SQL::Abstract is used by L<DBIx::Class> for
generating searches). The search will find all database rows
with bitmask that have at least the given values set. (use
the C<sql> method for an exact match)

Example how to use sqlfilter with SQL::Abstract:

    my($stmt, @bind) = $sql->select(
        'mytable', 
        \@fields,
        {
            $bm->sqlfilter_all('mytable.bitmaskfield'),
        }
    );

Example how to use sqlfilter with DBIx::Class:
   
    my $list = $resultset->search(
        { 
            $bm->sqlfilter_all('me.bitmaskfield'), 
        },
    );


=cut

sub sqlfilter_all {
    my ( $self, $field ) = @_;

    my $sql_mask = $self->string();
    my $format   = "bitand( $field, B'$sql_mask' )";
    return ( $format, \" = B'$sql_mask'" );
}
*sqlfilter = \&sqlfilter_all;

=head3 sqlfilter_any

Works like C<sqlfilter_all> but checks for any bit matching

=cut

sub sqlfilter_any {
    my ( $self, $field ) = @_;

    my $sql_mask = $self->string();
    my $format   = "bitand( $field, B'$sql_mask' )";
    my $empty_mask = $self->bitmask_empty;
    $empty_mask =~ tr/\0\1/01/;
    return ( $format, \" <> B'$empty_mask'" );
}

=head3 sqlstring

Returns the bitmask as a quoted string as needed by PostgreSQL:

 B'0000000000000001'::bit(16)

=cut

sub sqlstring {
    my ( $self ) = @_;
    return sprintf("B'%s'::bit(%i)",$self->string,$self->bitmask_length);
}

=head3 has_all

    if ($bm->has_all(PARAMS)) {
        # Do something
    }

Checks if all requestes bits/values are set and returns true or false.
This method takes the same arguments as C<new>. 

=cut

sub has_all {
    my ( $self, @args ) = @_;

    my $bitmask = $self->_parse_params(@args);
     
    return (($bitmask & $self->{bitmask}) eq $bitmask) ? 1:0;
}
*hasall = \&has_all;

=head3 has_exact

    if ($bm->has_exact(PARAMS)) {
        # Do something
    }

Checks if the set bits/values excactly match the supplied bits/values and 
returns true or false.
This method takes the same arguments as C<new>. 

=cut

sub has_exact {
    my ( $self, @args ) = @_;

    my $bitmask = $self->_parse_params(@args);

    return ($bitmask eq $self->{bitmask}) ? 1:0;
}
*hasexact = \&has_exact;

=head3 has_any

    if ($bm->has_any(PARAMS)) {
        # Do something
    }

Checks if at least one set value/bit matches the supplied bits/values and 
returns true or false.
This method takes the same arguments as C<new>. 

=cut

sub has_any {
    my ( $self, @args ) = @_;

    my $bitmask = $self->_parse_params(@args);
    
    return (($bitmask & $self->{bitmask}) ne $self->bitmask_empty)  ? 1:0;
}
*hasany = \&has_any;

1;

=head1 CAVEATS

Since Bitmask::Data is very liberal with input data you cannot use numbers
as bitmask values. (It would think that you are supplying an integer 
bitmask and not a value)

Bitmask::Data adds a considerable processing overhead to bitmask 
manipulations. If you either don't need the extra comfort or use 
bitmasks with less that 40 bits that you should consider using just the perl 
built in bit operators on simple integer values.

=head1 SUBCLASSING

Bitmask::Data was designed to be subclassed.
 
    package MyBitmask;
    use parent qw(Bitmask::Data);
    __PACKAGE__->bitmask_length(20); # Default length is 16
    __PACKAGE__->init(
        'value1' => 0b000000000000000001,
        'value2' => 0x2,
        'value2' => 4,
        'value4', # lazy initlialization
        'value5', # lazy initlialization
    );

=head1 WORKING WITH DATABASES

This module comes with support for POSTGRESQL databases (patches for other
database vendors are welcome). 

First you need to create the correct column types:

    CREATE TABLE bitmaskexample ( 
        id integer DEFAULT nextval('pkey_seq'::regclass) NOT NULL,
        bitmask bit(14),
        otherfields character varying
    );

The length of the bitmask field must match C<CLASS-E<gt>bitmask_length>.

This module provides three convenient methods to work with databases:

=over

=item * L<sqlfilter_all>: Search for matching bitmasks

=item * L<sqlfilter_any>: Search for bitmasks with matching bits

=item * L<string>: Print the bitmask string as used by the database

=back

If you are working with l<DBIx::Class> you might also install de- and 
inflators for Bitmask::Data objects:

    __PACKAGE__->inflate_column('fieldname',{
        inflate => sub {
            my $value = shift;
            return MyBitmask->new($value);
        },
        deflate => sub {
            my $value = shift;
            undef $value 
                unless ref($value) && $value->isa('MyBitmask');
            $value //= MyBitmask->new();
            return $value->string;
        },
    });

=head1 SUPPORT

Please report any bugs or feature requests to 
C<bug-bitmask-data@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Bitmask::Data>.
I will be notified and then you'll automatically be notified of the progress 
on your report as I make changes.

=head1 AUTHOR

    Klaus Ita
    koki [at] worstofall.com

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.revdev.at>

=head1 ACKNOWLEDGEMENTS 

This module was originally written by Klaus Ita (Koki) for Revdev 
L<http://www.revdev.at>, a nice litte software company I (Maros) run with 
Koki and Domm (L<http://search.cpan.org/~domm/>).

=head1 COPYRIGHT & LICENSE 

Bitmask::Data is Copyright (c) 2008 Klaus Ita, Maroš Kollár 
- L<http://www.revdev.at>

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
