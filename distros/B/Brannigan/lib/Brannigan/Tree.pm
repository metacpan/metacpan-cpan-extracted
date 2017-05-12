package Brannigan::Tree;

our $VERSION = "1.100001";
$VERSION = eval $VERSION;

use strict;
use warnings;
use Brannigan::Validations;

=head1 NAME

Brannigan::Tree - A Brannigan validation/parsing scheme tree, possibly built from a series of inherited schemes.

=head1 DESCRIPTION

This module is used internally by L<Brannigan>. Basically, a tree is a
validation/parsing scheme in its "final", workable structure, taking
any inherited schemes into account. The actual validation and parsing
of input is done by this module.

=head1 CONSTRUCTOR

=head2 new( $scheme | @schemes )

Creates a new Brannigan::Tree instance from one or more schemes.

=cut

sub new {
	my $class = shift;

	return bless $class->_merge_trees(@_), $class;
}

=head1 OBJECT METHODS

=head2 process( \%params )

Validates and parses the hash-ref of input parameters. Returns a hash-ref
of the parsed input, possibly containing a '_rejects' hash-ref with a list
of failed validations for each failed parameter.

=cut

sub process {
	my ($self, $params) = @_;

	my $rejects = $self->validate($params, $self->{params});
	my $data = $self->parse($params, $self->{params}, $self->{groups});

	$data->{_rejects} = $rejects
		if $rejects;

	return $data;
}

=head2 validate( \%params )

Validates the hash-ref of input parameters and returns a hash-ref of rejects
(i.e. failed validation methods) for each parameter.

=cut

sub validate {
	my ($self, $params, $rules) = @_;

	my $rejects;

	# go over all the parameters and validate them
	foreach (sort keys %$params) {
		# find references to this parameter, first in regexes, then direct
		# give preference to the direct references
		my @references;
		push(@references, $rules->{_all}) if $rules->{_all};
		foreach my $param (sort keys %$rules) {
			next unless $param =~ m!^/([^/]+)/$!;
			my $re = qr/$1/;
			push(@references, $rules->{$param}) if m/$re/;
		}
		push(@references, $rules->{$_}) if $rules->{$_};

		my $rj = $self->_validate_param($_, $params->{$_}, $self->_merge_trees(@references));

		$rejects->{$_} = $rj if $rj;
	}

	# find required parameters that aren't there
	foreach (sort keys %$rules) {
		next if $_ eq '_all';
		next if m!^/[^/]+/$!;
		$rejects->{$_} = ['required(1)'] if $rules->{$_}->{required} && (!defined $params->{$_} || $params->{$_} eq '');
	}

	return $rejects;
}

=head2 parse( \%params, \%param_rules, [\%group_rules] )

Receives a hash-ref of parameters, a hash-ref of parameter rules (this is
the 'params' part of a scheme) and optionally a hash-ref of group rules
(this is the 'groups' part of a scheme), parses the parameters according
to these rules and returns a hash-ref of all the parameters after parsing.

=cut

