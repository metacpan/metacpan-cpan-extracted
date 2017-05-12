package Apache::Voodoo::Validate;

$VERSION = "3.0200";

use strict;
use warnings;

use Apache::Voodoo::Exception;

sub new {
	my $class  = shift;
	my $config = shift || {};

	my $self = {};
	bless $self, $class;

	$self->{'ef'} = sub {
		my ($f,$t,$e) = @_;
		$e->{$t.'_'.$f} = 1;
	};

	$self->_configure($config);

	return $self;
}

sub set_valid_callback {
	my $self    = shift;
	#my $context = shift;
	my $sub_ref = shift;

	#unless (defined($context)) {
	#	Apache::Vodooo::Exception::RunTime->throw("add_callback requires a context name as the first parameter");
	#}

	unless (ref($sub_ref) eq "CODE") {
		Apache::Vodooo::Exception::RunTime::BadConfig->throw("add_callback requires a subroutine reference as the second paramter");
	}

	#push(@{$self->{'callbacks'}->{$context}},$sub_ref);
	$self->{'vc'} = $sub_ref;
}

sub set_error_formatter {
	my $self    = shift;
	my $sub_ref = shift;

	if (ref($sub_ref) eq "CODE") {
		$self->{'ef'} = $sub_ref;
	}
}

sub required  { return map { $_->name } grep { $_->required } @{$_[0]->{fields}} };
sub unique    { return map { $_->name } grep { $_->unique   } @{$_[0]->{fields}} };
sub multiple  { return map { $_->name } grep { $_->multiple } @{$_[0]->{fields}} };

sub fields {
	my $self = shift;
	my $type = shift;

	if ($type) {
		return grep { $_->type eq $type } @{$self->{fields}};
	}
	else {
		return @{$self->{fields}};
	}
}

sub validate {
	my $self = shift;
	my $p    = shift;

	my $values = {};
	my $errors = {};

	foreach my $field ($self->fields) {
		my $good;
		my $missing = 1;
		my $bad     = 0;
		foreach ($self->_param($p,$field)) {
			next unless defined ($_);

			# call the validation routine for each value
			my ($v,@b) = $field->valid($_);

			if (defined($b[0])) {
				# bad one, we're outta here.
				$bad = 1;
				foreach (@b) {
					$self->{'ef'}->($field->{'name'},$_,$errors);
				}
				last;
			}
			elsif (defined($field->valid_sub)) {
				# there's a validation subroutine, call it
				my $r = $field->valid_sub()->($v);

				if (defined($r) && $r == 1) {
					push(@{$good},$v);
					$missing = 0;
				}
				else {
					$bad = 1;
					if (!defined($r) || $r == 0) {
						$r = 'BAD';
					}
					$self->{'ef'}->($field->name,$r,$errors);
				}
			}
			elsif (defined($v)) {
				push(@{$good},$v);
				$missing = 0;
			}
		}

		# check requiredness
		if ($missing && $field->required) {
			$bad = 1;
			$self->{'ef'}->($field->name,'MISSING',$errors);
		}

		$self->_pack($good,$field,$values) unless ($bad);
	}

	if ($self->{vc}) {
		foreach ($self->{vc}->($values,$errors)) {
			next unless ref($_) eq "ARRAY";

			$self->{'ef'}->($_->[0],$_->[1],$errors);
			delete $values->{$_->[0]};
		}
	}

	if (scalar keys %{$errors}) {
		return ($values,$errors);
	}
	else {
		return $values;
	}
}

sub _configure {
	my $self = shift;
	my $c    = shift;

	my @errors;

	my @fields;
	if (ref($c) eq "ARRAY") {
		@fields = @{$c};
	}
	else {
		no warnings "uninitialized";
		@fields = map {
			$c->{$_}->{'id'} = $_;
			$c->{$_};
		}
		sort {
			$c->{$a}->{'seq'} ||= 0;
			$c->{$b}->{'seq'} ||= 0;

			$c->{$a}->{'seq'} cmp $c->{$b}->{'seq'} ||
			$a cmp $b;
		}
		keys %{$c};
	}

	unless (scalar(@fields)) {
		Apache::Voodoo::Exception::RunTime::BadConfig->throw("Empty Configuration.");
	}

	$self->{'fields'} = [];
	foreach my $conf (@fields) {
		my $name = $conf->{id};

		unless (defined($conf->{'type'})) {
			push(@errors,"missing 'type' for column $name");
			next;
		}

		my ($field,@e);
		eval {
			my $m = 'Apache::Voodoo::Validate::'.$conf->{'type'};
			my $f = 'Apache/Voodoo/Validate/'.$conf->{'type'}.'.pm';
			require $f;
			($field,@e) = $m->new($conf);
		};
		if ($@) {
			push(@errors,"Don't know how to handle data type $conf->{'type'}");
			next;
		}

		if (defined($e[0])) {
			push(@errors,@e);
			next;
		}

		push(@{$self->{'fields'}},$field);
	}

	if (@errors) {
		Apache::Voodoo::Exception::RunTime::BadConfig->throw("Configuration Errors:\n\t".join("\n\t",@errors));
	}
}

sub _param {
	my $self   = shift;
	my $params = shift;
	my $def    = shift;

	my $p = $params->{$def->{'name'}};
	if (ref($p) eq "ARRAY") {
		if ($def->{'multiple'}) {
			return map {
				$self->_trim($_)
			} @{$p};
		}
		else {
			return $self->_trim($p->[0]);
		}
	}
	else {
		return $self->_trim($p);
	}
}

sub _pack {
	my $self = shift;
	my $v    = shift;
	my $def  = shift;
	my $vals = shift;

	return unless defined($v);

	$vals->{$def->{'name'}} = ($def->{'multiple'})?$v:$v->[0];
}

sub _trim {
	my $self = shift;
	my $v    = shift;

	return undef unless defined($v);

	$v =~ s/^\s*//;
	$v =~ s/\s*$//;

	return (length($v))?$v:undef;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
