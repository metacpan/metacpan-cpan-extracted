package CSS::Struct::Output;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use List::MoreUtils qw(none);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Get default parameters.
	$self->_default_parameters;

	# Process params.
	set_params($self, @params);

	# Check parameters to right values.
	$self->_check_params;

	# Reset.
	$self->reset;

	# Object.
	return $self;
}

# Flush CSS structure in object.
sub flush {
	my ($self, $reset_flag) = @_;
	my $ouf = $self->{'output_handler'};
	my $ret;
	if (ref $self->{'flush_code'} eq 'ARRAY') {
		$ret = join $self->{'output_sep'}, @{$self->{'flush_code'}};
	} else {
		$ret = $self->{'flush_code'};
	}
	if ($ouf) {
		no warnings;
		print {$ouf} $ret or err 'Cannot write to output handler.';
		undef $ret;
	}

	# Reset.
	if ($reset_flag) {
		$self->reset;
	}

	# Return string.
	return $ret;
}

# Put CSS structure code.
sub put {
	my ($self, @data) = @_;

	# For every data.
	foreach my $css_structure_ar (@data) {

		# Bad data.
		if (ref $css_structure_ar ne 'ARRAY') {
			err 'Bad data.';
		}

		# Split to type and main CSS structure.
		my ($type, @css_struct) = @{$css_structure_ar};

		# Attributes.
		if ($type eq 'a') {
			$self->_check_arguments(\@css_struct, 1, 2);
			$self->_put_at_rules(@css_struct);

		# Comment.
		} elsif ($type eq 'c') {
			$self->_put_comment(@css_struct);

		# Definition.
		} elsif ($type eq 'd') {
			$self->_check_arguments(\@css_struct, 1, 2);
			$self->_put_definition(@css_struct);

		# End of selector.
		} elsif ($type eq 'e') {
			$self->_check_arguments(\@css_struct, 0, 0);
			$self->_put_end_of_selector;

		# Instruction.
		} elsif ($type eq 'i') {
			$self->_check_arguments(\@css_struct, 1, 2);
			$self->_put_instruction(@css_struct);

		# Raw data.
		} elsif ($type eq 'r') {
			$self->_put_raw(@css_struct);

		# Selector.
		} elsif ($type eq 's') {
			$self->_check_arguments(\@css_struct, 1, 1);
			$self->_put_selector(@css_struct);

		# Other.
		} else {
			if (! $self->{'skip_bad_types'}) {
				err 'Bad type of data.', 'type', $type;
			}
		}
	}

	# Auto-flush.
	if ($self->{'auto_flush'}) {
		$self->flush;
		$self->_reset_flush_code;
	}

	return;
}


# Resets internal variables.
sub reset {
	my $self = shift;

	# Tmp code.
	$self->{'tmp_code'} = [];

	# Flush code.
	$self->_reset_flush_code;

	# Open selector flag.
	$self->{'open_selector'} = 0;

	return;
}

# Check arguments.
sub _check_arguments {
	my ($self, $css_structure_ar, $min_arg_num, $max_arg_num) = @_;
	my $arg_num = scalar @{$css_structure_ar};
	if ($arg_num < $min_arg_num || $arg_num > $max_arg_num) {
		err 'Bad number of arguments.',
			'\'CSS::Struct\' structure',
			join ', ', @{$css_structure_ar};
	}
	return;
}

# Check to opened selector.
sub _check_opened_selector {
	my $self = shift;
	if (! $self->{'open_selector'}) {
		err 'No opened selector.';
	}
	return;
}

# Default parameters.
sub _default_parameters {
	my $self = shift;

	# Auto flush flag.
	$self->{'auto_flush'} = 0;

	# CSS comment delimeters.
	$self->{'comment_delimeters'} = [q{/*}, q{*/}];

	# Set output handler.
	$self->{'output_handler'} = undef;

	# Output separator.
	$self->{'output_sep'} = "\n";

	# Skip bad 'CSS::Struct' types.
	$self->{'skip_bad_types'} = 0;

	# Skip comments.
	$self->{'skip_comments'} = 0;

	return;
}

