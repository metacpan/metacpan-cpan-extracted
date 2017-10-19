package Class::Accessor::PackedString::Set;

our $DATE = '2017-10-15'; # DATE
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
        @{"$class\::HAS_PACKED"} = @$attrs;
    }

    # generate accessors
    my %idx     ; # key = attribute name, value = index
    my %tmpl    ; # key = attribute name, value = pack() template
    my %tmplsize; # key = attribute name, value = pack() data size
    my @attrs = @$attrs;
    while (my ($name, $template) = splice @attrs, 0, 2) {
        $idx{$name}      = keys %idx;
        $tmpl{$name}     = $template;
        $tmplsize{$name} = length(pack $template);
    }

    @attrs = @$attrs;
    while (my ($name, $template) = splice @attrs, 0, 2) {
        my $idx = $idx{$name};
        my $code_str = 'sub (;$) {' . "\n";
        $code_str .= qq(  my \$self = shift;\n);

        $code_str .= qq(  my \$val;\n  my \$pos = 0;\n  while (1) {\n    last if \$pos >= length(\$\$self);\n    my \$idx = ord(substr(\$\$self, \$pos++, 1));\n);
        for my $attr (sort {$idx{$a} <=> $idx{$b}} keys %idx) {
            my $idx = $idx{$attr};
            $code_str .= qq|    |.($idx == 0 ? "if   " : "elsif").qq| (\$idx == $idx) { my \$v = unpack("| . $tmpl{$attr} . qq|", substr(\$\$self, \$pos, | . $tmplsize{$attr} . qq|));|;
            if ($attr eq $name) {
                $code_str .= qq| \$val = \$v; if (\@_ && defined \$_[0]) { substr(\$\$self, \$pos, | . $tmplsize{$attr} . qq|) = pack("| . $tmpl{$attr} . qq|", \$_[0]); return \$val } last|;
            } else {
                $code_str .= qq| \$pos += | . $tmplsize{$attr} . qq|; next|;
            }
            $code_str .= qq| }\n|;
        }
        $code_str .= qq(    else  { die "Invalid data in object \$self: invalid index \$idx" }\n);
        $code_str .= qq(  }\n);

        $code_str .= qq(  return \$val unless \@_;\n);
        $code_str .= qq(  if (defined \$_[0]) {\n); # set a newly set attribute, append
        $code_str .= qq|    \$\$self .= chr($idx) . pack("|. $tmpl{$name} . qq|", \$_[0]);\n|;
        $code_str .= qq(  } elsif (defined \$val) {\n); # delete unset attribute
        $code_str .= qq|    substr(\$\$self, \$pos-1, | . $tmplsize{$name} . qq|+1) = "";\n|;
        $code_str .= qq(  }\n);
        $code_str .= qq(  return \$val;\n);
        $code_str .= "}\n";
        #print "D:accessor code for $name: ", $code_str, "\n";
        *{"$class\::$name"} = eval $code_str;
        die if $@;
    }

    # generate constructor
    {
        my $code_str;

        $code_str = 'sub { my $o = ""; bless \$o, shift }';

        # TODO

        #$code_str  = 'sub { my ($class, %args) = @_;';
        #$code_str .= qq( no warnings 'uninitialized';);
        #$code_str .= qq( my \@attrs = map { undef } 1..$num_attrs;);
        #for my $attr (sort keys %$attrs) {
        #    my $idx = $idx{$attr};
        #    $code_str .= qq( if (exists \$args{'$attr'}) { \$attrs[$idx] = delete \$args{'$attr'} });
        #}
        #$code_str .= ' die "Unknown $class attributes in constructor: ".join(", ", sort keys %args) if keys %args;';
        #$code_str .= qq( my \$self = pack('$pack_template', \@attrs); bless \\\$self, '$class';);
        #$code_str .= ' }';

        #print "D:constructor code for class $class: ", $code_str, "\n";
        my $constructor = $spec->{constructor} || "new";
        unless (*{"$class\::$constructor"}{CODE}) {
            *{"$class\::$constructor"} = eval $code_str;
            die if $@;
        };
    }
}

1;
# ABSTRACT: Like Class::Accessor::PackedString, but store attributes as they are set

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Accessor::PackedString::Set - Like Class::Accessor::PackedString, but store attributes as they are set

=head1 VERSION

This document describes version 0.001 of Class::Accessor::PackedString::Set (from Perl distribution Class-Accessor-PackedString-Set), released on 2017-10-15.

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Accessor::PackedString::Set {
     # constructor => 'new',
     accessors => [
         foo => "f",
         bar => "c",
     ],
 };

In code that uses your class:

 use Your::Class;

 my $obj = Your::Class->new;

C<$obj> is now:

 bless(do{\(my $o = "")}, "Your::Class")

After:

 $obj->bar(34);

C<$obj> is now:

 bless(do{\(my $o = join("", chr(1), pack("c", 34)))}, "Your::Class")

After:

 $obj->foo(1.2);

C<$obj> is now:

 bless(do{\(my $o = join("", chr(1), pack("c", 34), chr(0), pack("f", 1.2)))}, "Your::Class")

After:

 $obj->bar(undef);

C<$obj> is now:

 bless(do{\(my $o = join("", chr(0), pack("f", 1.2)))}, "Your::Class")

To subclass, in F<lib/Your/Subclass.pm>:

 package Your::Subclass;
 use parent 'Your::Class';
 use Class::Accessor::PackedString::Set {
     accessors => [
         @Your::Class::HAS_PACKED,
         baz => "a8",
         qux => "a8",
     ],
 };

=head1 DESCRIPTION

This module is a builder for classes that use string as memory storage backend.
The string is initially empty when there are no attributes set. When an
attribute is set, string will be appended with this data:

 | size        | description                        |
 +-------------+------------------------------------+
 | 1 byte      | index of attribute                 |
 | (pack size) | attribute value, encoded by pack() |

When another attribute is set, string will be further appended. When an
attribute is unset (undef'd), its entry will be removed in the string.

This module is similar to L<Class::Accessor::PackedString>. Using string (of
pack()-ed data) is useful in situations where you need to create many (e.g.
thousands+) objects in memory and want to reduce memory usage, because
string-based objects are more space-efficient than the commonly used hash-based
objects. Unlike in Class::Accessor::PackedString, space is further saved by only
storing set attributes and not unset attributes. This particularly saves
significant space if you happen to have many attributes with usually only a few
of them set.

The downsides are: 1) you have to predeclare all the attributes of your class
along with their types (pack() templates); 2) you can only store data which can
be pack()-ed; 3) slower speed, because unpack()-ing and re-pack()-ing are done
everytime an attribute is accessed or set.

Caveats:

There is a maximum of 256 attributes.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Class-Accessor-PackedString-Set>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Class-Accessor-PackedString-Set>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-PackedString-Set>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Class::Accessor::PackedString>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
