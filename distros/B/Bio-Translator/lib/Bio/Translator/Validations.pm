package Bio::Translator::Validations;

use strict;
use warnings;

=head1 NAME

Bio::Translator::Validations - validation methods and objects

=cut

use Carp;
use Params::Validate;
use Exporter 'import';

our %EXPORT_TAGS = (
    defaults => [
        qw(
          $DEFAULT_STRAND
          $DEFAULT_START
          $DEFAULT_OFFSET
          )
    ],
    regexes => [
        qw(
          $RE_BOOLEAN
          $RE_NON_NEG_INT
          $RE_STRAND
          $RE_SEARCH_STRAND
          $RE_012
          )
    ],
    validations => [
        qw(
          $VAL_NON_NEG_INT
          $VAL_STRAND
          $VAL_SEARCH_STRAND
          $VAL_START
          $VAL_OFFSET

          validate_seq_params
          validate_lower_upper
          )
    ]
);

our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

=head1 DEFAULTS

=cut

our $DEFAULT_STRAND        = 1;
our $DEFAULT_SEARCH_STRAND = 0;
our $DEFAULT_START         = 1;
our $DEFAULT_OFFSET        = 0;

=head1 REGULAR EXPRESSIONS

=cut

our $RE_BOOLEAN       = qr/^[01]$/;
our $RE_NON_NEG_INT   = qr/^\+?\d+$/;
our $RE_STRAND        = qr/^[+-]?1$/;
our $RE_SEARCH_STRAND = qr/^[+-]?[01]$/;
our $RE_012           = qr/^[012]$/;

=head1 VALIDATIONS

=cut

our $VAL_NON_NEG_INT = {
    optional => 1,
    regex    => $RE_NON_NEG_INT,
    type     => Params::Validate::SCALAR,
};

# Make sure strand is 1 or -1 and set default
our $VAL_STRAND = {
    default => $DEFAULT_STRAND,
    regex   => $RE_STRAND,
    type    => Params::Validate::SCALAR
};

# Make sure strand is 0, 1 or -1 and set default
our $VAL_SEARCH_STRAND = {
    default => $DEFAULT_SEARCH_STRAND,
    regex   => $RE_SEARCH_STRAND,
    type    => Params::Validate::SCALAR
};

# Make sure partial is boolean and set default
our $VAL_START = {
    default => $DEFAULT_START,
    type    => Params::Validate::SCALAR
};

# Make sure offset is 0, 1 or 2 and set default
our $VAL_OFFSET = {
    default => $DEFAULT_OFFSET,
    regex   => $RE_012,
    type    => Params::Validate::SCALAR
};

=head1 VALIDATION METHODS

=cut

=head2 validate_seq_params

    my ( $seq_ref, @p ) = validate_seq_params(@_);

Do validations for methods expecting to be called as:

    method( $sequence,  \%params ); # or
    method( \$sequence, \%params );

=cut

sub validate_seq_params (\@) {
    my ( $seq_ref, @p ) = validate_pos(
        @{ $_[0] },
        { type => Params::Validate::SCALARREF | Params::Validate::SCALAR },
        { type => Params::Validate::HASHREF, default => {} }
    );

    $seq_ref = \$seq_ref unless ( ref $seq_ref );
    return ( $seq_ref, @p );
}

=head2 validate_lower_upper

    my ( $lower, $upper ) = validate_lower_upper( $lower, $upper, $seq_ref );
    my ( $lower, $upper ) = validate_lower_upper( delete( @p{qw/ lower upper /} ), $seq_ref );
    
Validate lower and upper bounds. Assumes that they have already passed
$VAL_NON_NEG_INT.

=cut

sub validate_lower_upper {
    my ( $lower, $upper, $seq_ref ) = @_;

    if ($upper) {
        croak 'upper bound is out range'
          if ( $upper > length($$seq_ref) );
    }
    else { $upper = length($$seq_ref) }

    if ($lower) {
        croak 'lower bound is greater than upper bound'
          if ( $lower > $upper );
    }
    else { $lower = 0 }

    return ( $lower, $upper );
}

1;
