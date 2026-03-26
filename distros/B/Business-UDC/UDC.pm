package Business::UDC;

use strict;
use warnings;

use Business::UDC::Parser qw(parse);
use English;
use Error::Pure::Utils qw(clean);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, $source) = @_;

	# Create object.
	my $self = bless {
		'source' => $source,
		'_ast' => undef,
		'_error' => undef,
		'_tokens' => [],
		'_valid' => 0,
	}, $class;

	my $res_hr = eval {
		parse($self->{'source'});
	};
	if ($EVAL_ERROR) {
		chomp $EVAL_ERROR;
		$self->{'_error'} = $EVAL_ERROR;
		clean();
	} else {
		$self->{'_ast'} = $res_hr->{'ast'};
		$self->{'_tokens'} = $res_hr->{'tokens'};
		$self->{'_valid'} = 1;
	}

	return $self;
}

sub ast {
	my $self = shift;

	return $self->{'_ast'};
}

sub error {
	my $self = shift;

	return $self->{'_error'};
}

sub is_valid {
	my $self = shift;

	return $self->{'_valid'};
}

sub source {
	my $self = shift;

	return $self->{'source'};
}

sub tokens {
	my $self = shift;

	return $self->{'_tokens'};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Business::UDC - Class to work with Universal Decimal Classification.

=head1 SYNOPSIS

 use Business::UDC;

 my $obj = Business::UDC->new($udc_string);
 my $ast_hr = $obj->ast;
 my $error = $obj->error;
 my $is_valid = $obj->is_valid;
 my $source = $obj->source;
 my $tokens_ar = $obj->tokens;

=head1 METHODS

=head2 C<new>

 my $obj = Business::UDC->new($udc_string);

Constructor.

Returns instance of object.

=head2 C<ast>

 my $ast_hr = $obj->ast;

Get abstract syntax tree.

Returns reference to hash with structure.

=head2 C<error>

 my $error = $obj->error;

Get error.

TODO Errors.

Returns string or undef.

=head2 C<is_valid>

 my $is_valid = $obj->is_valid;

=head2 C<source>

 my $source = $obj->source;

Get UDC source which goes to constructor.

Returns string.

=head2 C<tokens>

 my $tokens_ar = $obj->tokens;

Get list of tokens defined by tokenization of input UDC string.

Returns reference to array with tokens.

=head1 EXAMPLE

=for comment filename=is_valid.pl

 use strict;
 use warnings;

 use Business::UDC;

 if (@ARGV < 1) {
        print STDERR "Usage: $0 udc_string\n";
        exit 1;
 }
 my $udc_string = $ARGV[0];

 # Object.
 my $obj = Business::UDC->new($udc_string);

 print "UDC string $udc_string ";
 if ($obj->is_valid) {
        print "is valid\n";
 } else {
        print "is not valid\n";
 }

 # Output for '821.111(73)-31"19"':
 # UDC string 821.111(73)-31"19" is valid

 # Output for '821.111(73)-31"19':
 # UDC string 821.111(73)-31"19 is not valid

=head1 DEPENDENCIES

L<Business::UDC::Parser>,
L<English>,
L<Error::Pure>,
L<Error::Pure::Utils>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Business-UDC>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.02

=cut
