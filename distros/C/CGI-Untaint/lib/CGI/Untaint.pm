package CGI::Untaint;

$VERSION = '1.26';

=head1 NAME 

CGI::Untaint - process CGI input parameters

=head1 SYNOPSIS

  use CGI::Untaint;

  my $q = new CGI;
  my $handler = CGI::Untaint->new( $q->Vars );
  my $handler2 = CGI::Untaint->new({
  	INCLUDE_PATH => 'My::Untaint',
  }, $apr->parms);

  my $name     = $handler->extract(-as_printable => 'name');
  my $homepage = $handler->extract(-as_url => 'homepage');

  my $postcode = $handler->extract(-as_postcode => 'address6');

  # Create your own handler...

  package MyRecipes::CGI::Untaint::legal_age;
  use base 'CGI::Untaint::integer';
  sub is_valid { 
    shift->value > 21;
  }

  package main;
  my $age = $handler->extract(-as_legal_age => 'age');

=head1 DESCRIPTION

Dealing with large web based applications with multiple forms is a
minefield. It's often hard enough to ensure you validate all your
input at all, without having to worry about doing it in a consistent
manner. If any of the validation rules change, you often have to alter
them in many different places. And, if you want to operate taint-safe,
then you're just adding even more headaches.

This module provides a simple, convenient, abstracted and extensible
manner for validating and untainting the input from web forms.

You simply create a handler with a hash of your parameters (usually
$q->Vars), and then iterate over the fields you wish to extract,
performing whatever validations you choose. The resulting variable is
guaranteed not only to be valid, but also untainted.

=cut

use strict;
use Carp;
use UNIVERSAL::require;

=head1 CONSTRUCTOR

=head2 new

  my $handler  = CGI::Untaint->new( $q->Vars );
  my $handler2 = CGI::Untaint->new({
  	INCLUDE_PATH => 'My::Untaint',
  }, $apr->parms);

The simplest way to contruct an input handler is to pass a hash of
parameters (usually $q->Vars) to new(). Each parameter will then be able
to be extracted later by calling an extract() method on it.

However, you may also pass a leading reference to a hash of configuration
variables.

Currently the only such variable supported is 'INCLUDE_PATH', which
allows you to specify a local path in which to find extraction handlers.
See L<LOCAL EXTRACTION HANDLERS>.

=cut

sub new {
	my $class = shift;

	# want to cope with any of:
	#  (%vals), (\%vals), (\%config, %vals) or (\%config, \%vals)
	#    but %vals could also be an object ...
	my ($vals, $config);

	if (@_ == 1) {

		# only one argument - must be either hashref or obj.
		$vals = ref $_[0] eq "HASH" ? shift: { %{ +shift } }

	} elsif (@_ > 2) {

		# Conf + Hash or Hash
		$config = shift if ref $_[0] eq "HASH";
		$vals   = {@_}

	} else {

		# Conf + Hashref or 1 key hash
		ref $_[0] eq "HASH" ? ($config, $vals) = @_ : $vals = {@_};
	}

	bless {
		__config => $config,
		__data   => $vals,
	} => $class;

}

=head1 METHODS

=head2 extract

  my $homepage = $handler->extract(-as_url => 'homepage');
  my $state = $handler->extract(-as_us_state => 'address4');
  my $state = $handler->extract(-as_like_us_state => 'address4');

Once you have constructed your Input Handler, you call the 'extract'
method on each piece of data with which you are concerned.

The takes an -as_whatever flag to state what type of data you
require. This will check that the input value correctly matches the
required specification, and return an untainted value. It will then call
the is_valid() method, where applicable, to ensure that this doesn't
just _look_ like a valid value, but actually is one.

If you want to skip this stage, then you can call -as_like_whatever
which will perform the untainting but not the validation.

=cut

sub extract {
	my $self = shift;
	$self->{_ERR} = "";
	my $val = eval { $self->_do_extract(@_) };
	if ($@) {
		chomp($self->{_ERR} = $@);
		return;
	}
	return $val;
}

