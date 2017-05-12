package Class::Privacy;

use strict;

require 5.006001; # Overloading %{} et alia doesn't work before this.

our $VERSION = 0.03;

sub import {
    my $class = shift;
    my ($caller, $file) = (caller(0))[0,1];
    my $check = "Class::Privacy::check::$caller";
    eval <<__EOF__;
sub $check {
    my (\$caller, \$file, \$line) = (caller(0))[0,1,2];
    if (\$caller eq "$caller" && \$file eq "$file") {
	return \$_[0];
    } else {
	# Tried to use Carp::croak here but that lead into strange
	# error where Carp::Heavy tried to stringify the object for
	# no apparent good reason.  Anyway, using die() directly
	# is here much simpler and faster.
	die("Cannot dereference '$caller' object at \$file line \$line.\n");
    }
}
package $caller;
use overload
    '\%{}' => \\&$check,
    '\@{}' => \\&$check,
    '\${}' => \\&$check,
    '\&{}' => \\&$check; # Unlikely, but while we are at it...
__EOF__
}

1;
__END__

=head1 NAME

Class::Privacy - object data privacy

=head1 SYNOPSIS

    use Class::Privacy;

=head1 DESCRIPTION

With the Class::Privacy module you can deny other classes from trying
to directly access the data of your objects.  Simply add the following
to your class:

    use Class::Privacy;

This disallows any outside attempts to directly access (dereference)
the inner parts of the objects, only the class itself can do it.
For outsiders the only allowed access is through the methods defined
in the class.

This is what happens if an outsider tries to access the innards of
the objects:

    Cannot dereference 'NoPeeking' object at ...

The denial of access includes even derived classes.  In other words,
this is what most object-oriented languages call I<private>.

There is no way to have I<protected>, I<package>, I<friend> or any
other privacy levels.  This can be considered to be a feature, not
a bug.

=head1 IMPLEMENTATION

The Class:Privacy relies on overloading of the dereferencers %{}, @{},
and ${} (and &{}, just in case).  Overloading those operations didn't
work properly before Perl 5.6.1.  This also means that you cannot have
your own overloads for these operations for your objects, but you can
still have other overloaded operations.

The protection is probably not foolproof since fools are so ingenious.

=head1 AUTHOR

Jarkko Hietaniemi

=head1 COPYRIGHT AND LICENSE

Copyright 2002 Jarkko Hietaniemi All Rights Reserved

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

