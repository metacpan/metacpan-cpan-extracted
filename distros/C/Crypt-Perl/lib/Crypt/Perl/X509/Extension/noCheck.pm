package Crypt::Perl::X509::Extension::noCheck;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::X509::Extension::noCheck

=head1 SYNOPSIS

    my $usage_obj = Crypt::Perl::X509::Extension::noCheck->new();

=head1 SEE ALSO

L<https://www.ietf.org/rfc/rfc2560.txt>

=cut

use parent qw( Crypt::Perl::X509::Extension );

use constant OID => '1.3.6.1.5.5.7.48.1.5';

use constant CRITICAL => 0;

use constant ASN1 => <<END;
    noCheck ::= NULL
END

sub new {
    my ($class) = @_;

    my $self;

    return bless \$self, $class;
}

sub _encode_params {
    my ($self) = @_;

    return;
}

1;
