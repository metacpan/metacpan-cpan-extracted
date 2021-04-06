package Crayon;
our $VERSION = '0.06';
use 5.006;
use strict;
use warnings;
use Struct::Match qw/match/;
use Colouring::In;
use Blessed::Merge;

our ($LINES, $GLOBAL, $NESTED_GLOBAL, $NESTED_VARIABLE, $VARIABLE, $COMMENT, $CI);
BEGIN {
	$LINES = qr{ ([\{]( (?: (?> [^\{\}]+ ) | (??{ $LINES }) )*) [\}]) }x;
	$GLOBAL = qr{ (\$([^:\n]+)\:([^;\n]+);) }x;
	$VARIABLE = qr{ (\$(.*)) }x;
	$COMMENT = qr{ (\/\*[^*]*\*+([^/*][^*]*\*+)*\/) }x;
	$NESTED_GLOBAL = qr{ (\%([^\:\(]+)[\:\s\(]+( (?: (?> [^\(\)]+ ) | (??{ $NESTED_GLOBAL }) )*) [\)];) }x;
	$NESTED_VARIABLE = qr{ (\$([^\{]+)[\{]( (?: (?> [^\{\}]+ ) | (??{ $NESTED_VARIABLE }) )*) [\}]) }x;
	$CI = qr{ ((mix|lighten|darken|fade|fadeout|fadein|tint|shade|saturate|desaturate|greyscale)[\(]( (?: (?> [^\(\)]+ ) | (??{ $CI }) )*) [\)]) }x;
}

sub new {
	my ($pkg, %args) = @_;
	$args{css} ||= {};
	$args{bm} ||= Blessed::Merge->new();
	return bless \%args, $pkg;
}

sub css { $_[0]->{css} }

sub bm { $_[0]->{bm} }

sub parse {
	my ($self, $string, $css) = @_;
	$css ||= $self->{css};
	return $self->_parse_content($self->_strip_comments($string), $css);
}

sub parse_file {
	my ($self, $file, $css) = @_;
	open my $fh, '<', $file or die "cannot open file:$file $!";
	my $string = do { local $/; <$fh> };
	close $fh;
	$self->parse($string, $css);
}

sub compile {
	my ($self, $struct) = @_;
	$struct ||= $self->{css};
	my $flat = $self->_dedupe_struct(
		$self->_flattern_struct($struct)
	);
	$self->{pretty} ? $self->_pretty_compile($flat) : $self->_compile($flat);
}

sub compile_file {
	my ($self, $file, $struct) = @_;
	my $string = $self->compile($struct);
	open my $fh, '>', $file or die "cannot open file:$file $!";
	print $fh $string;
	close $fh;
}

sub _strip_comments {
	my ($self, $string) = @_;

	while ($string =~ m/$COMMENT/g) {
		$string =~ s/\Q$1\E//g;
	}
	return $string;
}

sub _parse_globals {
	my ($self, $string) = @_;
	my %globals;
	while ($string =~ m/$GLOBAL/g) {
		my ($match, $class, $props) = ($1, cws($2), cws($3));
		next unless $class && $props;
		$globals{$class} = $props;
		$string =~ s/\Q$match\E//;
	}
	while ($string =~ m/$NESTED_GLOBAL/g) {
		my ($match, $class, $props) = ($1, cws($2), cws($3));
		my %props = $self->_parse_props($props);
		$globals{$class} = \%props;
		$string =~ s/\Q$match\E//;
	}

	return (\%globals, $string);
}

sub _parse_content {
	my ($self, $string, $css) = @_;

	my $globals = {};
	while ( $string =~ m/(([^{]+)$LINES)/g ) {
		my ($match, $class, $props) = ($1, $2, $4);
		
		my $nested = {};
		($nested, $props) = $self->_parse_content($props, {})
			if ($props =~ m/$LINES/);

		my $ri = rindex($class, ';');
		if ($ri > 0) {
			my $p = substr $class, 0, $ri + 1, '';
			$string .= $p;
		}
		return ($css, $string) if ($class =~ m/^[^@]+:\s*\$/);
		($globals, $props) = $self->_parse_globals($props);	

		my @classes = $self->_parse_classes($class);
		my %props = $self->_parse_props($props);
		for (@classes) {
			my $current = $css;
			for (@{$_}) {
				$current = $current->{$_} ||= {};
			}
			%{$current} = %{$self->bm->merge($current, $nested, \%props)};
			$current->{VARIABLES} = $self->bm->merge($current->{VARIABLES} || {}, $globals) if keys %{$globals};
		}

		$string =~ s/\Q$match\E//;
	}

	($globals, $string) = $self->_parse_globals($string);
	$css->{VARIABLES} = $globals if keys %{$globals}; 

	return ($css, $string);
}

sub _parse_classes {
	my ($self, $class) = @_;
	my @parts = split /,/, $class;
	return map {
		my $p = $_;
		[
			$p =~ m/^\s*\@/ ? cws($p) : do { $p =~ s/\:/ &/g; 1 } && grep {$_} split /\s+/, $p
		]
	} @parts
}

sub _parse_props {
	my ($self, $line) = @_;
	my %props;
	while ($line =~ m/(([^:]+)\:([^;]+);)/) {
		my ($match, $key, $val) = (quotemeta($1), cws($2), cws($3));
		$props{$key} = $val;
		$line =~ s/$match//;
	}
	while ($line =~ m/((\%[^;]+);)/) {
		my ($match, $key, $val) = (quotemeta($1), cws($2), cws($3));
		$props{$key} = 1;
		$line =~ s/$match//;
	}
	return %props;
}

sub _dedupe_struct {
	my ($self, $struct) = @_;
	for my $class (sort keys %{$struct}) {
		next unless $struct->{$class};
		my $new_class = $class;
		if ($class =~ m/^\@/) {
			$struct->{$new_class} = $self->_dedupe_struct($struct->{$class});
		} else {
			for my $inner (sort keys %{$struct}) {
				next if $class eq $inner;
				if (match($struct->{$class}, $struct->{$inner})) {
					delete $struct->{$inner};
					$new_class .= ", $inner";
				}
			}
			$struct->{$new_class} = delete $struct->{$class};
		}
	}
	return $struct;
}

sub _flattern_struct {
	my ($self, $struct, $key, $flat) = @_;
	$key ||= '';
	$flat ||= {};
	my $scp;

	if ($struct->{VARIABLES}) {
		$flat->{$key || 'GLOBAL'}->{VARIABLES} = delete $struct->{VARIABLES};
		$scp = $flat->{$key}->{VARIABLES} if $key;
	}
	for my $s (keys %{$struct}) {
		if ( $s =~ m/^\@/ ) {
			$flat->{$s} = $self->_flattern_struct($struct->{$s}, '', {});
		}
		elsif (ref $struct->{$s}) {
			my $k = $key ? $s =~ m/^\&(.*)/ ? $key . ':' . $1 : $key . ' ' . $s : $s;
			$self->_flattern_struct($struct->{$s}, $k, $flat);
			$flat->{$k}->{VARIABLES} = $self->bm->merge($scp, $flat->{$k}->{VARIABLES} || {}) if $scp;
		}
		else {
			$flat->{$key}->{$s} = $struct->{$s};
		}
	}
	return $flat;
}

sub _expand_nested_variables {
	my ($self, $struct, $variables) = @_;
	for my $key (keys %{$struct}) {
		if ($key =~ m/^\%(.*)/) {
			delete $struct->{$key};
			$struct = $self->bm->merge($struct, $variables->{$1});
		}
	}
	return $struct;
}


sub _compile {
	my ($self, $flat) = @_;
	my $string = '';
	my %global = %{ delete $flat->{GLOBAL} || {} };
	for my $class (sort keys %{$flat}) {
		my $variables = $self->bm->merge(
			$global{VARIABLES} || {}, 
			delete $flat->{$class}->{VARIABLES} || {}
		);
		$string .= $class . "{";
		$flat->{$class} = $self->_expand_nested_variables($flat->{$class}, $variables);
		next unless keys %{$flat->{$class}};
		for my $prop ( sort keys %{$flat->{$class}} ) {
			if ( ref $flat->{$class}->{$prop} ) {
				$string .= $prop . "{";
				for my $attr ( sort keys %{$flat->{$class}->{$prop}} ) {
					$string .= sprintf(
						"%s:%s;", 
						$attr, 
						$self->_recurse_extensions(
							$flat->{$class}->{$prop}->{$attr}, 
							$variables
						)
					);
				}
				$string .= "}";
			} else {
				$string .= sprintf(
					"%s:%s;", 
					$prop, 
					$self->_recurse_extensions(
						$flat->{$class}->{$prop}, 
						$variables
					)
				);
			}
		}
		$string .= "}";
	}
	return $string;
}

sub _pretty_compile {
	my ($self, $flat) = @_;
	my $string = '';
	my %global = %{ delete $flat->{GLOBAL} || {} };
	for my $class (sort keys %{$flat}) {
		my $variables = $self->bm->merge(
			$global{VARIABLES} || {}, 
			delete $flat->{$class}->{VARIABLES} || {}
		);
		$flat->{$class} = $self->_expand_nested_variables($flat->{$class}, $variables);
		next unless keys %{$flat->{$class}};
		$string .= join(",\n", split(", ", $class)) . " {\n";
		for my $prop ( sort keys %{$flat->{$class}} ) {
			if ( ref $flat->{$class}->{$prop} ) {
				$string .= "\t" . join(",\n\t", split(", ", $prop)) . " {\n";
				for my $attr ( sort keys %{$flat->{$class}->{$prop}} ) {
					$string .= sprintf(
						"\t\t%s: %s;\n",
						$attr,
						$self->_recurse_extensions($flat->{$class}->{$prop}->{$attr}, $variables)
					);
				}
				$string .= "\t}\n";
			} else {
				$string .= sprintf(
					"\t%s: %s;\n",
					$prop,
					$self->_recurse_extensions($flat->{$class}->{$prop}, $variables)
				);
			}
		}
		$string .= "}\n";
	}
	return $string;
}

sub _recurse_extensions {
	my ($self, $value, $variables) = @_;
	while ($value =~ m/$NESTED_VARIABLE/g || $value =~ m/$VARIABLE/g) {
		my ($match, $meth, $args) = ($1, cws($2), cws($3));
		my $val = $args ? $variables->{$meth}->{$args} : $variables->{$meth};
		$value =~ s/\Q$match\E/$val/;
	}
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
	$string && $string =~ s/^\s*|\s*$//g;
	return $string;
}

1;

__END__

=head1 NAME

Crayon - dedupe, minify and extend CSS

=head1 VERSION

Version 0.06 

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

Instantiate a new Crayon Object.

	Crayon->new();

=head2 parse

Parse css strings into Crayons internal struct.

	$crayon->parse(q|
		.some .class {
			...
		}
	|);


=head2 parse_file

Parse a file containing CSS/Crayon.

	$crayon->parse_file($file_name);

=head2 compile

Compile the current Crayon struct into CSS.

	$crayon->compile();

=head2 compile_file

Compile the current Crayon struct into the given file.

	$crayon->compile_file($file_name);

=head1 Crayon

=head2 Variables

Crayon allows you to define variables that can be reused throughout your css.

	$width: 10px;
	$height: 20px;
	#header {
		width: $width;
		height: $height;
	}

Outputs:

	#header {
		width: 10px;
		height: 20px;
	}

=head2 Scope

Scope in Crayon is very similar to that of CSS. Variables and mixins are first looked for locally, and if they aren't found, it's inherited from the "parent" scope.

	$var: red;
	#page {
		$var: white;
		#header {
			color: $var; // white
		}
	}

Like CSS custom properties, mixin and variable definitions do not have to be placed before a line where they are referenced. So the following Crayon code is identical to the previous example:

	$var: red;
	#page {
		#header {
			color: $var; // white
		}
		$var: white;
	}

=head2 Mixins

Mixins are a way of including ("mixing in") a bunch of properties into a rule-set. 

	%border: (
		border-top: dotted 1px black;
		border-bottom: solid 2px black;	
	);
	#header {
		background: #000;
		%border;
	}

Outputs:

	#header {
		background: #000;
		border-top: dotted 1px black;
		border-bottom: solid 2px black;	
	}

=head2 Maps

You can also use mixins as maps of values.

	%colors: {
		primary: blue;
		secondary: green;
	};
	.button {
		color: $colors{primary};
		border: 1px solid $colors{secondary};
	}

=head2 Nesting

Crayon gives you the ability to use nesting instead of, or in combination with cascading. Let's say we have the following CSS:

	#header {
		color: black;
	}
	#header .navigation {
		font-size: 12px;
	}
	#header .logo {
		width: 300px;
	}

In Crayon, we can also write it this way:

	#header {
		color: black;
		.navigation {
			font-size: 12px;
		}
		.logo {
			width: 300px;
		}
	}

You can also bundle pseudo-selectors with your mixins using this method. Here's the classic clearfix hack, rewritten as a mixin (& represents the current selector parent):

	.clearfix {
		display: block;
		zoom: 1;

		&after {
			content: " ";
			display: block;
			font-size: 0;
			height: 0;
			clear: both;
			visibility: hidden;
		}
	}

=head2 Functions

Crayon currently provides a variety of functions which transform colors.

=over

=item mix

=item lighten

=item darken

=item fade

=item fadeout

=item fadein

=item tint

=item shade

=item saturate

=item desaturate

=item greyscale

=back

=head2 Comments

Both block-style and inline comments may be used:

	/* One heck of a block
	*   style comment! */
	$var: red;

	// Get in line!
	$var: white;

=head2 Deduplication

Crayon attempts to deduplicate your CSS so when compiled the final string contains the least amount of characters possible.

	body .class {
		background: lighten(#000, 50%);
		color: darken(#fff, 50%);
	}
	body {
		.other {
			background: lighten(#000, 50%);
			color: darken(#fff, 50%);
		}
	}

Output:

	body .class, body .other {
		background: #7f7f7f;
		color: #7f7f7f;
	}


=head2 Pretty

The default behaviour for Crayon is to minify CSS. However if you prefer you have the option to pretty print aswell.


	Crayon->new( pretty => 1 );


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
