# =============================================================================
package Color::Model::Munsell;
# -----------------------------------------------------------------------------
$Color::Model::Munsell::VERSION = '0.02';
# -----------------------------------------------------------------------------
use warnings;
use strict;

=head1 NAME

Color::Model::Munsell - Color model of Munsell color system

=head1 SYNOPSIS

Chromatic color;

    $mun = Color::Model::Munsell->new("9R 5.5/14");
    $mun = Color::Model::Munsell->new("7PB", 4, 10);
    print "$mum is chromatic color" if !$mun->isneutral;

Neutral grays;

    $mun = Color::Model::Munsell->new("N 4.5");
    $mun = Color::Model::Munsell->new("N", 9);
    print "$mum is neutral color" if $mun->isneutral;

=cut

# =============================================================================
use Carp qw();
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
use base qw(Exporter);
@EXPORT    = qw( Munsell degree undegree );
@EXPORT_OK = qw( PUREWHITE PUREBLACK REALWHITE REALBLACK @hue_order %hue_number );
%EXPORT_TAGS = (
    symbols  => [ qw( @hue_order %hue_number ) ],
    vertexes => [ qw( PUREWHITE PUREBLACK REALWHITE REALBLACK ) ],
    all      => [ @EXPORT, @EXPORT_OK ]
);

our @hue_order = qw(R YR Y GY G BG B PB P RP);
our %hue_number = (
    R  => 0, YR => 1, Y  => 2, GY => 3, G  => 4,
    BG => 5, B  => 6, PB => 7, P  => 8, RP => 9,
);

our $ERROR;

# =============================================================================

=head1 CONSTRUCTORS

=head2 new()

    # with Munsell color specifying
    $m = Color::Model::Munsell->new("9R 5.5/14");
    $m = Color::Model::Munsell->new("N 4.5");

    # with parapeters
    $m = Color::Model::Munsell->new("7PB", 4, 10);
    $m = Color::Model::Munsell->new("N", 9);

If number part of hue is 0, it becomes 10.0 of previous hue color on the circle.

Value(as Lightness) or chroma has thier range;
    0 <= value  <= 10.0  # if 0 or 10, it will be regraded as black or white
    0 <= chroma          # if 0, it will be gray

and these number will be rounded up to the tenth's place with sprintf().

If constructor returns undef, it means some error occurs. When this case, Check
$Color::Model::Munsell::ERROR that have a reason of an error.

=cut

sub new
{
    my $class = shift;

    my ($hue, $value, $chroma);
    my ($chromatic, $hue_step, $hue_col);
    $ERROR = '';

    if ( @_ == 1 ){
        ($hue, $value, $chroma) = split(/[ \/]+/, $_[0]);
    } else {
        ($hue, $value, $chroma) = @_;
    }

    # - hue check
    if ( defined($hue) ){
        $hue = uc($hue);
        if ( $hue eq 'N' ){
            $chromatic = 0;
        }
        elsif ( $hue =~ /^(\d+|\d+\.\d+)(R|YR|Y|GY|G|BG|B|PB|P|RP)$/ ){
            ($hue_step,$hue_col) = ($1,$2);
            $hue_step = sprintf('%.1f',$hue_step);
            if ( $hue_step > 10 ){
                $ERROR = "Number of hue, \"$hue\", is grater than 10.0.";
                return undef;
            }
            if ( $hue_step == 0 ){
                $hue_step = 10.0;
                $hue_col  = $hue_col eq 'R'? 'RP': $hue_order[$hue_number{$hue_col}-1];
            }
            $hue = sprintf('%s%s',$hue_step+0,$hue_col);
            $chromatic = 1;
        }
        else {
            $ERROR = "Hue, \"$hue\" is not valid format.";
            return undef;
        }
    } else {
        $ERROR = "Hue is undefined.";
        return undef;
    }

    # - value check
    if ( defined($value) ){
        if ( $value =~ /^(\d+|\d+\.\d+)$/ ){
            $value = sprintf('%.1f',$value);
            if ( $value>10 ){
                $ERROR = "Value ($value) is out of range.";
                return undef;
            }
            elsif ( $value == 0 or $value == 10 ){
                $hue = 'N';
                $chromatic = 0;
            }
        }
        else {
            $ERROR = "Value is not a valid number.";
            return undef;
        }
    } else {
        $ERROR = "Value is undefined.";
        return undef;
    }

    # - chroma check
    if ( $chromatic ){
        if ( defined($chroma) ){
            if ( $chroma =~ /^(\d+|\d+\.\d+)$/ ){
                $chroma = sprintf('%.1f',$chroma);
                if ( $chroma == 0 ){
                    $hue = 'N';
                    $chromatic = 0;
                }
            }
            else {
                $ERROR = "Chroma is not a valid number.";
                return undef;
            }
        }
        else {
            $ERROR = "Chroma is undefined.";
            return undef;
        }
    }

    my $self = {
        hue         => $hue,
        hue_step    => $chromatic? $hue_step: undef,
        hue_col     => $chromatic? $hue_col: undef,
        value       => $value,
        chroma      => $chromatic? $chroma: undef,
    };
    bless $self, $class;
}


=head2 Munsell()

