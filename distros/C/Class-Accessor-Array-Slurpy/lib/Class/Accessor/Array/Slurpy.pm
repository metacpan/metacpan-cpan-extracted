package Class::Accessor::Array::Slurpy;

our $DATE = '2017-09-13'; # DATE
our $VERSION = '0.020'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

sub import {
    my ($class0, $spec) = @_;
    my $caller = caller();

    no warnings 'redefine';

    my $max_idx;
    for (values %{$spec->{accessors}}) {
        $max_idx = $_ if !defined($max_idx) || $max_idx < $_;
    }

    my $slurpy_attribute = $spec->{slurpy_attribute};

    # generate accessors
    for my $meth (keys %{$spec->{accessors}}) {
        my $idx = $spec->{accessors}{$meth};
        my $is = 'rw';
        my $code_str = $is eq 'rw' ? 'sub (;$) { ' : 'sub () { ';
        if (defined($slurpy_attribute) && $slurpy_attribute eq $meth) {
            die "Slurpy attribute must be put at the last index"
                unless $idx == $max_idx;
            $code_str .= "splice(\@{\$_[0]}, $idx, scalar(\@{\$_[0]}), \@{\$_[1]}) if \@_ > 1; "
                if $is eq 'rw';
            $code_str .= "[ \@{\$_[0]}[$idx .. \$#{\$_[0]}] ]; ";
        } else {
            $code_str .= "\$_[0][$idx] = \$_[1] if \@_ > 1; "
                if $is eq 'rw';
            $code_str .= "\$_[0][$idx]; ";
        }
        $code_str .= "}";
        #say "D:accessor code for $meth: ", $code_str;
        *{"$caller\::$meth"} = eval $code_str;
        die if $@;
    }

    # generate constructor
    {
        my $n = ($max_idx // 0) + 1; $n-- if defined $slurpy_attribute;
        my $code_str = 'sub { my $class = shift; bless [(undef) x '.$n.'], $class }';

        #say "D:constructor code for class $caller: ", $code_str;
        my $constructor = $spec->{constructor} || "new";
        unless (*{"$caller\::$constructor"}{CODE}) {
            *{"$caller\::$constructor"} = eval $code_str;
            die if $@;
        };
    }
}

1;
# ABSTRACT: Generate accessors/constructor for array-based object (supports slurpy attribute)

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Accessor::Array::Slurpy - Generate accessors/constructor for array-based object (supports slurpy attribute)

=head1 VERSION

This document describes version 0.020 of Class::Accessor::Array::Slurpy (from Perl distribution Class-Accessor-Array-Slurpy), released on 2017-09-13.

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Accessor::Array::Slurpy {
     accessors => {
         foo => 0,
         bar => 1,
         baz => 2,
     },
     slurpy_attribute => 'baz',
 };

In code that uses your class:

 use Your::Class;

 my $obj = Your::Class->new;
 $obj->foo(1);
 $obj->bar(2);
 $obj->baz([3,4,5]);

C<$obj> is now:

 bless([1, 2, 3, 4, 5], "Your::Class");

=head1 DESCRIPTION

This module is a builder for array-backed classes. It is the same as
L<Class::Accessor::Array> except that you can define your last (in term of the
index in array storage) attribute to be a "slurpy attribute", meaning it is an
array where its elements are stored as elements of the array storage. There can
be at most one slurpy attribute and it must be the last.

Note that without a slurpy attribute, you can still store arrays or other
complex data in your attributes. It's just that with a slurpy attribute, you can
keep a single flat array backend, so the overall number of arrays is minimized.

An example of application: tree node objects, where the first attribute (array
element) is the parent, then zero or more extra attributes, then the last
attribute is a slurpy one storing zero or more children. This is how
L<Mojo::DOM> stores its HTML tree node, for example.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Class-Accessor-Array-Slurpy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Class-Accessor-Array-Slurpy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-Array-Slurpy>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other class builders for array-backed objects: L<Class::Accessor::Array>,
L<Class::XSAccessor::Array>, L<Class::ArrayObjects>, L<Object::ArrayType::New>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
