package Class::Accessor::PackedString;

our $DATE = '2017-09-01'; # DATE
our $VERSION = '0.001'; # VERSION

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

    my $attrs = $spec->{accessors};

    # store list of accessors in the package
    {
#IFUNBUILT
#         no warnings 'once';
#END IFUNBUILT
        %{"$class\::HAS_PACKED"} = %$attrs;
    }

    # generate accessors
    my %idx; # key = attribute name, value = index
    my $pack_template = "";
    for my $attr (sort keys %$attrs) {
        $idx{$attr} = keys(%idx);
        $pack_template .= $attrs->{$attr};
    }
    my $num_attrs = keys %$attrs;

    for my $attr (keys %$attrs) {
        my $idx = $idx{$attr};
        my $code_str = 'sub (;$) {';
        $code_str .= qq( my \$self = shift;);
        $code_str .= qq( my \@attrs = unpack("$pack_template", \$\$self););
        $code_str .= qq( if (\@_) { \$attrs[$idx] = \$_[0]; \$\$self = pack("$pack_template", \@attrs) });
        $code_str .= qq( return \$attrs[$idx];);
        $code_str .= " }";
        #print "D:accessor code for $attr: ", $code_str, "\n";
        *{"$class\::$attr"} = eval $code_str;
        die if $@;
    }

    # generate constructor
    {
        my $code_str;
        $code_str  = 'sub { my ($class, %args) = @_;';
        $code_str .= qq( no warnings 'uninitialized';);
        $code_str .= qq( my \@attrs = map { undef } 1..$num_attrs;);
        for my $attr (sort keys %$attrs) {
            my $idx = $idx{$attr};
            $code_str .= qq( if (exists \$args{'$attr'}) { \$attrs[$idx] = delete \$args{'$attr'} });
        }
        $code_str .= ' die "Unknown $class attributes in constructor: ".join(", ", sort keys %args) if keys %args;';
        $code_str .= qq( my \$self = pack('$pack_template', \@attrs); bless \\\$self, '$class';);
        $code_str .= ' }';

        #print "D:constructor code for class $class: ", $code_str, "\n";
        my $constructor = $spec->{constructor} || "new";
        unless (*{"$class\::$constructor"}{CODE}) {
            *{"$class\::$constructor"} = eval $code_str;
            die if $@;
        };
    }
}

1;
# ABSTRACT: Generate accessors/constructor for object that use pack()-ed string as storage backend

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Accessor::PackedString - Generate accessors/constructor for object that use pack()-ed string as storage backend

=head1 VERSION

This document describes version 0.001 of Class::Accessor::PackedString (from Perl distribution Class-Accessor-PackedString), released on 2017-09-01.

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Accessor::PackedString {
     # constructor => 'new',
     accessors => {
         foo => "f",
         bar => "c",
     },
 };

In code that uses your class:

 use Your::Class;

 my $obj = Your::Class->new;
 $obj->foo(1.2);
 $obj->bar(34);

or:

 my $obj = Your::Class->new(foo => 1.2, bar => 34);

C<$obj> is now:

 bless(do{\(my $o = pack("fc", 1.2, 34))}, "Your::Class")

To subclass, in F<lib/Your/Subclass.pm>:

 package Your::Subclass;
 use parent 'Your::Class';
 use Class::Accessor::PackedString {
     accessors => {
         %Your::Class::HAS_PACKED,
         baz => "a8",
         qux => "a8",
     },
 };

=head1 DESCRIPTION

This module is a builder for classes that use pack()-ed string as memory storage
backend. This is useful in situations where you need to create many (e.g.
thousands+) objects in memory and want to reduce memory usage, because
string-based objects are more space-efficient than the commonly used hash-based
objects. The downsides are: 1) you have to predeclare all the attributes of your
class along with their types (pack() templates); 2) you can only store data
which can be pack()-ed; 3) slower speed, because unpack()-ing and re-pack()-ing
are done everytime an attribute is accessed or set.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Class-Accessor-PackedString>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Class-Accessor-PackedString>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-PackedString>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Class::Accessor::PackedString::Set>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
