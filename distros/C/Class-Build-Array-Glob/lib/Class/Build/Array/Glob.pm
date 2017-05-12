package Class::Build::Array::Glob;

our $DATE = '2016-03-27'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Hook::AfterRuntime;

our %all_attribute_specs; # key=class, value=[$attr, \%predicates, ...]

sub _collect_attributes {
    my ($target_class, $package, $attrs) = @_;

    for my $parent (@{"$package\::ISA"}) {
        _collect_attributes($target_class, $parent, $attrs);
    }
    push @$attrs, @{ $all_attribute_specs{$package} // [] };
}

sub import {
    my $class0 = shift;

    my $caller = caller();
    *{"$caller\::has"} = sub {
        my ($attr_name, %predicates) = @_;
        push @{ $all_attribute_specs{$caller} }, [$attr_name, \%predicates];

        # define the sub first, to allow things like Role::Tiny::With to check
        # the existence of required methods
        my $is = $predicates{is} // 'ro';
        *{"$caller\::$attr_name"} = $is eq 'rw' ? sub(;$) {} : sub() {};
    };
    after_runtime {
        my @attr_specs;

        # prepend the parent classes' attributes
        _collect_attributes($caller, $caller, \@attr_specs);

        my $glob_attr;
        my %attr_indexes;
        # generate the accessor methods
        {
            no warnings 'redefine';
            my $idx = 0;
            for my $attr_spec (@attr_specs) {
                my ($attr_name, $predicates) = @$attr_spec;
                next if defined $attr_indexes{$attr_name};
                $attr_indexes{$attr_name} = $idx;
                die "Class $caller attribute $attr_name: can't declare ".
                    "another attribute after globbing attribute ($glob_attr)"
                    if defined $glob_attr;
                if ($predicates->{glob}) {
                    $glob_attr = $attr_name;
                }
                my $is = $predicates->{is} // 'ro';
                my $code_str = $is eq 'rw' ? 'sub (;$) { ' : 'sub () { ';
                if (defined $glob_attr) {
                    $code_str .= "splice(\@{\$_[0]}, $idx, scalar(\@{\$_[0]}), \@{\$_[1]}) if \@_ > 1; "
                        if $is eq 'rw';
                    $code_str .= "[ \@{\$_[0]}[$idx .. \$#{\$_[0]}] ]; ";
                } else {
                    $code_str .= "\$_[0][$idx] = \$_[1] if \@_ > 1; "
                        if $is eq 'rw';
                    $code_str .= "\$_[0][$idx]; ";
                }
                $code_str .= "}";
                #say "D:accessor code for attr $attr_name: ", $code_str;
                *{"$caller\::$attr_name"} = eval $code_str;
                die if $@;
                $idx++;
            }
        }

        # generate constructor
        {
            my $code_str = 'sub { ';
            $code_str .= 'my ($class, %args) = @_; ';
            if (defined $glob_attr) {
                $code_str .= 'my $obj = bless [(undef) x '.(scalar(keys %attr_indexes)-1).'], $class; ';
            } else {
                $code_str .= 'my $obj = bless [], $class; ';
            }
            for my $attr_name (sort keys %attr_indexes) {
                my $idx = $attr_indexes{$attr_name};
                if (defined($glob_attr) && $attr_name eq $glob_attr) {
                    $code_str .= "if (exists \$args{'$attr_name'}) { splice(\@\$obj, $idx, scalar(\@\$obj), \@{ \$args{'$attr_name'} }) } ";
                } else {
                    $code_str .= "if (exists \$args{'$attr_name'}) { \$obj->[$idx] = \$args{'$attr_name'} } ";
                }
            }
            $code_str .= '$obj; }';
            #say "D:constructor code for class $caller: ", $code_str;
            unless (*{"$caller\::new"}{CODE}) {
                *{"$caller\::new"} = eval $code_str;
                die if $@;
            };
        }

        # cleanup, so user can't do $obj->has(...) etc later
        undef *{"$caller\::has"};
    };
}

1;
# ABSTRACT: Generate Class accessors/constructor (array-based object, supports globbing attribute)

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Build::Array::Glob - Generate Class accessors/constructor (array-based object, supports globbing attribute)

=head1 VERSION

This document describes version 0.01 of Class::Build::Array::Glob (from Perl distribution Class-Build-Array-Glob), released on 2016-03-27.

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Build::Array::Glob;

 has foo => (is => 'rw');
 has bar => (is => 'rw');
 has baz => (is => 'rw', glob=>1);

In code that uses your class, use your class as usual:

 use Your::Class;

 my $obj = Your::Class->new(foo => 1);
 $obj->bar(2);

 my $obj2 = Your::Class->new(foo=>11, bar=>12, baz=>[13, 14, 15]);

C<$obj1> is now:

 bless([1, 2], "Your::Class");

C<$obj2> is now:

 bless([11, 12, 13, 14, 15], "Your::Class");

=head1 DESCRIPTION

This module is a class builder for array-backed classes. With it you can declare
your attributes using Moose-style C<has>. Only these C<has> predicates are
currently supported: C<is> (ro/rw), C<glob> (bool). Array index will be
determined by the order of declaration, so in the example in Synopsis, C<foo>
will be stored in element 0, C<bar> in element 1.

The predicate C<glob> can be specified for the last attribute. It means the
attribute has an array value that are put in the end of the object backend
array's elements. So in the example in Synopsis, C<baz>value's elements will
occupy object backend array's elements 2 and subsequent.

There can only be at most one attribute with B<glob> set to true. After the
globbing attribute, there can be no more arguments (so subclassing a class with
a globbing attribute is not possible).

Note that without globbing attribute, you can still store arrays or other
complex data in your attributes. It's just that with a globbing attribute, you
can keep a single flat array backend, so the overall number of arrays is
minimized.

An example of application: tree node objects, where the first attribute (array
element) is the parent, then zero or more extra attributes, then the last
attribute is a globbing one storing zero or more children. This is how
L<Mojo::DOM> stores its HTML tree node, for example.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Class-Build-Array-Glob>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Class-Build-Array-Glob>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Build-Array-Glob>

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
