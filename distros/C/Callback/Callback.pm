
package Callback;

require Exporter;
require UNIVERSAL;

$VERSION = $VERSION = 1.07;
@ISA = (Exporter);
@EXPORT_OK = qw(@callbackTrace);

use strict;

sub new
{
	my ($package,$func,@args) = @_;
	my ($p, $file, $line) = caller(0);
	my @method;
	if (ref $func ne 'CODE' && UNIVERSAL::isa($func, "UNIVERSAL")) {
		if ($func->isa('Callback')) {
			return $func unless @args;
			my $new = bless { %$func }, $package;
			push(@{$new->{ARGS}}, @args);
			return $new;
		} else {
			my $method = shift @args;
			my $obj = $func;
			$func = $obj->can($method);
			unless (defined $func) {
				require Carp;
				Carp::croak("Can't locate method '$method' for object $obj");
			}
			unshift(@args, $obj);
			@method = (METHOD => $method);	# For Storable hooks
		}
	}
	my $x = {
		FUNC   => $func,
		ARGS   => [@args],
		CALLER => "$file:$line",
		@method
	};
	return bless $x, $package;
}

sub call
{
	my ($this, @args) = @_;
	my ($ret, @ret);

	unshift(@Callback::callbackTrace, $this->{CALLER});
	if (wantarray) {
		@ret = eval {&{$this->{FUNC}}(@{$this->{ARGS}},@args)};
	} else {
		$ret = eval {&{$this->{FUNC}}(@{$this->{ARGS}},@args)};
	}
	shift(@Callback::callbackTrace);
	die $@ if $@;
	return @ret if wantarray;
	return $ret;
}

sub DELETE
{
}

#
# Storable hooks
#
# We cannot serialize something containing a pure CODE ref, which is the
# case if there's no METHOD attribute in the object.
#
# However, when Callback is a method call, we can remove the FUNC attribute
# and serialize the object: the function address will be recomputed at
# retrieve time.
#

sub STORABLE_freeze {
	my ($self, $cloning) = @_;
	return if $cloning;

	my %copy = %$self;
	die "cannot store $self since it contains CODE references\n"
		unless exists $copy{METHOD};

	delete $copy{FUNC};
	return ("", \%copy);
}

sub STORABLE_thaw {
	my ($self, $cloning, $x, $copy) = @_;

	%$self = %$copy;

	my $method = $self->{METHOD};
	my $obj = $self->{ARGS}->[0];
	my $func = $obj->can($method);
	die("cannot restore $self: can't locate method '$method' on object $obj")
		unless defined $func;

	$self->{FUNC} = $func;
	return;
}

1;

