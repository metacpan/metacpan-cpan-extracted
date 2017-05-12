use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

no warnings qw(redefine);

package Apache::Wyrd::Datum;
our $VERSION = '0.98';

use constant TYPE => 0;
use constant VALUE => 1;
use constant PARAMS => 2;

sub new {
	my ($class, $value, $params) = @_;
	my $data = [];
	bless $data, $class;
	$data->_init($value, $params);
	return $data;
}

sub _init {
	my ($self, $value, $params) = @_; 
	$value ||= _default_value();
	$params ||= _default_params();
	$self->_raise_exception("Params must be a hashref") if (ref($params) ne 'HASH');
	my $defaults = $self->_default_params();
	foreach my $i (keys(%$params)) {
		#force lower-case params.  Trust me, it's a good thing.
		$defaults->{lc($i)} = $params->{$i};
	}
	if (ref($defaults->{options}) eq 'HASH') {
		$defaults->{_translate_key} = $defaults->{options};
		foreach my $i (keys(%{$defaults->{options}})) {
			$defaults->{_rev_translate_key}->{$defaults->{options}->{$i}} = $i;
		}
		$defaults->{options} = [values(%{$defaults->{options}})];
	}
	$defaults = $self->_check_params($defaults);
	$self->[Apache::Wyrd::Datum::TYPE] = $self->_type;
	$self->[Apache::Wyrd::Datum::VALUE] = $value;
	$self->[Apache::Wyrd::Datum::PARAMS] = $defaults;
}

sub _type {
	die "The base Apache::Wyrd::Datum is an abstract class.  Please use a defined type instead.";
}

sub _default_value {
	return;
}

sub _default_params {
	return {'strict' => 0};
}

sub _raise_exception {
	my ($value) = @_;
	die ($value . " " . join(':', caller()));
}

sub _check_params {
	#by default, check nothing
	return $_[1];
}

sub _suggest {
	return $_[1];
}

sub _check_value {
	#by default, approve everything unless not-null is specified
	my ($self, $value, $params) = @_;
	return (0, 'Required value missing') if ($params->{'not_null'} and not($value));
	return 1;
}

sub _set {
	my($self, $value) = @_;
	$value = $self->[Apache::Wyrd::Datum::PARAMS]->{_translate_key}->{$value} if ($self->[Apache::Wyrd::Datum::PARAMS]->{translate_key});
	$self->[Apache::Wyrd::Datum::VALUE] = $value;
	return $self->[Apache::Wyrd::Datum::PARAMS]->{_rev_translate_key}->{$self->[Apache::Wyrd::Datum::VALUE]} if ($self->[Apache::Wyrd::Datum::PARAMS]->{translate_key});
	return $value;
}

sub _process_incoming {
	return $_[1];
}

sub _process_outgoing {
	return $_[1];
}

#Public Methods

sub check {
	my ($self, $value) = @_;
	my ($ok, $error) = $self->_check_value($value, $self->[Apache::Wyrd::Datum::PARAMS]);
	return 1 if ($ok);
	return (undef, $error);
}

sub get {
	my ($self) = shift;
	my $value = undef;
	$value = $self->[Apache::Wyrd::Datum::PARAMS]->{_rev_translate_key}->{$self->[Apache::Wyrd::Datum::VALUE]} if ($self->[Apache::Wyrd::Datum::PARAMS]->{translate_key});
	$value = $self->[Apache::Wyrd::Datum::VALUE];
	return $self->_process_outgoing($value);
}

sub set {
	my($self, $value) = @_;
	$value = $self->_process_incoming($value);
	my ($ok, undef) = $self->check($value);
	unless ($ok) {
		return undef if ($self->[Apache::Wyrd::Datum::PARAMS]->{'strict'});
		$value = $self->_suggest($value);
	}
	$self->_set($value);
	return 1;
}

sub type {
	my ($self) = @_;
	return $self->[Apache::Wyrd::Datum::TYPE]
}

package Apache::Wyrd::Datum::Blob;
use base qw(Apache::Wyrd::Datum);

sub _type {
	return "blob";
}

package Apache::Wyrd::Datum::Char;
use base qw(Apache::Wyrd::Datum);

sub _type {
	return "char";
}

sub _default_params {
	return {
		'strict' => 0,
		'length' => 1
	}
}

sub _check_params {
	my ($self, $params) = @_;
	die("Length was provided to " . &_type . ", but was a null value") unless ($params->{'length'});
	die(&_type . " length can be no longer than 255 chars") unless ($params->{'length'} <= 255);
	die(&_type . " length must be greater than 0") unless ($params->{'length'} > 0);
	return $params;
}

sub _check_value {
	my ($self, $value, $params) = @_;
	return (0, 'Text is too long') if ($params->{'length'} and (length($value) > $params->{'length'}));
	return (0, 'Required value missing') if ($params->{'not_null'} and not($value));
	return 1;
}

package Apache::Wyrd::Datum::Enum;
use base qw(Apache::Wyrd::Datum::Char);

sub _type {
	return "enum";
}

sub _default_params {
	return {
		'strict' => 0,
		'options' => []
	}
}

sub _check_params {
	my ($self, $params) = @_;
	die("enum without arrayref opts") unless (ref($params->{'options'}) eq 'ARRAY');
	return $params;
}

