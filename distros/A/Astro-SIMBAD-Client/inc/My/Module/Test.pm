package My::Module::Test;

use strict;
use warnings;

use Astro::SIMBAD::Client;
use Test::More 0.96;	# Because of subtest()

use Exporter ();
our @ISA = qw{ Exporter };

use constant ARRAY_REF	=> ref [];
use constant HASH_REF	=> ref {};
use constant REGEXP_REF	=> ref qr{};

our @EXPORT_OK = qw{
    access
    call
    call_a
    canned
    clear
    count
    deref
    deref_curr
    diag
    dumper
    echo
    end
    find
    have_scheme
    hidden
    load_data
    load_module
    load_module_or_skip_all
    module_loaded
    note
    plan
    returned_value
    silent
    subtest
    test
    test_false
    $TODO
};
our @EXPORT = @EXPORT_OK;	## no critic (ProhibitAutomaticExportation)

my $canned;	# Canned data to test against.
my $got;	# Result of method call.
my %loaded;	# Record of the results of attempting to load modules.
my $obj;	# The object to be tested.
my $ref;	# Reference to result of method call, if it is a reference.
my $skip;	# True to skip tests.
my $silent;	# True to silence exceptions if $skip is true.

sub access () {	## no critic (ProhibitSubroutinePrototypes)
    eval {
	require LWP::UserAgent;
	1;
    } or plan skip_all => 'Can not load LWP::UserAgent';
    my $resp = LWP::UserAgent->new(
    )->get( Astro::SIMBAD::Client->__build_url( 'simbad/' ) );
    $resp->is_success
	or plan skip_all => "@{[$resp->status_line]}";
    return;
}

sub call (@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $method, @args ) = @_;
    $obj ||= Astro::SIMBAD::Client->new();
    eval {
	$got = $obj->$method( @args );
	1;
    } or do {
	_method_failure( $method, @args );
	$got = $@;
    };
    $ref = ref $got ? $got : undef;
    return;
}

sub call_a (@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $method, @args ) = @_;
    $obj ||= Astro::SIMBAD::Client->new();
    eval {
	$got = [ $obj->$method( @args ) ];
	1;
    } or do {
	_method_failure( $method. @args );
	$got = $@;
    };
    $ref = ref $got ? $got : undef;
    return;
}

sub canned (@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( @args ) = @_;
    my $want = $canned;
    foreach my $key (@args) {
	my $ref = ref $want;
	if ( ARRAY_REF eq $ref ) {
	    $want = $want->[$key];
	} elsif ( HASH_REF eq $ref ) {
	    $want = $want->{$key};
	} elsif ($ref) {
	    die "Loaded data contains unexpected $ref reference for key $key\n";
	} else {
	    die "Loaded data does not contain key @args\n";
	}
    }
    return $want;
}

sub clear (@) {	## no critic (ProhibitSubroutinePrototypes)
    $got = $ref = undef;	# clear
    $skip = undef;		# noskip
    $silent = undef;		# Not silent.
    return;
}

sub count () {	## no critic (ProhibitSubroutinePrototypes)
    if ( ARRAY_REF eq ref $got ) {
	$got = @{ $got };
    } else {
	$got = undef;
    };
    return;
}

sub deref (@) {	## no critic (ProhibitSubroutinePrototypes)
    $got = $ref;
    goto &deref_curr;
}

sub deref_curr (@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( @args ) = @_;
    foreach my $key (@args) {
	my $type = ref $got;
	if ( ARRAY_REF eq $type ) {
	    $got = $got->[$key];
	} elsif ($type eq HASH_REF) {
	    $got = $got->{$key};
	} else {
	    $got = undef;
	}
    }
    return;
}

sub dumper () {	## no critic (ProhibitSubroutinePrototypes)
	require Data::Dumper;
	diag Data::Dumper::Dumper( $got );
    return;
}

sub echo (@) {	## no critic (ProhibitSubroutinePrototypes)
    my @args = @_;
    foreach ( @args ) {
	note $_;
    }
    return;
}

sub end () {	## no critic (ProhibitSubroutinePrototypes)
    done_testing;
    return;
}

sub find (@) {	## no critic (ProhibitSubroutinePrototypes)
    my ( @args ) = @_;
    my $target = pop @args;
    if ( ARRAY_REF eq ref $got ) {
	foreach my $item ( @{ $got } ) {
	    my $test = $item;
	    foreach my $key ( @args ) {
		my $type = ref $test;
		if ( ARRAY_REF eq $type ) {
		    $test = $test->[$key];
		} elsif ( HASH_REF eq $type ) {
		    $test = $test->{$key};
		} else {
		    $test = undef;
		} 
	    }
	    (defined $test && $test eq $target)
	       and do {$got = $item; last;};
	}
    }
    return;
}

