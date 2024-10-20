use v5.12.0;
use warnings;
package Data::Rx::CoreType::fail 0.200008;
# ABSTRACT: the Rx //fail type

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

version 0.200008

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
