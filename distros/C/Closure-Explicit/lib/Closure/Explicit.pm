package Closure::Explicit;
# ABSTRACT: check coderefs for unintended lexical capture
use strict;
use warnings;
use B;
use PadWalker qw(closed_over peek_sub peek_my);
use Scalar::Util ();

our $VERSION = '0.002';

=head1 NAME

Closure::Explicit - check coderefs for variable capture

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Closure::Explicit qw(callback);

 {
   package Example;
   sub new { my $class = shift; bless {}, $class }
   sub method { my $self = shift; print "In method\n" }
 }
 my $self = Example->new;
 # This will raise an exception due to the reference to $self
 eval {
   my $code = callback {
     $self->method;
   };
 };
 # This will not raise the exception because $self is whitelisted
 my $code = callback {
   $self->method;
 } [qw($self)];
 # This will wrap the coderef so we can pass a weakened copy of $self
 my $code = callback {
   my $self = shift;
   $self->method;
 } weaken => [qw($self)];

=head1 DESCRIPTION

Attempts to provide some very basic protection against unintentional
capturing of lexicals in a closure.

For example, code such as the following risks creating cycles which
mean the top-level object is never freed:

 sub some_method {
   my $self = shift;
   $self->{callback} = sub { $self->other_method }
 }

and this can in turn lead to memory leaks.

=head1 API STABILITY

The main L</callback> function is not expected to change in future versions,
so as long as you use this:

 use Closure::Explicit qw(callback);

to import the function into your local namespace, or fully-qualify it using

 Closure::Explicit::callback { ... }

then you should have no problems with future versions of this module.

However, it is highly likely that a future version will also start exporting
a differently-named function with a better interface.

=cut

use parent qw(Exporter);
our @EXPORT_OK = qw(callback);

# This is not documented, because turning it off will break
# the weaken behaviour.
use constant CLOSURE_CHECKS => exists($ENV{PERL_CLOSURE_EXPLICIT_CHECKS}) ? $ENV{PERL_CLOSURE_EXPLICIT_CHECKS} : 1;

=head1 EXPORTS

=cut

=head2 callback

Checks the given coderef for potential closure issues, raising an exception if any
are found and returning the coderef (or a wrapped version of it) if everything is
okay.

The first parameter is the block of code to run. This is protoyped as C< & > so
you can replace the usual 'sub { ... }' with 'callback { ... }'. If you already
have a coderef, you can pass that using C< &callback($code, ...) >, but please
don't.

Remaining parameters are optional - you can either pass a single array, containing
a list of the B<names> of the variables that are safe to capture:

 callback { print "$x\n" } [qw($x)];

or a list of named parameters:

=over 4

=item * weaken => [...] - list of B<variable names> which will be copied, weakened
via L<Scalar::Util/weaken>, then prepended to the parameter list available in @_
in your code block

=item * allowed => [...] - list of B<variable names> to ignore if used in the code,
same behaviour as passing a single arrayref

=back

For example, a method call might look like this:

 my $code = callback {
   my $self = shift;
   $self->method(@_);
 } weaken => [qw($self)];

although L<curry::weak> would be a much cleaner alternative there:

 my $code = $self->curry::weak::method;

You can mix C<weaken> and C<allowed>:

 my $x = 1;
 my $code = callback {
   shift->method(++$x);
 } weaken => [qw($self)], allowed => [qw($x)];

=cut

sub callback(&;@) {
	if(CLOSURE_CHECKS) {
		my $code = shift;
		my %spec = (@_ > 1) ? (@_) : (allowed => shift);
#		warn "Have " . join ',', keys %spec;
		if(my @err = lint( $code => %spec )) {
			warn "$_\n" for @err;
			die "Had " . @err . " error(s) in closure";
		}
		return $code
	} else {
		return $_[0] unless grep $_ eq 'weaken', @_;
		my $code = shift;
		my %spec = @_;
		if($spec{weaken}) {
			my $scope = peek_my(1);
			my @extra = map ${ $scope->{$_} }, @{$spec{weaken}};
			Scalar::Util::weaken($_) for @extra;
			return sub { $code->(@extra, @_) };
		}
	}
}

=head2 lint

Runs checks on the given coderef. This is used internally and not exported,
but if you just want to get a list of potential problems for a coderef,
call this:

 my @errors = lint($code, allowed => [qw($x)]);

It's unlikely that the C<weaken> parameter will work when calling this
function directly - this may be fixed in a future version.

=cut

sub lint {
	my ($code, %spec) = @_;
	my $cv = B::svref_2object($code);
	my $details = sprintf '%s(%s:%d)', $cv->STASH->NAME, $cv->FILE, $cv->GV->LINE;

	my %closed = %{closed_over($code)};
	my %closed_by_value = map {
		ref($closed{$_}) eq 'REF'
		? (${$closed{$_}} => $_)
		: ()
	} keys %closed;

	# This is everything we declare in the sub
	my @lexicals = grep !exists $closed{$_}, keys %{ peek_sub $code };

	if($spec{weaken}) {
#		warn "weaken request: " . join ',', @{$spec{weaken}};
		my $scope = peek_my(2);
		my $real_code = $code;
		my @extra = map ${ $scope->{$_} }, @{$spec{weaken}};
		Scalar::Util::weaken($_) for @extra;
		$code = $_[0] = sub { $real_code->(@extra, @_) };
		shift;
	}

	# That's it for the data collection, now run the tests
	my @errors;
	foreach my $var (@{$spec{declares}}) {
		push @errors, "no $var declared in padlist" unless grep $_ eq $var, @lexicals;
	}
#	say " * We are capturing $_" for sort keys %closed;
	my %allowed = map { $_ => 1 } @{$spec{allowed}};
	push @errors, "$_ captured in closure, recommend checking for cycles" for sort grep !exists $allowed{$_}, keys %closed;

	foreach my $var (@{$spec{captures}}) {
		push @errors, "$var captured in closure, recommend checking for cycles" if grep $_ eq $var, keys %closed;
	}
	push @errors, "blacklisted value found in closure: $_ ($closed_by_value{$_})" for grep exists $closed_by_value{$_}, @{$spec{values}};
	return map "$details - $_", @errors;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<curry> - provides a convenient interface for creating callbacks

=item * L<PadWalker> - does most of the real work behind this module

=item * L<Test::RefCount> - convenient testing for reference counts, makes
cycles easier to detect in test code

=item * L<Devel::Cycle> - reports whether cycles exist and provides useful
diagnostics when any are found

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2012-2013. Licensed under the same terms as Perl itself.