sub parse {
	my ($self, $params, $param_rules, $group_rules) = @_;

	my $data;

	# fill-in missing parameters with default values, if defined
	foreach (sort keys %$param_rules) {
		next if m!^/[^/]+/$!;
		next unless !defined $params->{$_} || $params->{$_} eq '';

		# is there a default value/method?
		if (exists $param_rules->{$_}->{default} && ref $param_rules->{$_}->{default} eq 'CODE') {
			$data->{$_} = $param_rules->{$_}->{default}->();
		} elsif (exists $param_rules->{$_}->{default}) {
			$data->{$_} = $param_rules->{$_}->{default};
		}
	}

	# parse the data
	foreach (sort keys %$params) {
		# ignore undefined or empty values
		next if !defined $params->{$_} || $params->{$_} eq '';
		
		# is there a reference to this parameter in the scheme?
		my @refs;
		foreach my $p (sort keys %$param_rules) {
			next unless $p =~ m!^/([^/]+)/$!;
			my $re = qr/$1/;
			next unless m/$re/;
			push(@refs, $param_rules->{$p});
		}
		push(@refs, $param_rules->{$_}) if $param_rules->{$_};
		
		next if scalar @refs == 0 && $self->{ignore_missing};
		unless (scalar @refs && $self->{ignore_missing}) {
			# pass the parameter as is
			$data->{$_} = $params->{$_};
			next;
		}

		# is this a hash-ref or an array-ref or just a scalar?
		if (ref $params->{$_} eq 'HASH') {
			my $pd = $self->parse($params->{$_}, $self->_merge_trees(@refs)->{keys});
			foreach my $k (sort keys %$pd) {
				$data->{$_}->{$k} = $pd->{$k};
			}
		} elsif (ref $params->{$_} eq 'ARRAY') {
			foreach my $val (@{$params->{$_}}) {
				# we need to parse this value with the rules
				# in the 'values' key
				my $pd = $self->parse({ param => $val }, { param => $self->_merge_trees(@refs)->{values} });
				push(@{$data->{$_}}, $pd->{param});
			}
		} else {
			# is there a parsing method?
			# first see if there's one in a regex
			my $parse;
			my @data = ($params->{$_});
			foreach my $r (sort keys %$param_rules) {
				next unless $r =~ m!^/([^/]+)/$!;
				my $re = qr/$1/;
				
				my @matches = (m/$re/);
				next unless scalar @matches > 0;
				push(@data, @matches);

				$parse = $param_rules->{$r}->{parse} if $param_rules->{$r}->{parse};
			}
			$parse = $param_rules->{$_}->{parse} if $param_rules->{$_}->{parse};

			# make sure if we have a parse method that is indeed a subroutine
			if ($parse && ref $parse eq 'CODE') {
				my $parsed = $parse->(@data);
				foreach my $k (sort keys %$parsed) {
					if (ref $parsed->{$k} eq 'HASH') {
						foreach my $sk (sort keys %{$parsed->{$k}}) {
							$data->{$k}->{$sk} = $parsed->{$k}->{$sk};
						}
					} elsif (ref $parsed->{$k} eq 'ARRAY') {
						push(@{$data->{$k}}, @{$parsed->{$k}});
					} else {
						$data->{$k} = $parsed->{$k};
					}
				}
			} else {
				# just pass as-is
				$data->{$_} = $params->{$_};
			}
		}
	}

	# parse group data
	if ($group_rules) {
		foreach (sort keys %$group_rules) {
			my @data;
			
			# do we have a list of parameters, or a regular expression?
			if (exists $group_rules->{$_}->{params}) {
				foreach my $p (@{$group_rules->{$_}->{params}}) {
					push(@data, $data->{$p});
				}
			} elsif (exists $group_rules->{$_}->{regex}) {
				my ($re) = ($group_rules->{$_}->{regex} =~ m!^/([^/]+)/$!);
				next unless $re;
				$re = qr/$re/;
				foreach my $p (sort keys %$data) {
					next unless $p =~ m/$re/;
					push(@data, $data->{$p});
				}
			} else {
				# we have nothing in this group
				next;
			}
			
			# parse the data
			my $parsed = $group_rules->{$_}->{parse}->(@data);
			foreach my $k (sort keys %$parsed) {
				if (ref $parsed->{$k} eq 'ARRAY') {
					push(@{$data->{$k}}, @{$parsed->{$k}});
				} elsif (ref $parsed->{$k} eq 'HASH') {
					foreach my $sk (sort keys %{$parsed->{$k}}) {
						$data->{$k}->{$sk} = $parsed->{$k}->{$sk};
					}
				} else {
					$data->{$k} = $parsed->{$k};
				}
			}
		}
	}

	return $data;
}

#############################
##### INTERNAL METHODS ######
#############################

# _validate_param( $param, $value, \%validations )
# ------------------------------------------------
# Receives the name of a parameter, its value, and a hash-ref of validations
# to assert against. Returns a list of validations that failed for this
# parameter. Depending on the type of the parameter (either scalar, hash
# or array), this method will call one of the following three methods.

sub _validate_param {
	my ($self, $param, $value, $validations) = @_;

	# is there any reference to this parameter in the scheme?
	return unless $validations;

	# is this parameter required? if not, and it has no value
	# (either undef or an empty string), then don't bother checking
	# any validations. If yes, and it has no value, do the same.
	return if !$validations->{required} && (!defined $value || $value eq '');
	return ['required(1)'] if $validations->{required} && (!defined $value || $value eq '');

	# is this parameter forbidden? if yes, and it has a value,
	# don't bother checking any other validations.
	return ['forbidden(1)'] if $validations->{forbidden} && defined $value && $value ne '';

	# is this a scalar, array or hash parameter?
	if ($validations->{hash}) {
		return $self->_validate_hash($param, $value, $validations);
	} elsif ($validations->{array}) {
		return $self->_validate_array($param, $value, $validations);
	} else {
		return $self->_validate_scalar($param, $value, $validations);
	}
}

# _validate_scalar( $param, $value, \%validations, [$type] )
# ----------------------------------------------------------
# Receives the name of a parameter, its value, and a hash-ref of validations
# to assert against. Returns a list of all failed validations for this
# parameter. If the parameter is a child of a hash/array parameter, then
# C<$type> must be provided with either 'hash' or 'array'.

