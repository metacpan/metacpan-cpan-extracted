package PDL::SV;

# ABSTRACT: PDL subclass for keeping scalar data (like strings)

use 5.016;
use warnings;

use PDL::Lite ();   # PDL::Lite is the minimal to get PDL work
use PDL::Core qw(pdl);
use PDL::Primitive qw(which);

use Ref::Util qw(is_plain_arrayref);
use Safe::Isa;
use Type::Params;
use Types::Standard qw(slurpy ArrayRef ConsumerOf Int);
use List::AllUtils ();

use parent 'PDL';
use Class::Method::Modifiers;

use Role::Tiny::With;
with qw(PDL::Role::Stringifiable);

use Devel::OverloadInfo qw(overload_op_info);

my $overload_info;
my $super_dotassign;

BEGIN {
    my $overload_info = overload_op_info('PDL', '.=');
    $super_dotassign = $overload_info->{code};
}

use overload
  '==' => \&_eq,
  'eq' => \&_eq,
  '!=' => \&_ne,
  'ne' => \&_ne,
  '<'  => \&_lt,
  'lt' => \&_lt,
  '<=' => \&_le,
  'le' => \&_le,
  '>'  => \&_gt,
  'gt' => \&_gt,
  '>=' => \&_ge,
  'ge' => \&_ge,

  '.=' => sub {
    my ( $self, $other, $swap ) = @_;

    if ( $other->$_DOES('PDL::SV') ) {
        my $internal = $self->_internal;
        if ($other->dim(0) == 1) {
            for my $i ( 0 .. $self->dim(0) - 1 ) {
                my $idx = PDL::Core::at( $self, $i );
                $internal->[$idx] = $other->at(0);
            }
        } else {
            for my $i ( 0 .. $self->dim(0) - 1 ) {
                my $idx = PDL::Core::at( $self, $i );
                $internal->[$idx] = $other->at($i);
            }
        }
        return $self;
    }
    elsif ($other->$_DOES('PDL')) {
        return $super_dotassign->( $self, $other, $swap );
    }
    else {  # non-piddle
        my $internal = $self->_internal;
        for my $i ( 0 .. $self->dim(0) - 1 ) {
            my $idx = PDL::Core::at( $self, $i );
            $internal->[$idx] = $other;
        }
    }
  },
  fallback => 1;

# after stringifiable role is added, the string method will exist
eval q{
	use overload ( '""'   =>  \&PDL::SV::string );
};

sub _internal {
    my ( $self, $val ) = @_;
    if ( defined $val ) {
        $self->{_internal} = $val;
    }
    return $self->{_internal};
}

sub new {
    my ( $class, @args ) = @_;
    my $data = shift @args;    # first arg

    state $rmap = sub {
        my ( $x ) = @_; 
        is_plain_arrayref($x)
          ? [ map { __SUB__->( $_ ) } @$x ]
          : 0;
    };  

    my $faked_data = $rmap->($data);

    my $self = $class->initialize();
    my $pdl  = $self->{PDL};
    $pdl .= PDL::Core::indx($faked_data);
    $pdl .= PDL->sequence( $self->dims );

    if ($self->ndims == 1) {    # for speed 
        $self->_internal($data);
    } else {
        my $internal = $self->_internal;
        for my $idx ( 0 .. $self->nelem - 1 ) {
            my @where = reverse $self->one2nd($idx);
            $internal->[$idx] = $self->_array_get( $data, \@where );
        }
    }

    $self;
}

sub initialize {
    my ($class) = @_;
    return bless( { PDL => PDL::Core::null, _internal => [] }, $class );
}

# code modified from <https://metacpan.org/pod/Hash::Path>
sub _array_get {
    my ( $self, $array, $indices ) = @_;

    my $return_value = $array->[ $indices->[0] ];
    for ( 1 .. $#$indices ) {
        $return_value = $return_value->[ $indices->[$_] ];
    }
    return $return_value;
}

sub _array_set {
    my ( $self, $array, $indices, $val ) = @_;
    return unless scalar @$indices;

    my $subarray = $array;
    for ( 0 .. $#$indices - 1 ) {
        $subarray = $subarray->[ $indices->[$_] ];
    }
    $subarray->[ $indices->[-1] ] = $val;
}


around qw(slice dice) => sub : lvalue {
    my $orig = shift;
    my $self = shift;

    my $new = $self->$orig(@_);
    $new->_internal( $self->_internal );
    return $new;
};


