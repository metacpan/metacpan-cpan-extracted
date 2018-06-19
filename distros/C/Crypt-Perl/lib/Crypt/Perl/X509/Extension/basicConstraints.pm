package Crypt::Perl::X509::Extension::basicConstraints;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::basicConstraints

=cut

use parent qw( Crypt::Perl::X509::Extension );

use Crypt::Perl::X ();

use constant OID => '2.5.29.19';

use constant ASN1 => <<END;
    basicConstraints ::= SEQUENCE {
        cA  BOOLEAN,
        pathLenConstraint INTEGER OPTIONAL
    }
END

sub new {
    my ($class, $ca_yn, $pl_constraint) = @_;

    return bless { _ca => $ca_yn, _pl_constraint => $pl_constraint }, $class;
}

sub _encode_params {
    my ($self) = @_;

    my $data = {
        cA => $self->{'_ca'} ? 1 : 0,

        ( defined $self->{'_pl_constraint'}
            ? ( pathLenConstraint => $self->{'_pl_constraint'} )
            : ()
        ),
    };

    return $data;
}

1;