sub have_scheme ($) {
    my ( $protocol ) = @_;
    local $@ = undef;
    return eval {
	require "LWP/Protocol/$protocol.pm";
	1;
    };
}

sub hidden ($) {
    my ( $module ) = @_;
    my $code = Test::Without::Module->can( 'get_forbidden_list' )
	or return 0;
    return exists $code->()->{$module} || 0;
}

sub load_data ($) {	## no critic (ProhibitSubroutinePrototypes)
    my ( $arg ) = @_;
    if ( defined $arg ) {
	local @INC = ( @INC, '.' );
	$canned = do $arg;
    } else {
	$canned = undef;
    }
    return;
}

sub load_module (@) {	## no critic (ProhibitSubroutinePrototypes)
    my @args = @_;
    my $prob = @args > 1 ?
	("Can not load any of " . join (', ', @args)) :
	@args ? "Can not load @args" : '';
    foreach ( @args ) {
	if ( exists $loaded{$_} ) {
	    $loaded{$_} and do {
		$prob = undef;
		last;
	    };
	} else {
	    $loaded{$_} = undef;
	    eval "require $_; 1" and do {
		$prob = undef;
		$loaded{$_} = 1;
		last;
	    };
	}
    }
    defined $prob
	and not $skip
	and $skip = $prob;
    return;
}

sub load_module_or_skip_all (@) {
    my @args = @_;
    load_module( @args );
    $skip
	and plan skip_all => $skip;
    return;
}

sub module_loaded (@) {		## no critic (ProhibitSubroutinePrototypes,RequireArgUnpacking)
    my ( @args ) = @_;
    $loaded{shift @args} or return;
    my $verb = shift @args;
    my $code = __PACKAGE__->can( $verb )
	or die "Unknown command $verb";
    @_ = @args;
    goto &$code;
}

sub returned_value () { ## no critic (ProhibitSubroutinePrototypes,RequireArgUnpacking)
    return $got;
}

sub silent (;$) { ## no critic (ProhibitSubroutinePrototypes)
    my ( $arg ) = @_;
    defined $arg
	or $arg = ! $silent;
    $silent = $arg;
    return;
}

sub test ($$) {		## no critic (ProhibitSubroutinePrototypes,RequireArgUnpacking)
    $_[2] = 1;
    goto &_test;
}

sub test_false ($$) {	## no critic (ProhibitSubroutinePrototypes,RequireArgUnpacking)
    $_[2] = 0;
    goto &_test;
}


sub _test {		## no critic (RequireArgUnpacking)
    my ( $want, $title, $type ) = @_;
    $got = 'undef' unless defined $got;
    foreach ($want, $got) {
	ref $_ and next;
	chomp $_;
	m/(.+?)\s+$/ and _numberp ($1 . '') and $_ = $1;
    }
    if ( $skip ) {
	SKIP: {
	    skip $skip, 1;
	}
    } elsif ( REGEXP_REF eq ref $want ) {
	@_ = ( $got, $want, $title );
	goto $type ? \&like : \&unlike;
    } elsif (_numberp ($want) && _numberp ($got)) {
	@_ = ( $got, ( $type ? '==' : '!=' ), $want, $title );
	goto &cmp_ok;
    } else {
	@_ = ( $got, $want, $title );
	goto $type ? \&is : \&isnt;
    }
    return;
}

##################################################################

sub _method_failure {
    my ( $method, @args ) = @_;
    $skip
	and $silent
	and return;
    my $msg = $skip ? ' ($skip set)' : '';
    @args = map { _quote() } @args;
    local $" = ', ';
    diag "$method( @args ) failed$msg: $@";
    return;
}

