package Class::MaybeXSAccessor;

our $DATE = '2016-05-04'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our $_target_spec;

sub import {
    my $pkg = shift;
    my $spec = shift;

    my $caller = caller();

    if (eval { require Class::XSAccessor; 1 }) {
        # XXX bad, bad implementation. we need to call _generate_method directly
        $_target_spec = {
            constructor => 'new',
            accessors => { map { $_ => $_ } @{ $spec->{accessors} // [] } },
        };
        eval "package $caller; Class::XSAccessor->import(\$Class::MaybeXSAccessor::_target_spec);";
        die if $@;
    } else {
        require Class::Accessor;
        push @{"$caller\::ISA"}, "Class::Accessor";
        $caller->_mk_accessors('rw', @{ $spec->{accessors} });
    }
}

1;
# ABSTRACT: Generate accessors/constructor

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::MaybeXSAccessor - Generate accessors/constructor

=head1 VERSION

This document describes version 0.001 of Class::MaybeXSAccessor (from Perl distribution Class-MaybeXSAccessor), released on 2016-05-04.

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::MaybeXSAccessor {
     accessors => [qw/foo bar/],
 };

In code that uses your class:

 use Your::Class;

 my $obj = Your::Class->new;
 $obj->foo(1980);
 $obj->bar(12);

=head1 DESCRIPTION

B<EARLY, EXPERIMENTAL>.

This module can be used to generate accessors/constructor. It will use
L<Class::XSAccessor> if available, falling back to L<Class::Accessor>. Note that
not all features from Class::Accessor nor Class::XSAccessor are supported.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Class-MaybeXSAccessor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Class-MaybeXSAccessor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-MaybeXSAccessor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Class::Accessor>

L<Class::XSAccessor>

L<Class::MaybeXSAccessor::Array>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
