package CSS::Struct::Output::Structure;

use base qw(CSS::Struct::Output);
use strict;
use warnings;

use Error::Pure qw(err);

our $VERSION = 0.02;

sub flush {
	my ($self, $reset_flag) = @_;

	my $ouf = $self->{'output_handler'};

	# Text output.
	my $ret_ar;
	if ($ouf) {
		foreach my $line_ar (@{$self->{'flush_code'}}) {
			my $line = "['";
			$line .= join "', '", @{$line_ar};
			$line .= "']".$self->{'output_sep'};
			no warnings;
			print {$ouf} $line
				or err 'Cannot write to output handler.';
		}

	# Structure.
	} else {
		$ret_ar = $self->{'flush_code'};
	}

	# Reset.
	if ($reset_flag) {
		$self->reset;
	}

	return $ret_ar;
}

# At-rules.
sub _put_at_rules {
	my ($self, $at_rule, $value) = @_;

	$self->_put_structure('a', $at_rule, $value);

	return;
}

# Comment.
sub _put_comment {
	my ($self, @comments) = @_;

	$self->_put_structure('c', @comments);

	return;
}

# Definition.
sub _put_definition {
	my ($self, $key, $value) = @_;

	$self->_put_structure('d', $key, $value);

	return;
}

# End of selector.
sub _put_end_of_selector {
	my $self = shift;

	$self->_put_structure('e');

	return;
}

# Instruction.
sub _put_instruction {
	my ($self, $target, $code) = @_;

	$self->_put_structure('i', $target, $code);

	return;
}

# Raw data.
sub _put_raw {
	my ($self, @raw_data) = @_;

	$self->_put_structure('r', @raw_data);

	return;
}

# Selectors.
sub _put_selector {
	my ($self, $selector) = @_;

	$self->_put_structure('s', $selector);

	return;
}

# Put common structure.
sub _put_structure {
	my ($self, @struct) = @_;

	push @{$self->{'flush_code'}}, \@struct;

	return;
}

# Reset flush code.
sub _reset_flush_code {
	my $self = shift;

	$self->{'flush_code'} = undef;

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CSS::Struct::Output::Structure - Structure class for 'CSS::Struct' output.

=head1 SYNOPSIS

 use CSS::Struct::Output::Structure;

 my $css = CSS::Struct::Output::Structure->new(%parameters);
 my $ret_or_undef = $css->flush($reset_flag);
 $css->put(@data);
 $css->reset;

=head1 METHODS

=head2 C<new>

 my $css = CSS::Struct::Output::Structure->new(%parameters);

Constructor.

Returns instance of object.

=over 8

=item * C<auto_flush>

 Auto flush flag.
 Default is 0.

=item * C<output_handler>

 Handler for print output strings.
 Must be a GLOB.
 Default is undef.

=item * C<skip_bad_types>

 Flag, that means bad 'CSS::Struct' types skipping.
 Default value is 0.

=back

=head2 C<flush>

 my $ret_or_undef = $css->flush($reset_flag);

Flush CSS structure in object.
If defined 'output_handler' flush to its as structure string.
Or return CSS structure as array.
If enabled $reset_flag, then resets internal variables via reset method.

Returns output string or undef.

=head2 C<put(@data)>

 $css->put(@data);

Put CSS structure in format specified in L<CSS::Struct>.

Returns undef.

=head2 C<reset>

 $css->reset;

Resets internal variables.

Returns undef.

=head1 ERRORS

 From CSS::Struct::Output:
         Auto-flush can't use without output handler.
         Bad comment delimeters.
         Bad data.
         Bad number of arguments.
                 ('CSS::Struct' structure array),
         Bad type of data.
         Cannot write to output handler.
         No opened selector.
         Output handler is bad file handler.
         Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use CSS::Struct::Output::Structure;
 use Data::Printer;

 my $css = CSS::Struct::Output::Structure->new;

 # Set structure.
 $css->put(['c', 'Comment']);
 $css->put(['a', '@charset', 'utf-8']);
 $css->put(['s', 'selector#id']);
 $css->put(['s', 'div div']);
 $css->put(['s', '.class']);
 $css->put(['d', 'weight', '100px']);
 $css->put(['d', 'font-size', '10em']);
 $css->put(['e']);

 # Get structure.
 my $css_struct_ar = $css->flush;

 # Dump out.
 p $css_struct_ar;

 # Output:
 # \ [
 #     [0] [
 #         [0], "c",
 #         [1], "comment"
 #     ],
 #     [1] [
 #         [0] "a",
 #         [1] "@charset",
 #         [2] "utf-8"
 #     ],
 #     [2] [
 #         [0] "s",
 #         [1] "selector#id"
 #     ],
 #     [3] [
 #         [0] "s",
 #         [1] "div div"
 #     ],
 #     [4] [
 #         [0] "s",
 #         [1] ".class"
 #     ],
 #     [5] [
 #         [0] "d",
 #         [1] "weight",
 #         [2] "100px"
 #     ],
 #     [6] [
 #         [0] "d",
 #         [1] "font-size",
 #         [2] "10em"
 #     ],
 #     [7] [
 #         [0] "e"
 #     ]
 # ]

=head1 EXAMPLE2

 use strict;
 use warnings;

 use CSS::Struct::Output::Structure;
 use Data::Printer;

 my $css = CSS::Struct::Output::Structure->new(
        'output_handler' => \*STDOUT,
 );

 # Set structure.
 $css->put(['c', 'Comment']);
 $css->put(['a', 'charset', 'utf-8']);
 $css->put(['s', 'selector#id']);
 $css->put(['s', 'div div']);
 $css->put(['s', '.class']);
 $css->put(['d', 'weight', '100px']);
 $css->put(['d', 'font-size', '10em']);
 $css->put(['e']);

 # Get structure.
 $css->flush;

 # Output:
 # ['c', 'comment']
 # ['a', 'charset', 'utf-8']
 # ['s', 'selector#id']
 # ['s', 'div div']
 # ['s', '.class']
 # ['d', 'weight', '100px']
 # ['d', 'font-size', '10em']
 # ['e']

=head1 DEPENDENCIES

L<CSS::Struct::Output>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<CSS::Struct>

Struct oriented CSS manipulation.

=item L<CSS::Struct::Output>

Base class for CSS::Struct::Output::*.

=item L<CSS::Struct::Output::Indent>

Indent printing 'CSS::Struct' structure to CSS code.

=item L<CSS::Struct::Output::Raw>

Raw printing 'CSS::Struct' structure to CSS code.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/CSS-Struct-Output-Structure>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