sub _do_extract {
	my $self = shift;

	my %param = @_;

	#----------------------------------------------------------------------
	# Make sure we have a valid data handler
	#----------------------------------------------------------------------
	my @as = grep /^-as_/, keys %param;
	croak "No data handler type specified"        unless @as;
	croak "Multiple data handler types specified" unless @as == 1;

	my $field      = delete $param{ $as[0] };
	my $skip_valid = $as[0] =~ s/^(-as_)like_/$1/;
	my $module     = $self->_load_module($as[0]);

	#----------------------------------------------------------------------
	# Do we have a sensible value? Check the default untaint for this
	# type of variable, unless one is passed.
	#----------------------------------------------------------------------
	defined(my $raw = $self->{__data}->{$field})
		or die "No parameter for '$field'\n";

	# 'False' values get returned as themselves with no warnings.
	# return $self->{__lastval} unless $self->{__lastval};

	my $handler = $module->_new($self, $raw);

	my $clean = eval { $handler->_untaint };
	if ($@) {    # Give sensible death message
		die "$field ($raw) does not untaint with default pattern\n"
			if $@ =~ /^Died at/;
		die $@;
	}

	#----------------------------------------------------------------------
	# Are we doing a validation check?
	#----------------------------------------------------------------------
	unless ($skip_valid) {
		if (my $ref = $handler->can('is_valid')) {
			die "$field ($raw) does not pass the is_valid() check\n"
				unless $handler->$ref();
		}
	}

	return $handler->untainted;
}

=head2 error

  my $error = $handler->error;

If the validation failed, this will return the reason why.

=cut

sub error { $_[0]->{_ERR} }

sub _load_module {
	my $self = shift;
	my $name = $self->_get_module_name(shift());

	foreach
		my $prefix (grep defined, "CGI::Untaint", $self->{__config}{INCLUDE_PATH})
	{
		my $mod = "$prefix\::$name";
		return $self->{__loaded}{$mod} if defined $self->{__loaded}{$mod};
		eval {
			$mod->require;
			$mod->can('_untaint') or die;
		};
		return $self->{__loaded}{$mod} = $mod unless $@;
	}
	die "Can't find extraction handler for $name\n";
}

# Convert the -as_whatever to a FQ module name
sub _get_module_name {
	my $self = shift;
	(my $handler = shift) =~ s/^-as_//;
	return $handler;
}

=head1 LOCAL EXTRACTION HANDLERS

As well as as the handlers supplied with this module for extracting
data, you may also create your own. In general these should inherit from
'CGI::Untaint::object', and must provide an '_untaint_re' method which
returns a compiled regular expression, suitably bracketed such that $1
will return the untainted value required.

e.g. if you often extract single digit variables, you could create 

  package My::Untaint::digit;

  use base 'CGI::Untaint::object';

  sub _untaint_re { qr/^(\d)$/ }

  1;

You should specify the path 'My::Untaint' in the INCLUDE_PATH
configuration option.  (See new() above.)

When extract() is called CGI::Untaint will also check to see if you have
an is_valid() method also, and if so will run this against the value
extracted from the regular expression (available as $self->value).

If this returns a true value, then the extracted value will be returned,
otherwise we return undef. 

is_valid() can also modify the value being returned, by assigning 
  $self->value($new_value)

e.g. in the above example, if you sometimes need to ensure that the
digit extracted is prime, you would supply:

  sub is_valid { (1 x shift->value) !~ /^1?$|^(11+?)\1+$/ };

Now, when users call extract(), it will also check that the value
is valid(), i.e. prime:

  my $number = $handler->extract(-as_digit => 'value');

A user wishing to skip the validation, but still ensure untainting can
call 

  my $number = $handler->extract(-as_like_digit => 'value');

=head2 Test::CGI::Untaint

If you create your own local handlers, then you may wish to explore
L<Test::CGI::Untaint>, available from the CPAN. This makes it very easy
to write tests for your handler. (Thanks to Profero Ltd.)

=head1 AVAILABLE HANDLERS

This package comes with the following simplistic handlers: 

  printable  - a printable string
  integer    - an integer
  hex        - a hexadecimal number (as a string)

To really make this work for you you either need to write, or download
from CPAN, other handlers. Some of the handlers available on CPAN include:

  asin         - an Amazon ID
  boolean      - boolean value
  country      - a country code or name
  creditcard   - a credit card number
  date         - a date (into a Date::Simple)
  datetime     - a date (into a DateTime)
  email        - an email address
  hostname     - a DNS host name
  html         - sanitized HTML
  ipaddress    - an IP address
  isbn         - an ISBN
  uk_postcode  - a UK Postcode
  url          - a URL
  zipcode      - a US zipcode

=head1 BUGS

None known yet.

=head1 SEE ALSO

L<CGI>. L<perlsec>. L<Test::CGI::Untaint>.

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-CGI-Untaint@rt.cpan.org

=head1 COPYRIGHT and LICENSE

Copyright (C) 2001-2005 Tony Bowden. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
