package Crayon;
our $VERSION = '0.01';
use 5.006;
use strict;
use warnings;
use Struct::Match qw/match/;
use Colouring::In;

our ($LINES, $CI);
BEGIN {
	$LINES = qr{ (([^\{]+)[\{]( (?: (?> [^\{\}]+ ) | (??{ $LINES }) )*) [\}]) }x;
	$CI = qr{ ((mix|lighten|darken|fade|fadeout|fadein|tint|shade|saturate|desaturate|greyscale)[\(]( (?: (?> [^\(\)]+ ) | (??{ $CI }) )*) [\)]) }x;
}

sub new {
	my ($pkg, %args) = @_;
	$args{css} ||= {};
	return bless \%args, $pkg;
}

sub css { $_[0]->{css} }

sub parse {
	my ($self, $string, $css) = @_;
	$css ||= $self->{css};
	while ($string =~ m/$LINES/g) {
		my ($match, $class, $props) = ($1, $2, $3);
		my $nested = {};
		($nested, $props) = $self->parse($props, {})
			if ($props =~ m/$LINES/);
		my $ri = rindex($class, ';');
		if ($ri > 0) {
			my $p = substr $class, 0, $ri + 1, '';
			$string .= $p;
		}
		my @classes = $self->_parse_classes($class);
		my %props = $self->_parse_props($props);
		for (@classes) {
			my $current = $css;
			for (@{$_}) {
				$current = $current->{$_} ||= {};
			}
			%{$current} = (%{$current}, %{$nested}, %props);
		}
		$string =~ s/\Q$match\E//;
	}
	return ($css, $string);
}

sub compile {
	my ($self, $struct) = @_;
	$struct ||= $self->{css};
	my $flat = $self->_dedupe_struct(
		$self->_flattern_struct($struct)
	);
	$self->{pretty} ? $self->_pretty_compile($flat) : $self->_compile($flat);
}

sub _parse_classes {
	my ($self, $class) = @_;
	my @parts = split /,/, $class;
	return map {
		[
			$_ =~ m/^\s*\@/ ? cws($_) : grep {$_} split /\s+/, $_
		]
	} @parts
}

sub _parse_props {
	my ($self, $line) = @_;
	my %props;
	while ($line =~ m/(([^}:]+)\:?([^};]+);)/) {
		my ($match, $key, $val) = (quotemeta($1), cws($2), cws($3));
		$props{$key} = $val;
		$line =~ s/$match//;
	}
	return %props;
}

sub _dedupe_struct {
	my ($self, $struct) = @_;
	for my $class (sort keys %{$struct}) {
		next unless $struct->{$class};
		my $new_class = $class;
		for my $inner (keys %{$struct}) {
			next if $class eq $inner;
			if (match($struct->{$class}, $struct->{$inner})) {
				delete $struct->{$inner};
				$new_class .= ", $inner";
			}
		}
		$struct->{$new_class} = delete $struct->{$class};
	}
	return $struct;
}

sub _flattern_struct {
	my ($self, $struct, $key, $flat) = @_;
	$key ||= '';
	$flat ||= {};
	for (keys %{$struct}) {
		if ( $_ =~ m/^\@/ ) {
			$flat->{$_} = $self->_flattern_struct($struct->{$_}, '', {});
		}
		elsif (ref $struct->{$_}) {
			my $k = $key ? $key . ' ' . $_ : $_;
			$self->_flattern_struct($struct->{$_}, $k, $flat)
		}
		else {
			$flat->{$key}->{$_} = $struct->{$_};
		}
	}
	return $flat;
}

sub _compile {
	my ($self, $flat) = @_;
	my $string = '';
	for my $class (sort keys %{$flat}) {
		$string .= $class . "{";
		for my $prop ( sort keys %{$flat->{$class}} ) {
			if ( ref $flat->{$class}->{$prop} ) {
				$string .= $prop . "{";
				for my $attr ( sort keys %{$flat->{$class}->{$prop}} ) {
					$string .= sprintf("%s:%s;", $attr, $self->_recurse_extensions($flat->{$class}->{$prop}->{$attr}));
				}
				$string .= "}";
			} else {
				$string .= sprintf("%s:%s;", $prop, $self->_recurse_extensions($flat->{$class}->{$prop}));
			}
		}
		$string .= "}";
	}
	return $string;
}

sub _pretty_compile {
	my ($self, $flat) = @_;
	my $string = '';
	for my $class (sort keys %{$flat}) {
		$string .= $class . " {\n";
		for my $prop ( sort keys %{$flat->{$class}} ) {
			if ( ref $flat->{$class}->{$prop} ) {
				$string .= "\t" . $prop . " {\n";
				for my $attr ( sort keys %{$flat->{$class}->{$prop}} ) {
					$string .= sprintf(
						"\t\t%s: %s;\n",
						$attr,
						$self->_recurse_extensions($flat->{$class}->{$prop}->{$attr})
					);
				}
				$string .= "\t}\n";
			} else {
				$string .= sprintf(
					"\t%s: %s;\n",
					$prop,
					$self->_recurse_extensions($flat->{$class}->{$prop})
				);
			}
		}
		$string .= "}\n";
	}
	return $string;
}

sub _recurse_extensions {
	my ($self, $value) = @_;
	while ($value =~ m/$CI/g) {
		my ($match, $meth, $args) = ($1, $2, $3);
		if ($args =~ m/$CI/) {
			$args = $self->_recurse_extensions($args);
		}
		my @params = map { cws($_) } split /,/, $args;
		no strict 'refs';
		my $ci = *{"Colouring::In::$meth"}->(@params)->toCSS;
		$value =~ s/\Q$match\E/$ci/;
	}
	return $value;
}

sub cws {
	my $string = shift;
	$string =~ s/^\s*|\s*$//g;
	return $string;
}


1;

__END__

=head1 NAME

Crayon - CSS Toolkit

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

	use Crayon;

	my $crayon = Crayon->new(
		pretty => 1
	);

	$crayon->parse(q|
		body .class {
			background: lighten(#000, 50%);
			color: darken(#fff, 50%);
		}
	|);

	$crayon->parse(q|
		body {
			.other {
				background: lighten(#000, 50%);
				color: darken(#fff, 50%);
			}
		}
	|);

	my $css = $crayon->compile();
	# body .class, body .other {
	#	background: #7f7f7f;
	#	color: #7f7f7f;
	# }


=head1 SUBROUTINES/METHODS

=head2 new

=head2 parse

=head2 compile

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-crayon at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Crayon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Crayon

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Crayon>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Crayon>

=item * Search CPAN

L<https://metacpan.org/release/Crayon>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Crayon
