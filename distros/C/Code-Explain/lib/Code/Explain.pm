package Code::Explain;
use 5.008;
use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.02';

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;

	$self->{code} = $args{code}
		or croak('Method ->new needs a "code" => $some_code pair');

	return $self
}

sub code { return $_[0]->{code} };

sub explain {
	my ($self, $code) = @_;

	# TODO we will maintain a database of exact matches
	my %exact = (
		'$_'    => 'Default variable',
		'@_'    => 'Default array',
		'given' => 'keyword in perl 5.10',
		'say'   => 'keyword in perl 5.10',
		'!!'    => 'Creating boolean context by negating the value on the right hand side twice',
	);

	$code = $self->code if not defined $code;
	if ($exact{$code}) {
		return $exact{$code};
	}

	# parentheses after the name of a subroutine
	if ($code =~ /^(\w+)\(\)$/) {
		my $sub = $1;
		if ($exact{$sub}) {
			return $exact{$sub};
		}
	}

	# '' .
	if ($code =~ m{^'' \s* \.$}x) {
		return 'Forcing string context';
	}

	# 0 +
	if ($code =~ m{^0 \s* \+$}x) {
		return 'Forcing numeric context';
	}

	my $NUMBER = qr{\d+(?:\.\d+)?};

	# 2 + 3
	if ($code =~ m{^$NUMBER \s* [/*+-]  \s* $NUMBER$}x) {
		return 'Numerical operation';
	}

	# 2
	# 2.34
	if ($code =~ /^$NUMBER$/) {
		return 'A number';
	}

	# 23_145
	if ($code =~ /^\d+(_\d\d\d)+$/) {
		return 'This is the same as the number ' . eval($code) . ' just in a more readable format';
	}

	# $_[2], $_[$var], $name[42]
	if ($code =~ /\$(\w+)\[(.*?)\]/) {
		if ($1 eq '_') {
			return "This is element $2 of the default array \@_";
		} else {
			return "This is element $2 of the array \@$1";
		}
	}

	# $phone{$name}
	if ($code =~ m{^\$(\w+)    \{  \$(\w+) \}  }x) {
		my ($hash_name, $key_name) = ($1, $2);
		return "The element \$$key_name of the hash \%$hash_name";
	}

	# $$x
	if ($code =~/^\$\$(\w+)$/) {
		return "\$$1 is a reference to a scalar value. This expression dereferences it. See perlref";
	}

	# $x ||= $y
	if ($code  =~ m{^\$(\w+) \s*  \|\|= \s* \$(\w+)$}x) {
		my $lhs = $1;
		return "Assigning default value to \$$lhs. It has the disadvantage of not allowing \$$lhs=0. Startin from 5.10 you can use //= instead of ||=";
	}

	# $self->editor
	if ($code =~ m{^\$(\w+)   ->   (\w+)}x) {
		my ($obj_name, $method) = ($1, $2);
		return "Calling method '$method' on an object in the variable called \$$obj_name",
	}

	return "Not found";
}

sub ppi_dump {
	my ($self) = @_;

	require PPI::Dumper;
	my $dumper = PPI::Dumper->new( $self->ppi_document );
	return $dumper->list;
}

sub ppi_explain {
	my ($self) = @_;

	my $document = $self->ppi_document;

	my @result;
	foreach my $token ( $document->tokens ) {
		push @result, {
			code => $token->content,
			text => $self->explain($token->content),
		};
	}
	return @result;
}

sub ppi_document {
	my ($self) = @_;
	
	if (not $self->{ppi_document}) {
		require PPI::Document;
		my $code = $self->code;
		$self->{ppi_document} = PPI::Document->new(\$code);
#		$self->{ppi_document}->index_locations;
	}

	return $self->{ppi_document};
}


=head1 NAME

Code::Explain - Try to explain what $ @ % & * and the rest mean

=head1 SYNOPSIS


   my $ce = Code::Explain->new;
   $str = '$x ||= $y';
   print $ce->explain($str), "\n";

or

   @ppi_dump = $ce->ppi_dump($str);

=head1 COMMAND LINE

The module comes with a command line tool called

   explain-code

You give a perl expression to it and it will give an explanation
what that might be.


=head1 COMMAND LINE OPTIONS

One of the following:

   --explain     Try to exaplain our way
   --ppidump     Run PPI on the code and print the dump
   --ppiexplain  Run PPI on the code and try to explain the individual tokens
   --all         All of the above

   --help        Prints the list of command line options


=head1 DESCRIPTION

This is pre-alpha version (whatever that means) of the code
explain tool. It should be able to understand various perl
constructs such as.


    $x ||=  $y;

    @data = map { ... } sort { ... } grep { ... } @data;

give a short explanation and reasonable pointers to the documentation.

See the t/cases.txt file more cases that are already handled.
Add further cases to t/todo.txt, preferably with some explanation.

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT and LICENSE

This software is copyright (c) 2011 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;