sub _check_value {
	my($self,$value,$params) = @_;
	_raise_exception("Enum value must be scalar") if (ref($value));
	unless ($params->{'not_null'}) {
		#empty value is always OK unless not-null is set
		return 1 if (not($value) and ($value ne '0'));
	}
	#Compare value to options, ok if a match
	return (0, qq("$value" is not a permitted value))
		unless (grep {lc($_) eq lc($value)} @{$params->{'options'}});
	return 1;
}

package Apache::Wyrd::Datum::Set;
use base qw(Apache::Wyrd::Datum::Enum);

sub _type {
	return "set";
}

sub _check_params {
	my ($self, $params) = @_;
	die("enum without arrayref opts") unless (ref($params->{'options'}) eq 'ARRAY');
	return $params;
}

sub _check_value {
	my($self,$value,$params) = @_;
	$self->_raise_exception("Set value must be arrayref") if (ref($value) ne 'ARRAY');
	unless ($params->{'not_null'}) {
		#empty value is always OK unless not-null is set
		return 1 if ((scalar(@$value) == 1) and (not($$value[0]) and ($$value[0] ne '0')) or not(scalar(@$value)));
	}
	#Go through all permutations, checking each against the total
	my $ok = 1;
	my $test;
	foreach my $i (@$value) {
		$test = undef;
		foreach my $j (@{$params->{'options'}}) {
			$test = 1 if (lc($j) eq lc($i));
		}
		$ok = $test;
		last if ($ok);
	}
	return $ok;
}

package Apache::Wyrd::Datum::Text;
use base qw(Apache::Wyrd::Datum);

sub _type {
	return "text";
}

sub _process_incoming {
	my ($self, $value) = @_;
	$value =~ s/\s+$//s;
	$value =~ s/^\s+//s;
	return $value;
}

package Apache::Wyrd::Datum::Varchar;
use base qw(Apache::Wyrd::Datum::Char);

sub _type {
	return "varchar";
}

sub _default_params {
	return {
		'strict' => 0,
		'length' => 255,
	}
}

package Apache::Wyrd::Datum::Integer;
use base qw(Apache::Wyrd::Datum::Char);

sub _type {
	return "integer";
}

sub _check_value {
	my($self,$value,$params) = @_;
	unless ($params->{'not_null'}) {
		return 1 unless ($value);
	}
	return (0, 'Value must be a whole number') unless ($value =~ /-?^\d+$/);
	return (0, 'Value must be a positive number') if ($value < 0 and not($params->{'signed'}));
	return (0, 'Value is too high') if ($value > ('9' x $params->{'length'}) + 0);
	return (1, undef);
}
sub _type {
	return "integer";
}

sub _default_params {
	return {
		'signed' => 0,
		'strict' => 0,
		'length' => 10,
	}
}

package Apache::Wyrd::Datum::Null;
use base qw(Apache::Wyrd::Datum);

sub _type {
	return "null";
}

sub _check_value {
	return 1;
}

sub check {
	return 1;
}

sub set {
	return 1;
}

sub force_set {
	return;
}

1;



=head1 NAME

Apache::Wyrd::Datum - Abstract data-checking objects for Wyrd Input objects

=head1 SYNOPSIS

    use Apache::Wyrd::Datum;
    my $ives = Apache::Wyrd::Datum::Set->new(
      'kits',
      {
        options => ['kits', 'cats', 'sacks', 'wives'],
        not_null => 0
      }
    );
    my ($are_ostriches_ok, $why_not) = $ives->check('ostriches')
    my $is_cats = $ives->set('cats');
    if ($is_cats) {
      print "yes, it can be cats"
    } else {
      print "no, cats are out"
    }
    my $suggest_something_then = $ives->suggest;

=head1 OBJECTS

This module defines the following objects:

=over

=item Apache::Wyrd::Datum

=item Apache::Wyrd::Datum::Char

=item Apache::Wyrd::Datum::Varchar

=item Apache::Wyrd::Datum::Text

=item Apache::Wyrd::Datum::Set

=item Apache::Wyrd::Datum::Enum

=back

=head1 DESCRIPTION

These objects are roughly tied to SQL data types and HTML inputs for
providing data objects to higher-level objects.  By abstracting the data
class, the definintion of a "valid" value can be abstracted from the SQL
or Wyrd device it will be used to check the values of.

These are used by C<Apache::Wyrd::Input>-derived classes to check
user-input.

=head1 METHODS

All Classes have the following methods:

=over

=item new

    my $data = Apache::Wyrd::Datum->new($value, \%params);

=item set

    $data->set('value') #sets data to value (if strict, will return undef and fail to set)

=item get

    my $value = $data->get('value'); #Return value (always a scalar)

=item check

    $data->check('somevalue') #returns undef on invalid data.
                              #Second returned param is an
                              #[optional] error message.

=item type

    $data->type #returns Data type: Char, Varchar, etc. in lower case

=item suggest

    $data->suggest #returns a suggested value [if implemented].


=head1 DEVELOPMENT

Derived classes of Apache::Wyrd::Datum should override:

=over

=item *

_type

=item *

_check_params

=item *

_check_value

=back

And will probably want to override:

=over

=item *

_default_value

=item *

_raise_exception

=back

=head1 PARAMS

All Datum objects are initialized with 

=item Char

params: strict, length, not-null

=item Varchar

params: strict, length, not-null

=item Text

params: strict, not-null

=item Blob

params: strict, not-null

=item Set

params: strict, not-null, options (arrayref of possible options)

=item Enum

params: strict, not-null, options (arrayref of possible options)

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