sub glue {
    my $self = shift;

    state $check =
      Type::Params::compile( Int,
        slurpy ArrayRef [ ConsumerOf ['PDL::SV'] ] );
    my ( $dim, $others ) = $check->(@_);

    my $class = ref($self);

    if ($dim != 0) {
        die('PDL::SV::glue does not yet support $dim != 0');
    }

    my $data = [ map { @{$_->unpdl} } ($self, @$others) ];
    my $new = $class->new($data);
    if (List::AllUtils::any { $_->badflag } ($self, @$others)) {
        my $isbad = pdl([ map { @{$_->isbad->unpdl} } ($self, @$others) ]);
        $new->{PDL} = $new->{PDL}->setbadif($isbad);
    }
    return $new;
}


sub uniq {
    my ($self) = @_;
    my $class = ref($self);

    my @uniq = List::AllUtils::uniq( grep { defined $_ }
          @{ $self->_effective_internal } );
    return $class->new( \@uniq );
}

## Please see file perltidy.ERR
sub uniqind {
    my ($self) = @_;

    my $effective_internal = $self->_effective_internal;
    my @uniqind = List::AllUtils::uniq_by { $effective_internal->[$_] }
        grep { defined $effective_internal->[$_] }
            ( 0 .. $#$effective_internal );
    return pdl( \@uniqind );
}


sub sever {
    my ($self) = @_;

    $self->_internal( $self->_effective_internal );
    my $p = PDL->sequence( $self->dims );
    $p = $p->setbadif( $self->isbad ) if $self->badflag;
    $self->{PDL} = $p;
    return $self;
}


sub set {
    my ($self, @position) = @_;

    my $value = pop @position;
    my $idx = $self->{PDL}->at(@position);
    $self->_internal->[$idx] = $value;
    return $self;
}


sub at {
    my $self = shift;

    my $idx = $self->{PDL}->at(@_);
    return 'BAD' if $idx eq 'BAD';
    return $self->_internal->[$idx];
}


sub unpdl {
    my $self = shift;

    if ($self->ndims == 1) {    # shortcut for 1D for performance
        return [ $self->list ];
    }

    state $rmap = sub {
        my ( $x, $f ) = @_;
        is_plain_arrayref($x)
          ? [ map { __SUB__->( $_, $f ) } @$x ]
          : $f->($x);
    };

    my $internal = $self->_internal;
    my $f =
      $self->badflag
      ? sub { $_ eq 'BAD' ? 'BAD' : $internal->[$_] }
      : sub { $internal->[$_] };
    return $rmap->( $self->{PDL}->unpdl, $f );
}


sub list {
    my ($self) = @_;

    my $internal = $self->_internal;
    my @list = do {
        no warnings 'numeric';
        map { $internal->[$_] } $self->{PDL}->list;
    };
    if ($self->badflag) {
        my @bad_indices = which($self->isbad)->list;
        @list[@bad_indices] = (('BAD') x @bad_indices);
    }
    return @list;
}


sub copy {
    my ($self) = @_;

    my $new = PDL::SV->new( [] );
    $new->{PDL} = PDL->sequence( $self->dims );
    $new->_internal( $self->_effective_internal );
    if ( $self->badflag ) {
        $new->{PDL} = $new->{PDL}->setbadif( $self->isbad );
    }
    return $new;
}


sub inplace {
    my $self = shift;
    $self->{PDL}->inplace(@_);
    return $self;
}

sub _call_on_pdl {
    my ($method) = @_;

    return sub {
        my $self = shift;
        return $self->{PDL}->$method(@_);
    };
}


sub where {
    my ( $self, $mask ) = @_;
    return $self->slice( which($mask) );
}


for my $method (qw(isbad isgood ngood nbad)) {
    no strict 'refs';
    *{$method} = _call_on_pdl($method);
}


sub setbadif {
    my $self = shift;

    my $new = $self->copy;
    $new->{PDL} = $new->{PDL}->setbadif(@_);
    return $new;
}


sub setbadtoval {
    my $self = shift;
    my ($val) = @_;

    my $class = ref($self);

    my $data = $self->unpdl;
    if ( $self->badflag ) {
        my $isbad = $self->isbad;
        for my $idx ( which($isbad)->list ) {
            my @where = reverse $self->one2nd($idx);
            $self->_array_set( $data, \@where, $val );
        }
    }
    return $class->new($data);
}


sub match_regexp {
    my ( $self, $regexp ) = @_;

    my @matches = map { $_ =~ $regexp ? 1 : 0 } @{ $self->_internal };
    my $p = pdl( \@matches )->reshape( $self->dims );
    if ( $self->badflag ) {
        $p = $p->setbadif( $self->isbad );
    }
    return $p;
}

sub _effective_internal {
    my ($self) = @_;

    my $internal = $self->_internal;
    my @indices = $self->{PDL}->list;

    no warnings 'numeric';
    my @rslt = @$internal[@indices];
    if ($self->badflag) {
        my @isbad = which($self->isbad)->list;
        @rslt[@isbad] = ((undef) x @isbad);
    }
    return \@rslt;
}

sub _compare {
    my ($self, $other) = @_;

    unless ($other->$_DOES('PDL::SV') or !ref($other)) {
        die "Cannot compare PDL::SV to anything other than a PDL::SV or a plain string";
    }

    my $rslt;
    if (ref($other)) {

        # check dimensions
        {
            # this would die if they are not same
            no warnings qw(void);
            $self->{PDL}->shape == $other->{PDL}->shape;
        }

        my @cmp_rslt = List::AllUtils::pairwise {
            (defined $a and defined $b) ? ($a cmp $b) : 0
        } @{$self->_effective_internal}, @{$other->_effective_internal};

        $rslt = PDL::Core::pdl( \@cmp_rslt )->reshape( $self->dims );
        if ( $self->badflag or $other->badflag ) {
            $rslt = $rslt->setbadif( $self->isbad | $other->isbad );
        }
    } else {    # $other is a plain string
        my @cmp_rslt = map {
            (defined $_) ? ($_ cmp $other) : 0
        } @{$self->_effective_internal};

        $rslt = PDL::Core::pdl( \@cmp_rslt )->reshape( $self->dims );
        if ( $self->badflag ) {
            $rslt = $rslt->setbadif( $self->isbad );
        }
    }

    return $rslt;
}

sub _gen_compare {
    my ($f) = @_;

    return sub {
        my ( $self, $other, $swap ) = @_;
        my $cmp_rslt = $self->_compare($other);
        return $f->($swap, $cmp_rslt);
    }
} 

*_eq = _gen_compare( sub { $_[1] == 0 } );
*_ne = _gen_compare( sub { $_[1] != 0 } );
*_lt = _gen_compare( sub { $_[0] ? $_[1] > 0  : $_[1] < 0  } );
*_le = _gen_compare( sub { $_[0] ? $_[1] >= 0 : $_[1] <= 0 } );
*_gt = _gen_compare( sub { $_[0] ? $_[1] < 0  : $_[1] > 0  } );
*_ge = _gen_compare( sub { $_[0] ? $_[1] <= 0 : $_[1] >= 0 } );

sub element_stringify_max_width {
    my ( $self, $element ) = @_;
    my @where   = @{ $self->uniq->SUPER::unpdl };
    my @which   = @{ $self->_internal }[@where];
    my @lengths = map { length $_ } @which;
    List::AllUtils::max(@lengths);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::SV - PDL subclass for keeping scalar data (like strings)

=head1 VERSION

version 0.0056

=head1 SYNOPSIS

    use PDL::SV ();
    
    my $p = PDL::SV->new( [ qw(foo bar) ] );

=head1 DESCRIPTION

This PDL::SV class stores array of scalar values. It can be used for vectors
of strings.

While this class is a subclass of L<PDL>, its internals are quite different
from other normal PDL types. So basically what's not documented are not
guarenteed to work.

=head1 METHODS / BASIC

These methods basically have similar behavior as PDL class's methods of
same names.

=head2 slice

    slice(...)

=head2 dice

    dice(...)

=head2 glue

    $c = $a->glue($dim, $b, ...);

Glue two or more PDLs together along an arbitrary dimension.
For now it only supports 1D PDL::SV piddles, and C<$dim> has to be C<0>.

=head2 uniq

    uniq()

BAD values are not considered unique and are ignored.

=head2 uniqind()

Return the indices of all uniq elements of a piddle.

=head2 sever

    sever()

=head2 set

    set(@position, $value)

=head2 at

    at(@position)

=head2 unpdl

    unpdl()

=head2 list

    list()

=head2 copy

    copy()

=head2 inplace

    inplace()

=head2 where

    where($mask)

=head1 METHODS / BAD VALUE

These methods basically have similar behavior as PDL class's methods of
same names.

=head2 isbad

    isbad()

=head2 isgood

    isgood()

=head2 ngood

    ngood()

=head2 nbad

    nbad()

=head2 setbadif

    setbadif($mask)

=head2 setbadtoval

    setbadtoval($val)

Cannot be run inplace.

=head1 METHODS / ADDITIONAL

These methods exist not in PDL but only in this class.

=head2 match_regexp

    match_regexp($pattern)

Match against a plain a regular expression.
Returns a piddle of the same dimension.

=head1 SEE ALSO

L<PDL>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2020 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
