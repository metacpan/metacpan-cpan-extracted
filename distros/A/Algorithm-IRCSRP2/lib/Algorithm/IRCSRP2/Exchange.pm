package Algorithm::IRCSRP2::Exchange;

BEGIN {
    $Algorithm::IRCSRP2::Exchange::VERSION = '0.501';
}

# ABSTRACT: utility functions

use Moose::Role;

# core
use Scalar::Util qw(blessed);

foreach my $k (qw(I x a A b B S u K1 K2 M1 M2 P s v)) {
    has $k => (
        'isa'     => 'Any',
        'is'      => 'rw',
        'default' => undef,
        'trigger' => sub {
            my ($self, $new, $old) = @_;

            my $str = "Changing IRCSRP exchange $k from %s to %s";

            my ($oldstr, $newstr);

            my $formatstr = sub {
                my ($string) = @_;

                my $retstr;

                if (blessed($string)) {
                    $retstr = (blessed($string) eq 'Math::BigInt') ? $string->bstr : $retstr;
                }
                elsif (!defined($string)) {
                    $retstr = 'undef';
                }
                else {
                    if ($string =~ /[[:^ascii:]]/) {
                        $retstr = Algorithm::IRCSRP2::bytes2int($string);
                    }
                    else {
                        $retstr = $string;
                    }
                }
                return $retstr;
            };

            $self->debug_cb->(sprintf($str, $formatstr->($old), $formatstr->($new)));
        }
    );
}

has 'cipher' => (
    'isa' => 'Crypt::OpenSSL::AES',
    'is'  => 'rw',
);

has 'session_key' => (
    'isa' => 'Str',
    'is'  => 'rw',
);

has 'mac_key' => (
    'isa' => 'Str',
    'is'  => 'rw',
);

no Moose::Role;

1;

__END__

=pod

=head1 NAME

Algorithm::IRCSRP2::Exchange - utility functions

=head1 VERSION

version 0.501

=head1 DESCRIPTION

Role for all the member variables. See
L<http://www.bjrn.se/ircsrp/ircsrp.2.0.txt> for their meaning.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
