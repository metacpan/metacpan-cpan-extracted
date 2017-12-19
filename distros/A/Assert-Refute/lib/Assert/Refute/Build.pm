package Assert::Refute::Build;

use 5.006;
use strict;
use warnings;
our $VERSION = 0.0305;

=head1 NAME

Assert::Refute::Build - tool for extending Assert::Refute suite

=head1 DESCRIPTION

Although arbitrary checks may be created using just the C<refute> function,
they may be cumbersome to use and especially share.

This module takes care of some boilerplate as well as maintains parity
between functional and object-oriented interfaces of L<Assert::Refute>.

=head1 SYNOPSIS

Extending the test suite goes as follows:

    package My::Package;
    use Assert::Refute::Build;
    use parent qw(Exporter);

    build_refute is_everything => sub {
        return if $_[0] == 42;
        return "$_[0] is not answer to life, universe, and everything";
    }, export => 1, args => 1;

    1;

This can be later used inside production code to check a condition:

    use Assert::Refute;
    use My::Package;
    my $fun_check = contract {
        is_everything( shift );
    };
    my $oo_check = contract {
        $_[0]->is_everything( $_[1] );
    }, need_object => 1;
    # ditto

    # apply $fun_check or $oo_check to a variable, get result

    my $log = $oo_check->apply(137);
    $log->is_passing; # nope
    $log->as_tap;     # get details

This call will create a prototyped function is_everything(...) in the calling
package, with C<args> positional parameters and an optional human-readable
message. (Think C<ok 1>, C<ok 1 'test passed'>).

=head1 FUNCTIONS

All functions are exportable.

=cut

use Carp;
use Scalar::Util qw(weaken blessed set_prototype looks_like_number refaddr);
use parent qw(Exporter);
our @EXPORT = qw(build_refute current_contract to_scalar);

our $BACKEND;

# NOTE HACK
# If we're being loaded after Test::More, we're *likely* inside a test script
# This has to be re-done properly
# Cannot instantiate *here* because cyclic dependencies
#    so wait until current_contract() is called
our $MORE_DETECTED = Test::Builder->can("new") ? 1 : 0;

=head2 build_refute name => \&CODE, %options

This function

=over

=item * accepts a subroutine reference that returns a false value on success
and a brief description of the discrepancy on failure
(e.g. C<"$got != $expected">);

Note that this function does not need to know anything about the testing
environment it is in, it just cares about its arguments
(think I<pure function>).

=item * builds an exportable wrapper around it that would talk to
the most recent L<Assert::Refute::Exec> instance;

=item * adds a method with the same name to L<Assert::Refute::Exec>
so that object-oriented and functional interfaces
are as close to each other as possible.

=back

As a side effect, Assert::Refute's internals are added to the caller's
C<@CARP_NOT> array so that carp/croak points to where the built function
is actually used.

B<NOTE> One needs to use Exporter explicitly if either C<export>
or C<export_ok> option is in use. This MAY change in the future.

Options may include:

=over

=item * C<export> => 1    - add function to @EXPORT
(Exporter still has to be used by target module explicitly).

