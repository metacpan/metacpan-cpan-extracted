package Crypt::Perl::X509::Extension::inhibitAnyPolicy;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::inhibitAnyPolicy

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::inhibitAnyPolicy->new( 5 );

=head1 SEE ALSO

L<https://tools.ietf.org/html/rfc5280#section-4.2.1.14>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use constant OID => '2.5.29.54';

use constant CRITICAL => 1;

use constant ASN1 => <<END;
    SkipCerts ::= INTEGER

    inhibitAnyPolicy ::= SkipCerts
END

sub new {
    my ($class, $skip_int) = @_;

    return bless \$skip_int, $class;
}

sub _encode_params {
    my ($self) = @_;

    return $$self;
}

1;
