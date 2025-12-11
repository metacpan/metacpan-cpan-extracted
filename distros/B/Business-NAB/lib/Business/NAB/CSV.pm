package Business::NAB::CSV;
$Business::NAB::CSV::VERSION = '0.02';
# undocument abstract class for parsing/creating CSV lines
# mostly delegated to Text::CSV_XS

use strict;
use warnings;
use feature qw/ signatures /;
use autodie qw/ :all /;
use Carp    qw/ croak /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures /;

use Text::CSV_XS qw/ csv /;

sub _record_type { croak( "You must define the _record_type method" ) }

sub _attributes { croak( "You must define the _attributes method" ) }

sub new_from_record ( $class, $line ) {

    my $aoh = csv(
        in      => \$line,
        headers => [ 'record_type', $class->_attributes ],
    ) or croak( Text::CSV->error_diag );

    my $self = $class->new( my %record = $aoh->[ 0 ]->%* );

    if ( $record{ record_type } ne $self->_record_type ) {
        croak( "unsupported record type (@{[ $record{record_type} ]})" );
    }

    return $self;
}

sub to_record ( $self, $aoa = undef ) {

    $aoa //= [ [
        map { $self->$_ }
            '_record_type', $self->_attributes,
    ] ];

    csv(
        in          => $aoa,
        out         => \my $data,
        quote_space => 0,
        eol         => '',
    );

    return $data;
}

1;
