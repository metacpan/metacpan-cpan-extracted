package Acme::Math::XS::LeanDist;

our $VERSION = '0.100';

require Exporter;
use base 'Exporter';
our @EXPORT = qw(add subtract);

# Commented out for distribution by Inline::Module::LeanDist
#use Inline::Module::LeanDist C => 'DATA';

# XSLoader added for distribution by Inline::Module::LeanDist:
require XSLoader; XSLoader::load(__PACKAGE__, $VERSION);



1;


__DATA__
__C__

long add(long a, long b) {
    return a + b;
}

long subtract(long a, long b) {
    return a - b;
}


__END__

=encoding utf-8

=head1 NAME

Acme::Math::XS::LeanDist - Example module for Inline::Module::LeanDist

=head1 SYNOPSIS

    use Acme::Math::XS::LeanDist;

    print add(4, 3);

=head1 DESCRIPTION

This is a super simple demonstration module for L<Inline::Module::LeanDist> in the spirit of L<Acme::Math::XS>.

=head1 SEE ALSO

L<Acme-Math-XS-LeanDist github repo|https://github.com/hoytech/Acme-Math-XS-LeanDist>

L<Inline::Module::LeanDist>

L<Inline::Module>

L<Inline>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2015 Doug Hoyte.

This module is licensed under the same terms as perl itself.
