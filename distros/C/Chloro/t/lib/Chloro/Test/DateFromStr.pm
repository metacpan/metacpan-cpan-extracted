package Chloro::Test::DateFromStr;

use Moose;
use namespace::autoclean;

use Chloro;

use Chloro::Types qw( Str );

use DateTime;

field date => (
    isa       => 'DateTime',
    required  => 1,
    extractor => '_extract_date',
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _extract_date {
    my $self   = shift;
    my $params = shift;
    my $prefix = shift;

    my %keys = map { $_ => $_ } qw( year month day );

    if ( defined $prefix ) {
        $keys{$_} = join q{.}, $prefix, $keys{$_} for keys %keys;
    }

    return (
        DateTime->new(
            map { $_ => $params->{ $keys{$_} } } qw( year month day )
        ),
        ( 'year', 'month', 'day' ),
    );
}
## use critic

__PACKAGE__->meta()->make_immutable;

1;