# Check parameters to rigth values.
sub _check_params {
	my $self = shift;

	# Check to output handler.
	if (defined $self->{'output_handler'}
		&& ref $self->{'output_handler'} ne 'GLOB') {

		err 'Output handler is bad file handler.';
	}
	# Check auto-flush only with output handler.
	if ($self->{'auto_flush'} && ! defined $self->{'output_handler'}) {
		err 'Auto-flush can\'t use without output handler.';
	}

	# Check to comment delimeters.
	if (ref $self->{'comment_delimeters'} ne 'ARRAY'
		|| (none { $_ eq $self->{'comment_delimeters'}->[0] }
		(q{/*}, '<!--'))
		|| (none { $_ eq $self->{'comment_delimeters'}->[1] }
		(q{*/}, '-->'))) {

		err 'Bad comment delimeters.';
	}

	return;
}

# At-rules.
sub _put_at_rules {
	my ($self, $at_rule, $file) = @_;
	push @{$self->{'flush_code'}}, 'At-rule';
	return;
}

# Comment.
sub _put_comment {
	my ($self, @comments) = @_;
	push @{$self->{'flush_code'}}, 'Comment';
	return;
}

# Definition.
sub _put_definition {
	my ($self, $key, $value) = @_;
	push @{$self->{'flush_code'}}, 'Definition';
	return;
}

# End of selector.
sub _put_end_of_selector {
	my $self = shift;
	push @{$self->{'flush_code'}}, 'End of selector';
	return;
}

# Instruction.
sub _put_instruction {
	my ($self, $target, $code) = @_;
	push @{$self->{'flush_code'}}, 'Instruction';
	return;
}

# Raw data.
sub _put_raw {
	my ($self, @raw_data) = @_;
	push @{$self->{'flush_code'}}, 'Raw data';
	return;
}

# Selectors.
sub _put_selector {
	my ($self, $selector) = @_;
	push @{$self->{'flush_code'}}, 'Selector';
	return;
}

# Reset flush code.
sub _reset_flush_code {
	my $self = shift;
	$self->{'flush_code'} = [];
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CSS::Struct::Output - Base class for CSS::Struct::Output::*.

=head1 SYNOPSIS

 use CSS::Struct::Output;

 my $css = CSS::Struct::Output->new(%parameters);
 my $ret_or_undef = $css->flush($reset_flag);
 $css->put(@data);
 $css->reset;

=head1 METHODS

=head2 C<new>

 my $css = CSS::Struct::Output->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<auto_flush>

 Auto flush flag.
 Default is 0.

=item * C<comment_delimeters>

 Reference to array with begin and end comment delimeter.
 Default value is ['/*', '*/'].
 Possible values are:
 - ['/*', '*/']
 - ['<!--', '-->'],

=item * C<output_handler>

 Handler for print output strings.
 Must be a GLOB.
 Default value is undef.

=item * C<output_sep>

 Output separator.
 Default value is newline.

=item * C<skip_bad_types>

 Flag, that means bad 'CSS::Struct' types skipping.
 Default value is 0.

=item * C<skip_comments>

 Flag, that means comment skipping.
 Default value is 0.

=back

=head2 C<flush>

 my $ret_or_undef = $css->flush($reset_flag);

Flush CSS structure in object.
If defined 'output_handler' flush to its.
Or return CSS.
If enabled $reset_flag, then resets internal variables via reset method.

Returns CSS string or undef.

=head2 C<put>

 $css->put(@data);

Put CSS structure in format specified in L<CSS::Struct>.

Returns undef.

=head2 C<reset>

 $css->reset;

Resets internal variables.

Returns undef.

=head1 ERRORS

 Mine:
         Auto-flush can't use without output handler.
         Bad comment delimeters.
         Bad data.
         Bad number of arguments.
                 ('CSS::Struct' structure array),
         Bad type of data.
         Cannot write to output handler.
         No opened selector.
         Output handler is bad file handler.

 From Class::Utils::set_params():
         Unknown parameter '%s'.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<List::MoreUtils>.

=head1 SEE ALSO

=over

=item L<CSS::Struct>

Struct oriented CSS manipulation.

=item L<CSS::Struct::Output::Raw>

Raw printing 'CSS::Struct' structure to CSS code.

=item L<CSS::Struct::Output::Indent>

Indent printing 'CSS::Struct' structure to CSS code.

=back

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2007-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
