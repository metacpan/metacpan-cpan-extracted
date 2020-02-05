package Acme::BayaC;
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $args  = shift || +{};

    bless $args, $class;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Acme::BayaC - one line description


=head1 SYNOPSIS

    use Acme::BayaC;


=head1 METHODS

=head2 new

constructor


=head1 DESCRIPTION

Acme::BayaC is


=head1 REPOSITORY

=begin html

<a href="https://github.com/bayashi/Acme-BayaC/blob/master/LICENSE"><img src="https://img.shields.io/badge/LICENSE-Artistic%202.0-GREEN.png"></a> <a href="https://github.com/bayashi/Acme-BayaC/actions"><img src="https://github.com/bayashi/Acme-BayaC/workflows/build/badge.svg?branch=master"/></a> <a href="https://coveralls.io/r/bayashi/Acme-BayaC"><img src="https://coveralls.io/repos/bayashi/Acme-BayaC/badge.png?branch=master"/></a>

=end html

Acme::BayaC is hosted on github: L<http://github.com/bayashi/Acme-BayaC>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Other::Module>


=head1 LICENSE

C<Acme::BayaC> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
