package Class::Accessor::Array;

our $DATE = '2016-03-28'; # DATE
our $VERSION = '0.02'; # VERSION

sub import {
    my ($class0, $spec) = @_;
    my $caller = caller();

    no warnings 'redefine';

    # generate accessors
    for my $meth (keys %{$spec->{accessors}}) {
        my $idx = $spec->{accessors}{$meth};
        my $code_str = 'sub (;$) { ';
        $code_str .= "\$_[0][$idx] = \$_[1] if \@_ > 1; ";
        $code_str .= "\$_[0][$idx]; ";
        $code_str .= "}";
        #say "D:accessor code for $meth: ", $code_str;
        *{"$caller\::$meth"} = eval $code_str;
        die if $@;
    }

    # generate constructor
    {
        my $code_str = 'sub { my $class = shift; bless [], $class }';

        #say "D:constructor code for class $caller: ", $code_str;
        my $constructor = $spec->{constructor} || "new";
        unless (*{"$caller\::$constructor"}{CODE}) {
            *{"$caller\::$constructor"} = eval $code_str;
            die if $@;
        };
    };
}

1;
# ABSTRACT: Generate accessors/constructor for array-based object

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Accessor::Array - Generate accessors/constructor for array-based object

=head1 VERSION

This document describes version 0.02 of Class::Accessor::Array (from Perl distribution Class-Accessor-Array), released on 2016-03-28.

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Accessor::Array {
     accessors => {
         foo => 0,
         bar => 1,
     },
 };

In code that uses your class:

 use Your::Class;

 my $obj = Your::Class->new;
 $obj->foo(1980);
 $obj->bar(12);

C<$obj> is now:

 bless([1980, 12], "Your::Class");

=head1 DESCRIPTION

This module is a builder for array-backed classes.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Class-Accessor-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Class-Accessor-Array>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other class builders for array-backed objects: L<Class::XSAccessor::Array>,
L<Class::ArrayObjects>, L<Object::ArrayType::New>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