sub _validate_scalar {
	my ($self, $param, $value, $validations, $type) = @_;

	my @rejects;

	# get all validations we need to perform
	foreach my $v (sort keys %$validations) {
		# skip the parse method and the default value
		next if $v eq 'parse' || $v eq 'default';
		next if $type && $type eq 'array' && $v eq 'values';
		next if $type && $type eq 'hash' && $v eq 'keys';

		# get the data we're passing to the validation method
		my @data = ref $validations->{$v} eq 'ARRAY' ? @{$validations->{$v}} : ($validations->{$v});
		
		# which validation method are we gonna use?
		# custom ones have preference
		if ($v eq 'validate' && ref $validations->{$v} eq 'CODE') {
			# this is an "inline" validation method, invoke it
			push(@rejects, $v) unless $validations->{$v}->($value, @data);
		} elsif (exists $self->{_custom_validations} && exists $self->{_custom_validations}->{$v} && ref $self->{_custom_validations}->{$v} eq 'CODE') {
			# this is a cross-scheme custom validation method
			push(@rejects, $v.'('.join(', ', @data).')') unless $self->{_custom_validations}->{$v}->($value, @data);
		} else {
			# we're using a built-in validation method
			push(@rejects, $v.'('.join(', ', @data).')') unless Brannigan::Validations->$v($value, @data);
		}
	}

	return scalar @rejects ? [@rejects] : undef;
}

# _validate_array( $param, $value, \%validations )
# ------------------------------------------------
# Receives the name of an array parameter, its value, and a hash-ref of validations
# to assert against. Returns a list of validations that failed for this
# parameter.

sub _validate_array {
	my ($self, $param, $value, $validations) = @_;

	# if this isn't an array, don't bother checking any other validation method
	return { _self => ['array(1)'] } unless ref $value eq 'ARRAY';

	# invoke validations on the parameter itself
	my $rejects = {};
	my $_self = $self->_validate_scalar($param, $value, $validations, 'array');
	$rejects->{_self} = $_self if $_self;

	# invoke validations on the values of the array
	my $i = 0;
	foreach (@$value) {
		my $rj = $self->_validate_param("${param}[$i]", $_, $validations->{values});
		$rejects->{$i} = $rj if $rj;
		$i++;
	}

	return scalar keys %$rejects ? $rejects : undef;
}

# _validate_hash( $param, $value, \%validations )
# -----------------------------------------------
# Receives the name of a hash parameter, its value, and a hash-ref of validations
# to assert against. Returns a list of validations that failed for this
# parameter.

sub _validate_hash {
	my ($self, $param, $value, $validations) = @_;

	# if this isn't a hash, don't bother checking any other validation method
	return { _self => ['hash(1)'] } unless ref $value eq 'HASH';

	# invoke validations on the parameter itself
	my $rejects = {};
	my $_self = $self->_validate_scalar($param, $value, $validations, 'hash');
	$rejects->{_self} = $_self if $_self;

	# invoke validations on the keys of the hash (a.k.a mini-params)
	my $hr = $self->validate($value, $validations->{keys});

	foreach (sort keys %$hr) {
		$rejects->{$_} = $hr->{$_};
	}

	return scalar keys %$rejects ? $rejects : undef;
}

# _merge_trees( @trees )
# ----------------------
# Merges two or more hash-refs of validation/parsing trees and returns the
# resulting tree. The merge is performed in order, so trees later in the
# array (i.e. on the right) "tramp" the trees on the left.

sub _merge_trees {
	my $class = shift;

	return unless scalar @_ && (ref $_[0] eq 'HASH' || ref $_[0] eq 'Brannigan::Tree');

	# the leftmost tree is the starting tree
	my $tree = shift;
	my %tree = %$tree;

	# now for the merging business
	foreach (@_) {
		next unless ref $_ eq 'HASH';

		foreach my $k (sort keys %$_) {
			if (ref $_->{$k} eq 'HASH') {
				unless (exists $tree{$k}) {
					$tree{$k} = $_->{$k};
				} else {
					$tree{$k} = $class->_merge_trees($tree{$k}, $_->{$k});
				}
			} else {
				if ($k eq 'forbidden' && $_->{$k}) {
					# remove required, if there was such a rule
					delete $tree{'required'};
				} elsif ($k eq 'required' && $_->{$k}) {
					# remove forbidden, if there was such a rule
					delete $tree{'forbidden'};
				}
				$tree{$k} = $_->{$k};
			}
		}
	}

	return \%tree;
}

=head1 SEE ALSO

L<Brannigan>, L<Brannigan::Validations>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-brannigan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Brannigan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Brannigan::Tree

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Brannigan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Brannigan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Brannigan>

=item * Search CPAN

L<http://search.cpan.org/dist/Brannigan/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ido Perlmuter

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
