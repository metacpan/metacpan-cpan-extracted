package Assert::Refute::Build;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.1301';

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

    use Assert::Refute qw(:all);
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
    $log->get_tap;    # get details

This call will create a prototyped function is_everything(...) in the calling
package, with C<args> positional parameters and an optional human-readable
message. (Think C<ok 1>, C<ok 1 'test passed'>).

=head1 FUNCTIONS

All functions are exportable.

=cut

use Carp;
use Data::Dumper;
use Scalar::Util qw(weaken blessed set_prototype looks_like_number refaddr);
use parent qw(Exporter);
our @EXPORT = qw(build_refute current_contract to_scalar);

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
the most recent L<Assert::Refute::Report> instance;

=item * adds a method with the same name to L<Assert::Refute::Report>
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

=item * C<manual> => 1 - don't generate any code.
Instead, assume that user has already done that and just add a method
to L<Assert::Refute::Report> and a prototyped exportable wrapper.

This may be useful to create refutations based on subcontract or such.

B<[EXPERIMENTAL]>.

=item * C<args> => C<nnn> - number of arguments.
This will generate a prototyped function
accepting C<nnn> scalars + optional description.

=item * C<list> => 1 - create a list prototype instead.
Mutually exclusive with C<args>.

=item * C<block> => 1 - create a block function.

=item * C<no_proto> => 1 - skip prototype, function will have to be called
with parentheses.

=back

The name must not start with C<set_>, C<get_>, or C<do_>.
Also colliding with a previously defined name would case an exception.

=cut

my %Backend;
my %Carp_not;
my $trash_can = __PACKAGE__."::generated::For::Cover::To::See";
my %known;
$known{$_}++ for qw(args list block no_proto manual
    export export_ok no_create);

sub build_refute(@) { ## no critic # Moose-like DSL for the win!
    my ($name, $cond, %opt) = @_;

    my $class = "Assert::Refute::Report";

    if ($name =~ /^(get_|set_|do_)/) {
        croak "build_refute(): fucntion name shall not start with get_, set_, or do_";
    };
    if (my $backend = ( $class->can($name) && ($Backend{$name} || $class )) ) {
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
    my $method  = $opt{manual} ? $cond : sub {
        my $self = shift;
        my $message; $message = pop unless @_ <= $nargs;

        return $self->refute( scalar $cond->(@_), $message );
    };
    my $wrapper = $opt{manual} ? sub {
        return $cond->( $Assert::Refute::DRIVER || current_contract(), @_ );
    } : sub {
        my $message; $message = pop unless @_ <= $nargs;
        return (
            # Ugly hack for speed in happy case
            $Assert::Refute::DRIVER || current_contract()
        )->refute( scalar $cond->(@_), $message );
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

Returns a L<Assert::Refute::Report> object.
Dies if no contract is being executed at the time.

=cut

sub current_contract() { ## nocritic
    return $Assert::Refute::DRIVER if $Assert::Refute::DRIVER;

    # Would love to just die, but...
    if ($MORE_DETECTED) {
        require Assert::Refute::Driver::More;
        return $Assert::Refute::DRIVER = Assert::Refute::Driver::More->new;
    };

    croak "Not currently testing anything";
};

=head2 to_scalar

Convert an arbitrary value into a human-readable string.

    to_scalar( $value )
    to_scalar( $value, $depth )

If $value is undefined and $depth is not given, returns C<'(undef)'>
(so that it's harder to confuse with a literal C<'undef'>).

If $value is a scalar and $depth is not given, returns $value as is,
without quotes or anything.

Otherwise returns L<Data::Dumper> to depth $depth (or unlimited by default).

One SHOULD NOT rely on exact format of returned data.

=cut

sub to_scalar {
    my ($data, $depth) = @_;

    if (!ref $data and !defined $depth) {
        # auto-explain
        return defined $data ? $data : '(undef)';
    };

    $depth = 0 unless defined $depth;

    local $Data::Dumper::Indent    = 0;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Maxdepth  = $depth;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Useqq     = 1;
    my $str = Dumper($data);
    $str =~ s/^\$VAR1 *= *//;
    $str =~ s/;\s*$//s;
    return $str;
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
