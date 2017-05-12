package Array::Each::Override;

use strict;
use warnings;

our $VERSION = '0.05';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Scalar::Util qw<reftype>;
use Carp qw<croak>;

my @FUNCTIONS = qw<each keys values>;
my %KNOWN_FUNCTION = map { ($_ => 1, "array_$_" => 1) } @FUNCTIONS;

sub import {
    my ($class, @imports) = @_;
    my $caller = caller;
    for my $export (_parse_import_list($caller, @imports)) {
        my ($dest, $name, $func) = @$export{qw<dest name func>};
        no strict qw<refs>;
        *{"$dest\::$name"} = $func;
    }
}

sub unimport {
    my ($package, @imports) = @_;
    my $caller = caller;
    for my $export (_parse_import_list($caller, @imports)) {
        my ($dest, $name, $func) = @$export{qw<dest name func>};
        no strict qw<refs>;
        delete ${"$dest\::"}{$name}
    }
}

sub _parse_import_list {
    my ($importer, @imports) = @_;

    for my $name (@imports) {
        croak "Unknown function '$name'"
            if !$KNOWN_FUNCTION{$name}
            && $name ne ':global'
            && $name ne ':safe';
    }

    my $mode = '';
    $mode = shift @imports
        if @imports && $imports[0] =~ /\A :/xms;

    croak ":global or :safe must be the first item in the import list"
        if grep { /^:/ } @imports;

    @imports = @FUNCTIONS if !@imports;

    $importer = 'CORE::GLOBAL'
        if $mode eq ':global';

    return map {
        (my $func_name = $_) =~ s/\A (?!array_)/array_/xms;
        $_ = $func_name if $mode eq ':safe';
        my $func = do { no strict 'refs'; \&$func_name };
        +{
            dest => $importer,
            func => $func,
            name => $_,
        };
    } @imports;
}

1;

=head1 NAME

Array::Each::Override - C<each> for iterating over an array's keys and values

=head1 SYNOPSIS

    use Array::Each::Override;

    my @array = get_data();
    while (my ($i, $val) = each @array) {
        print "Position $i contains: $val\n";
    }

=head1 DESCRIPTION

This module provides new implementations of three core functions: C<each>,
C<values>, and C<keys>.

=over 4

=item C<each>

The core C<each> function iterates over a hash; each time it's called, it
returns a 2-element list of a key and value in the hash.  The new version of
C<each> does not change the behaviour of C<each> when called on a hash.
However, it also allows you to call C<each> on array.  Each time it's called,
it returns a 2-element list of the next uniterated index in the the array, and
the value at that index.

When the array is entirely iterated, an empty list is returned in list context.
The next call to array C<each> after that will start iterating again.

=item C<keys>

The core C<keys> function returns a list of the keys in a hash, or a count of
the keys in a hash when called in scalar context.  The new version of C<keys>
does not change the behaviour of C<keys> when called on a hash.  However, it
also allows you to call C<keys> on an array.

In list context, C<keys @array> returns a list of the indexes in the array; in
scalar context, it returns the number of elements in the array.

=item C<values>

The core C<values> function returns a list of the values in a hash, or a count
of the values in a hash when called in scalar context.  The new version of
C<values> does not change the behaviour of C<values> when called on a hash.
However, it also allows you to call C<values> on an array.

In list context, C<values @array> returns a list of the elements in the array;
in scalar context, it returns the number of elements in the array.

=back

There is a single iterator for each array, shared by all C<each>, C<keys>, and
C<values> calls in the program.  It can be reset by reading all the elements
from the iterator with C<each>, or by evaluating C<keys @array> or C<values
@array>.

=head1 ALTERNATIVE NAMES

You may prefer not to change the core C<each>, C<keys>, and C<values>
functions.  If so, you can import the new functions under alternative,
noninvasive names:

    use Array::Each::Override qw<array_each array_keys array_values>;

Or to import all of them in one go:

    use Array::Each::Override qw<:safe>;

Or mix and match:

    use Array::Each::Override qw<each array_keys array_values>;

The functions with these noninvasive names behave exactly the same as the
overridden core functions.

You might alternatively prefer to make the new functions available to all parts
of your program in one fell swoop:

    use Array::Each::Override qw<:global>;

Or make just some of the functions global:

    use Array::Each::Override qw<:global each keys>;

You can also unimport names.  For example, this removes the globally overridden
functions:

    no Array::Each::Override qw<:global>;

=head1 BUGS

=over 4

=item *

If you set C<$[> to anything other than 0, then (a) please stop doing that,
because it's been deprecated for a long time, and (b) C<each>, C<keys>, and
C<values> on arrays probably don't do what you expect.

=item *

Importing and unimporting function names has an effect on your entire package,
not just your lexical scope.

=item *

There may be some outstanding memory leaks.

=item *

Tied arrays haven't been tested at all.

=back

=head1 PERFORMANCE

There is some overhead for calling the new functions on a hash, compared to
the standard core functions.  The approximate penalties in each case are as
follows:

=over 4

=item C<each %hash>

20-25%

=item scalar-context C<keys %hash>

55-60%

=item scalar-context C<values %hash>

60-65%

=item list-context C<keys %hash>

1%

=item list-context C<values %hash>

1%

=back

If this performance penalty bothers you, use the C<:safe> function names
instead.

=head1 SEE ALSO

L<perlfunc|each>, L<perlfunc|keys>, L<perlfunc|values>.

=head1 AUTHOR

Aaron Crane E<lt>arc@cpan.orgE<gt>

Thanks to Chia-Liang Kao for his help in getting this working.

=head1 COPYRIGHT

Copyright 2007 Aaron Crane.

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License, or (at your option) under the terms of the
GNU General Public License version 2.

=cut
