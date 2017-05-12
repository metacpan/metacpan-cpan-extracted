use 5.10.0;
use strict;
use warnings;

package Types::CairoX::Sweet;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Type::Library -base,
                  -declare => qw/
                        CairoImageSurface
                        CairoContext
                        ArrayRefNumOfTwo
                        ArrayRefNumOfFour
                        ArrayRefNumOfSix
                        Color
                        CurveTo
                        LineTo
                        MoveTo
                        NumUpToOne
                        Path
                        Point
/;
use Type::Utils -all;
use List::Util qw/any/;
use List::SomeUtils qw/zip/;
use namespace::autoclean;

use Types::Standard -types;
#use Types::TypeTiny -types;

class_type CairoContext      => { class => 'Cairo::Context' };
class_type CairoSurface => { class => 'Cairo::Surface' };

class_type Color   => { class => 'CairoX::Sweet::Color' };
class_type CurveTo    => { class => 'CairoX::Sweet::Core::CurveTo' };
class_type LineTo    => { class => 'CairoX::Sweet::Core::LineTo' };
class_type MoveTo    => { class => 'CairoX::Sweet::Core::MoveTo' };
class_type Path    => { class => 'CairoX::Sweet::Path' };
class_type Point    => { class => 'CairoX::Sweet::Core::Point' };

declare ArrayRefNumOfTwo, as ArrayRef[Num],
    where { scalar @$_ % 2 == 0 },
    message {
        return ArrayRef->get_message($_) if !ArrayRef->check($_);
        return "Takes two values per unit";
    };
declare ArrayRefNumOfFour, as ArrayRef[Num],
    where { scalar @$_ % 4 == 0 },
    message {
        return ArrayRef->get_message($_) if !ArrayRef->check($_);
        return "Takes four values per unit";
    };
declare ArrayRefNumOfSix, as ArrayRef[Num],
    where { scalar @$_ % 6 == 0 },
    message {
        return ArrayRef->get_message($_) if !ArrayRef->check($_);
        return "Takes six values per unit";
    };

declare NumUpToOne, as Num,
    where { $_ >= 0 && $_ <= 1 },
    message {
        return Num->get_message($_) if !Num->check($_);
        return "$_ is too small. Minimum allowed value is 0" if $_ < 0;
        return "$_ is too big. Maximum allowed value is 1";
    };

coerce Color,
    from Str, via {
        my $str = $_;
        $str =~ s{^#}{};
        if($str =~ m{^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$}i) {
            "CairoX::Sweet::Color"->new(red => (hex $1) / 255, green => (hex $2) / 255, blue => (hex $3) / 255 );
        }
    },
    from ArrayRef, via {
        my @array = @{ $_ };
        if(scalar @array == 3 || scalar @array == 4) {
            my $opacity = scalar @array == 4 ? pop @array : undef;

            my @colors = qw/red green blue/;
            if(any { int $_ != $_ } @array) {
                @colors = zip (@colors, @array);
            }
            else {
                @array = map { $_ / 255 } @array;
                @colors = zip (@colors, @array);
            }
            my %color = @colors;
            $color{'opacity'} = $opacity if defined $opacity;

            "CairoX::Sweet::Color"->new(%color);
        }
    };

coerce Point,
    from ArrayRefNumOfTwo, via {
        "CairoX::Sweet::Core::Point"->new($_->[0], $_->[1]);
    };
coerce MoveTo,
    from ArrayRefNumOfTwo, via {
        "CairoX::Sweet::Core::MoveTo"->new($_->[0], $_->[1]);
    };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Types::CairoX::Sweet

=head1 VERSION

Version 0.0200, released 2016-08-22.

=head1 SOURCE

L<https://github.com/Csson/p5-CairoX-Sweet>

=head1 HOMEPAGE

L<https://metacpan.org/release/CairoX-Sweet>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
