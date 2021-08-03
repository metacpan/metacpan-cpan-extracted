package Class::Accessor::Array;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-03'; # DATE
our $DIST = 'Class-Accessor-Array'; # DIST
our $VERSION = '0.032'; # VERSION

#IFUNBUILT
# use strict 'subs', 'vars';
# use warnings;
#END IFUNBUILT

sub import {
    my ($class0, $spec) = @_;
    my $caller = caller();

    my $class = $caller;

#IFUNBUILT
#     no warnings 'redefine';
#END IFUNBUILT

    # user does not specify 'accessors', perhaps she just loads it. so we just
    # return.
    return unless exists $spec->{accessors};

    # generate accessors
    for my $meth (keys %{$spec->{accessors}}) {
        my $idx = $spec->{accessors}{$meth};
        my $code_str = 'sub (;$) { ';
        $code_str .= "\$_[0][$idx] = \$_[1] if \@_ > 1; ";
        $code_str .= "\$_[0][$idx]; ";
        $code_str .= "}";
        #say "D:accessor code for $meth: ", $code_str;
        *{"$class\::$meth"} = eval $code_str;
        die if $@;
    }

    # generate constructor
    {
        my $code_str;
        $code_str  = 'sub { my ($class, %args) = @_;';
        if (@{"$class\::ISA"}) {
            $code_str .= ' require '.${"$class\::ISA"}[0].';';
            $code_str .= ' my $self = '.${"$class\::ISA"}[0].'->new(map {($_=>delete $args{$_})}'.
                ' grep {'.(join " && ", map {'$_ ne \''.$_.'\''} keys %{$spec->{accessors}}).'} keys %args);';
            $code_str .= ' $self = bless $self, \''.$class.'\';';
        } else {
            $code_str .= ' my $self = bless [], $class;';
        }
        $code_str .= ' for my $key (grep {'.(join " || ", map {'$_ eq \''.$_.'\''} keys %{$spec->{accessors}}).'} keys %args) { $self->$key(delete $args{$key}) }';
        $code_str .= ' die "Unknown $class attributes in constructor: ".join(", ", sort keys %args) if keys %args;';
        $code_str .= ' $self }';

        #print "D:constructor code for class $class: ", $code_str, "\n";
        my $constructor = $spec->{constructor} || "new";
        unless (*{"$class\::$constructor"}{CODE}) {
            *{"$class\::$constructor"} = eval $code_str;
            die if $@;
        };
    }
}

1;
# ABSTRACT: Generate accessors/constructor for array-based object

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Accessor::Array - Generate accessors/constructor for array-based object

=head1 VERSION

This document describes version 0.032 of Class::Accessor::Array (from Perl distribution Class-Accessor-Array), released on 2021-08-03.

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Accessor::Array {
     # constructor => 'new',
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

or:

 my $obj = Your::Class->new(foo => 1, bar => 2);

C<$obj> is now:

 bless([1980, 12], "Your::Class");

To subclass, in F<lib/Your/Subclass.pm>:

 package Your::Subclass;
 our @ISA = qw(Your::Class);
 use Class::Accessor::Array {
     accessors => {
         baz => 2,
     },
 };

=head1 DESCRIPTION

This module is a builder for array-backed classes.

You can change the constructor name from the default C<new> using the
C<constructor> parameter.

Currently the built constructor does not accept parameters to set the
attributes, e.g.:

 my $obj = Your::Class->new(foo=>1, bar=>2); # not supported

You have to set the attributes manually:

 # supported
 my $obj = Your::Class->new;
 $obj->foo(1);
 $obj->bar(2);

If you subclass from another class that uses L<Class::Accessor::Array>, you must
make sure that: 1) the parent class' constructor is C<new>; 2) you choose
attribute array indices that have not already been used (unless you deliberately
want to share storage space with attributes existing in the parent class).
Multiple inheritance is not supported.

Note that if you're looking to reduce memory storage usage, an object based on
Perl array is not that much-more-space-efficient compared to the hash-based
object. Try representing an object as a pack()-ed string instead using
L<Class::Accessor::PackedString>.

=for Pod::Coverage .+

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <sharyanto@cpan.org>

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

L<Class::Accessor::PackedString> and L<Class::Accessor::PackedString::Fields>.

Other class builders for array-backed objects: L<Class::XSAccessor::Array>,
L<Class::Accessor::Array::Glob>, L<Class::ArrayObjects>,
L<Object::ArrayType::New>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
