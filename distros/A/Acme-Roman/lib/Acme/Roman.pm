
package Acme::Roman;

use strict;
use warnings;

use version; our $VERSION = qv('0.0.2.12');

require Roman;
use Carp qw( croak );

use base qw( Class::Accessor );
__PACKAGE__->mk_ro_accessors( qw( roman num ) );

use overload 
    '0+'     => sub { shift->num },
    '""'     => sub { shift->roman },
    '+'      => \&plus,
    '-'      => \&minus,
    '*'      => \&times,
    fallback => 1
;

# aliases to Roman functions, whose names dislike me
*to_roman  = \&Roman::Roman;
*to_number = \&Roman::arabic;

sub is_roman {
    return "" if $_[0] =~ /[^IVXLCDM]/; # false: accept nothing but uppercase
    return Roman::isroman(shift);
}

sub new {
    my $proto = shift;
    my $arg   = shift;
    if ( $arg =~ /^\d+$/ ) { # looks like an arabic number
        croak __PACKAGE__, " does not like numbers above 3999" if $arg > 3999;
        return $proto->SUPER::new( { roman => Roman::Roman($arg), num => $arg } );
    } elsif ( Roman::isroman($arg) ) {
        return $proto->SUPER::new( { roman => $arg, num => Roman::arabic($arg) } );
    } else {
        croak "$arg does not look like a (roman or arabic) number";
    }
}

sub plus {
    my $r1 = shift;
    my $r2 = shift;
    my $num1 = ref $r1 ? $r1->num : is_roman($r1) ? to_number($r1) : $r1;
    my $num2 = ref $r2 ? $r2->num : is_roman($r2) ? to_number($r2) : $r2;
    return __PACKAGE__->new( $num1 + $num2 );
}

sub minus {
    my $r1 = shift;
    my $r2 = shift;
    my $num1 = ref $r1 ? $r1->num : is_roman($r1) ? to_number($r1) : $r1;
    my $num2 = ref $r2 ? $r2->num : is_roman($r2) ? to_number($r2) : $r2;
    return __PACKAGE__->new( $num1 - $num2 );
}

sub times {
    my $r1 = shift;
    my $r2 = shift;
    my $num1 = ref $r1 ? $r1->num : is_roman($r1) ? to_number($r1) : $r1;
    my $num2 = ref $r2 ? $r2->num : is_roman($r2) ? to_number($r2) : $r2;
    return __PACKAGE__->new( $num1 * $num2 );
}

use vars qw( $AUTOLOAD );

sub make_autoload {
    my $package = shift;
    return sub {
        my $sub_name = $AUTOLOAD;
        $sub_name =~ s/^.*:://;
        if ( is_roman($sub_name) ) {
            return Acme::Roman->new($sub_name);
        } else {
            croak "Undefined subroutine $AUTOLOAD called";
        }
    };
}

use Scalar::Util qw( set_prototype );

sub def_prototypes {
    my $package = shift;
    use strict;
    for ( 1..3999 ) {
        my $roman = to_roman($_);
        # sets an empty prototype
        set_prototype( \&{ "${package}::${roman}" }, '' ); 
        #eval "sub ${package}::${roman} (); ";
    }
}

sub import {
    my $package = caller;

    def_prototypes($package);

    my $autoload = make_autoload($package);
    no strict 'refs';
    *{ "${package}::AUTOLOAD" } = $autoload;
}

1;

__END__

=head1 NAME

Acme::Roman - Do maths like Romans did

=head1 SYNOPSIS

    use Acme::Roman;

    print I + II; # III, of course!

=head1 DESCRIPTION

The Roman Empire ruled over a large part of the ocidental world 
for a long time, probably too long for the conquested people.

They were finally won and there are some who say it was because
they could not do mathematics. Such liars!

This module redeems Perl with the ungratefully forgotten
Roman numbers, which now can find their glory again.

=head1 INSPIRATION

That module was inspired by

    Ruby Quiz - Roman Numerals (#22)
    http://rubyquiz.com/quiz22.html

See the hightlighted solution at the Quiz Summary in the same page.

=head1 EXAMPLES

Take a look at F<< eg/roman.pl >> in this distribution
for an amusing example.

=head1 BUGS

Acme::Roman does not like numbers greater than 3999.
Why would you like such big numbers? 

Only knows how to do addition, subtraction and multiplication.
What else do you think that Romans did with such a lovely
numeric system?

Ranges (like I..X) don't work :(

The actual implementation does a bit of brute force when
defining empty prototypes so that barewords are resolved
into subroutine calls. I don't know if it can be fixed.

If you find a bug, tell Julio Caesar from a respectful and safe distance.
(He's always looking for entertainment at the circus. And lions are
ever hungry.) If you prefer, you might file a report at 
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Roman or via e-mail at 
bug-Acme-Roman@rt.cpan.org. (Ok, CPAN RT now likes me again.)

=head1 AUTHOR

Adriano R. Ferreira E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007, 2008 Adriano R. Ferreira

The Acme::Roman module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
