use strict;
use warnings;
package Data::Rx::CoreType::fail;
# ABSTRACT: the Rx //fail type
$Data::Rx::CoreType::fail::VERSION = '0.200007';
use parent 'Data::Rx::CoreType';

sub assert_valid {
  $_[0]->fail({
    error   => [ qw(fail) ],
    message => "matching reached an always-fail check",
    value   => $_[1],
  });
}

sub subname   { 'fail' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Rx::CoreType::fail - the Rx //fail type

=head1 VERSION

version 0.200007

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