sub _numberp {
    return ($_[0] =~ m/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
}

sub _quote {
    defined $_
	or return 'undef';
    _numberp( $_ )
	and return $_;
    s/ ( ['\\] ) /\\$1/smx;
    return "'$_'";
}

1;

__END__

=head1 NAME

My::Module::Test - Provide test harness for Astro::SIMBAD::Client

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test;
 
 access;	# Check access to SIMBAD web site.

 # Tests here

 end;		# All testing complete

=head1 DETAILS

This module provides some subroutines to help test the
L<Astro::SIMBAD::Client|Astro::SIMBAD::Client> package. All the
documented subroutines are prototyped, and are exported by default.

A test would typically consist of:

* A call to C<call()>, to execute a method;

* A call to C<deref()>, to select from the output structure the value to
be tested;

* A call to C<test()>, to provide the standard value and the test name,
and actually perform the test.

Since many tests use the same data, the C<load_data()> subroutine can be
called to import a data structure (stored as a
L<Data::Dumper|Data::Dumper> hash), and the C<canned()> subroutine can
be used to select the standard value from the hash.

The subroutines exported are:

=head2 access

This subroutine must be called, if at all, before the first test. It
checks access to the SIMBAD web site. If the web site is accessable, it
simply returns. If not, it calls C<plan skip_all>.

=head2 call

This subroutine calls an C<Astro::SIMBAD::Client|Astro::SIMBAD::Client>
method, instantiating the object if needed. The results of the call are
not returned, but are made available for testing.

=head2 call_a

This subroutine is similar to C<call>, but the method call is made
inside an array constructor.

=head2 canned

This subroutine returns the content of the canned data hash loaded by
the most recent call to C<load_data()>. The arguments are the hash keys
and array indices needed to navigate to the desired datum. If the
desired datum is not found, an exception is thrown.

=head2 clear

This subroutine prepares for another round of testing by clearing the
skip indicator and any results.

=head2 count

This subroutine counts the number of elements in the array reference
returned by the most recent C<call()>, and makes that available for
testing. If the most recent C<call()> did not return an array reference,
the tested value is C<undef>.

=head2 deref

This subroutine returns the selected datum from the result of the most
recent C<call()>, and makes it available for testing. The arguments are
the hash keys and array indices needed to navigate to the desired datum.
If the desired datum is not found, C<undef> is used for testing.

=head2 deref_curr

This subroutine is like C<deref()>, but the navigation is applied to the
current value to be tested.

=head2 dumper

This subroutine loads L<Data::Dumper|Data::Dumper> and dumps the current
content of the value to be tested.

=head2 echo

This subroutine simply displays its arguments. It is implemented via the
L<Test::More|Test::More> diag() method.

=head2 end

This subroutine B<must> be called after testing is complete, to let the
test harness know that testing B<is> complete.

=head2 find

This subroutine finds a given value in the structure which is available
for testing. The value to look for is the last argument; the other
argumments are navigation information, such as would be passed to
C<deref()>.

If structure available for testing is not an array reference, C<undef>
is made available for testing. Otherwise, the subroutine iterates over
the elements in the array, performing the navigation on each in turn,
and testing whether the desired value is found. If it is, the array
element in which it is found becomes the value available for testing.
Otherwise C<undef> becomes available for testing.

=head2 hidden

This subroutine returns true if its argument is the name of a module
hidden by L<Test::Without::Module|Test::Without::Module>. Otherwise it
returns false.

=head2 load_data

This subroutine takes as its argument a file containing data to be
provided via the C<canned()> subroutine. The contents of the file will
be string C<eval>-ed.

=head2 load_module

This subroutine takes as arguments a number of Perl module names. It
attempts to C<require> these in order, stopping when the first
C<require> succeeds. If none succeeds, the internal skip indicator is
set, so that subsequent tests are skipped until C<clear()> is called.

Load status is cached, so only one C<eval> is done per module.

=head2 module_loaded

This subroutine takes as its first argument the name of a module. The
second argument is the name of one of the C<My::Module::Test>
subroutines, and subsequent arguments are arguments for the named
subroutine. If the named module has not been loaded, nothing happens. If
the named module has been loaded, the named subroutine is called (as a
co-routine), with the given arguments.

=head2 returned_value

This subroutine dumps the value returned by the last call as a scalar.
It is intended for diagnostics only.

=head2 silent

This subroutine causes exception diagnostics displayed by C<call()> and
C<call_a()> to be silenced if skipping is in effect. The argument is
interpreted as a Perl boolean, and defaults to the negation of the
current setting. If skipping is not in effect, diagnostics will be
issued regardless of whether C<silence 1> is in effect.

This is cleared by C<clear>.

=head2 test

This subroutine performs the actual test. It takes two arguments: the
expected value, and the name of the test. The value made available by
C<call()>, C<count()>, C<deref()>, C<deref_curr()>, or C<find()> is
compared to the expected value, and the test succeeds or fails based on
the result of the comparison.

If the expected value is a C<Regexp> object, the comparison is done with
the C<Test::More> C<like()> subroutine. If it looks like a number, the
comparison is done with C<cmp_ok> for numeric equality. Otherwise, the
comparison is done with C<is>.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