=item * C<export_ok> => 1 - add function to @EXPORT_OK (don't export by default).

=item * C<no_create> => 1 - don't generate a function at all, just add to
L<Assert::Refute>'s methods.

=item * C<args> => C<nnn> - number of arguments.
This will generate a prototyped function
accepting C<nnn> scalars + optional description.

=item * C<list> => 1 - create a list prototype instead.
Mutually exclusive with C<args>.

=item * C<block> => 1 - create a block function.

=item * C<no_proto> => 1 - skip prototype, function will have to be called
with parentheses.

=back

=cut

my %Backend;
my %Carp_not;
my $trash_can = __PACKAGE__."::generated::For::Cover::To::See";
my %known;
$known{$_}++ for qw(args list block no_proto
    export export_ok no_create);

sub build_refute(@) { ## no critic # Moose-like DSL for the win!
    my ($name, $cond, %opt) = @_;

    my $class = "Assert::Refute::Exec";

    if (my $backend = ( $class->can($name) ? $class : $Backend{$name} ) ) {
        croak "build_refute(): '$name' already registered by $backend";
    };
    my @extra = grep { !$known{$_} } keys %opt;
    croak "build_refute(): unknown options: @extra"
        if @extra;
    croak "build_refute(): list and args options are mutually exclusive"
        if $opt{list} and defined $opt{args};

    my @caller = caller(0);
    my $target = $opt{target} || $caller[0];

    confess "Too bad (@caller)" if !$target or $target eq __PACKAGE__;

    my $nargs = $opt{args} || 0;
    $nargs = 9**9**9 if $opt{list};

    $nargs++ if $opt{block};

    # TODO Add executability check if $block
    my $method  = sub {
        my $self = shift;
        my $message; $message = pop unless @_ <= $nargs;

        return $self->refute( scalar $cond->(@_), $message );
    };
    my $wrapper = sub {
        my $message; $message = pop unless @_ <= $nargs;
        return current_contract()->refute( scalar $cond->(@_), $message );
    };
    if (!$opt{no_proto} and ($opt{block} || $opt{list} || defined $opt{args})) {
        my $proto = $opt{list} ? '@' : '$' x ($opt{args} || 0);
        $proto = "&$proto" if $opt{block};
        $proto .= ';$' unless $opt{list};

        # '&' for set_proto to work on a scalar, not {CODE;}
        &set_prototype( $wrapper, $proto );
    };

    $Backend{$name}   = "$target at $caller[1] line $caller[2]"; # just for the record
    my $todo_carp_not = !$Carp_not{ $target }++;
    my $todo_create   = !$opt{no_create};
    my $export        = $opt{export} ? "EXPORT" : $opt{export_ok} ? "EXPORT_OK" : "";

    # Magic below, beware!
    no strict 'refs'; ## no critic # really need magic here

    # set up method for OO interface
    *{ $class."::$name" } = $method;

    # FIXME UGLY HACK - somehow it makes Devel::Cover see the code in report
    *{ $trash_can."::$name" } = $cond;

    if ($todo_create) {
        *{ $target."::$name" } = $wrapper;
        push @{ $target."::".$export }, $name
            if $export;
    };
    if ($todo_carp_not) {
        no warnings 'once';
        push @{ $target."::CARP_NOT" }, "Assert::Refute::Contract", $class;
    };

    # magic ends here

    return 1;
};

=head2 current_contract

Returns a L<Assert::Refute::Exec> object.
Dies if no contract is being executed at the time.

=cut

sub current_contract() { ## nocritic
    return $BACKEND if $BACKEND;

    # Would love to just die, but...
    if ($MORE_DETECTED) {
        require Assert::Refute::Driver::More;
        return $BACKEND = Assert::Refute::Driver::More->new;
    };

    croak "Not currently testing anything";
};

=head2 to_scalar

Convert an arbitrary data structure to a human-readable string.

=over

=item * C<to_scalar( undef )> # returns C<'(undef)'>

=item * C<to_scalar( string )> # returns the string as is in quotes

=item * C<to_scalar( \%ref || \@array, $depth )>

Only goes C<$depth> levels deep. Default depth is 1.

=back

Hashes/arrays are only penetrated 1 level deep by default.

C<undef> is returned as C<"(undef)"> so it can't be confused with other types.

Strings are quoted unless numeric or depth is omitted.

Refs are returned as C<My::Module/1a2c3f> (NOT in perl's own format
C<My::Module=HASH(0x20f9190)>). This MAY change in the future.

=cut

my %replace = ( "\n" => "n", "\\" => "\\", '"' => '"', "\0" => "0", "\t" => "t" );
sub to_scalar {
    my ($data, $depth) = @_;

    return '(undef)' unless defined $data;
    if (!ref $data) {
        return $data if !defined $depth or looks_like_number($data);
        $data =~ s/([\0"\n\t\\])/\\$replace{$1}/g;
        $data =~ s/([^\x20-\x7E])/sprintf "\\x%02x", ord $1/ge;
        return "\"$data\"";
    };

    $depth = 1 unless defined $depth;

    if ($depth) {
        if (UNIVERSAL::isa($data, 'ARRAY')) {
            return (ref $data eq 'ARRAY' ? '' : ref $data)
                ."[".join(", ", map { to_scalar($_, $depth-1) } @$data )."]";
        };
        if (UNIVERSAL::isa($data, 'HASH')) {
            return (ref $data eq 'HASH' ? '' : ref $data)
            . "{".join(", ", map {
                 to_scalar($_, 0) .":".to_scalar( $data->{$_}, $depth-1 );
            } sort keys %$data )."}";
        };
    };
    return sprintf "%s/%x", ref $data, refaddr $data;
};
=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017 Konstantin S. Uvarin. C<< <khedin at gmail.com> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
