package Class::Wrap;
require Exporter;
use strict;
use warnings;

our @EXPORT = qw(wrap);
our @ISA= qw(Exporter);
our $VERSION = "1.0";

sub wrap (&$) {
    my ($subref, $class) = @_;
    no strict;
    no warnings 'redefine';
    for my $c (keys %{"${class}::"}) {
        *{"hidden::".$class."::$c"} = *{$class."::$c"}{CODE};
        *{$class."::$c"} = sub {
            my $continue = 1;
            $continue = $subref->($c,@_) 
                unless $c eq "AUTOLOAD" and $AUTOLOAD =~ /DESTROY$/; 
            ${"${class}::AUTOLOAD"} = $AUTOLOAD if $c eq "AUTOLOAD";
            goto &{"hidden::${class}::$c"} if $continue; 
        };
    }
}

1;

__END__

=head1 NAME

Class::Wrap - Proxy an entire class's methods.

=head1 SYNOPSIS

    use Some::Class;
    use Class::Wrap;

    wrap { print "We called the ", shift, " method!\n" } Some::Class;

=head1 DESCRIPTION

There are several modules on CPAN which claim to help with wrapping
classes; this is not like any of them. It provides a single pre- wrapper
on all of a class's defined methods; it works on a class instead of an
object basis.

The scenario I had in mind was wanting to know which methods of a
particular class were being used by a very complex program;
C<Class::Wrap> helped understand what was being used and when, in order
to make a decision about whether or not to replace the class.

It should be smart enough to do the right thing with AUTOLOADs.

=head1 EXPORTS

The module provides the C<wrap> function:

    wrap { coderef } "Package Name";

This will wrap all existing methods in the given class. The coderef is
passed the name of the method called plus the parameters. This allows
you to perform different actions based on the name of the method, so
it's not a problem that only one wrapper fits the whole class.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 LICENSE

You may use and distribute this module under the terms of the Artistic
or GPL licenses, at your choice.