Munsell() is defalut exporting subroutine which calls new().

    $m = Munsell("9R 5.5/14");

=cut

sub Munsell
{
    return __PACKAGE__->new(@_);
}


# =============================================================================

=head1 CONSTANTS

There are some constants which makes black or white object. Use tag ":vertexes"
or ":all".

=over

=item PUREWHITE()

return an object of "N 10.0"

=item PUREBLACK();

return an object of "N 0.0"

=item REALWHITE();

return an object of "N 9.5"

=item REALBLACK();

return an object of "N 1.0"

=back

=cut

sub PUREWHITE { __PACKAGE__->new('N 10.0') }
sub PUREBLACK { __PACKAGE__->new('N 0.0') }
sub REALWHITE { __PACKAGE__->new('N 9.5') }
sub REALBLACK { __PACKAGE__->new('N 1.0') }


=head1 METHODS

Object C<Color::Model::Munsell> has methods below.

=over

=item code()

Returns Munsell code like "5R 10/14" or "N 4.5".

=item ischromatic()

Returns 1 if object is chromatic, or 0.

=item isneutral()

Returns 1 if object is neutral color, or 0.

=item isblack()

Return 1 if value is equal or lesser than 1.0, or 0

=item iswhite()

Return 1 if value is equal or greater than 9.5, or 0

=item hue()

Returns hue code like "5R" or "N".

=item hueCol()

Returns color sign of hue; R,YR,Y,GY,G,BG,B,PB,P,RP or N

=item hueStep();

Returns number of hue (gray returns undef)

=item value()

Returns Munsell value.

=item lightness()

Same as value()

=item chroma()

Returns Munsell chroma.

=item saturation()

Same as chroma().

=item degree()

See degree() below.

=back

=cut

sub ischromatic { defined($_[0]->{chroma})? 1:0; }
sub isneutral   { defined($_[0]->{chroma})? 0:1; }
sub hue         { $_[0]->{hue};      }
sub hueCol      { $_[0]->{hue_col};  }
sub hueStep     { $_[0]->{hue_step}; }
sub value       { $_[0]->{value};    }
sub lightness   { $_[0]->{value};    }
sub chroma      { $_[0]->{chroma};   }
sub saturation  { $_[0]->{chroma};   }

sub code
{
    my $self = shift;
    if ( defined($self->{chroma}) ){
        return sprintf('%s %s/%s',$self->{hue}, $self->{value}+0, $self->{chroma}+0);
    } else {
        return sprintf('N %.1f',$self->{value});
    }
}

sub isblack
{
    my $self = shift;
    return $self->{value} <= 1.0? 1: 0;
}

sub iswhite
{
    my $self = shift;
    return $self->{value} >= 9.5? 1: 0;
}


# =============================================================================

=head1 SUBROUTINES

=head2 degree()

    print $m->degree();
    print degree("7.5B");

Subroutine or object method C<degree()> return a serial hue number, considering
10.0RP is 0, 10R is 10, 10YR is 20, ..., and ends 9.9RP as 99.9.
This will be useful to get radians of Muncell color circle.
If object is neutral, this returns undef.

=cut

sub degree
{
    unless ( @_ == 1 ){
        Carp::croak('Usage: degree($huecode) or $m->degree()');
    }
    my $self = shift;
    if ( ref($self) eq __PACKAGE__ ){
        return undef unless defined($self->{chroma});
    } else {
        $self = __PACKAGE__->new($self,1,1);
        Carp::croak($ERROR) unless defined($self);
    }
    if ( $self->{hue} eq '10RP' ){
        return 0;
    } else {
        return $hue_number{$self->{hue_col}} * 10 + $self->{hue_step};
    }
}

=head2 undegree();

    print undegree();

Function undegree() return a hue code from a serial hue number.

=cut

sub undegree
{
    unless ( @_ == 1 ){
        Carp::croak('Usage: undegree($degreenum)');
    }
    my $num = shift;
    unless ( defined($num) && $num=~/^(\d+|\d+\.\d+)$/ ){
        Carp::croak("Argument is not a valid number.");
    }
    if ( $num > 100.0 ){
        Carp::croak("Given number is out of range(<=100).");
    }
    $num = sprintf('%.1f', $num);
    if ( $num == 0 or $num == 100 ){
        return '10RP';
    } else {
        my $col = int($num/10);
        my $stp = $num - $col*10;
        return sprintf('%s%s', $stp+0, $hue_order[$col]);
    }
}


# =============================================================================

=head1 OPERATOR OVERLOAD

Stringify operator of this module, Color::Model::Munsell, is prepared. If
you join a object with some string, object will be Munsell code.

    $m = Color::Model::Munsell->new("9R", 5.5, 14);
    print "$m is red";    # printing "9R 5.5/14 is red"

=cut

use overload
    '""' => \&_stringify,
    'fallback' => undef;

sub _stringify {
    my($object,$argument,$flip) = @_;
    return $object->code;
}


=head1 BUGS

Please report any bugs or feature requests to C<bug-color-model-munsell at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Color-Model-Munsell>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Takahiro Onodera, C<< <ong at garakuta.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 T.Onodera.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Color::Model::Munsell
