package API::Docker::Type::HealthcheckResult;
# ABSTRACT: Information about a single run of a healthcheck probe
our $VERSION = '0.006';
use API::Docker::Type;
use namespace::clean;


docker start => Str;


docker end => Str;


docker exit_code => Int;


docker output => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::Docker::Type::HealthcheckResult - Information about a single run of a healthcheck probe

=head1 VERSION

version 0.006

=head1 DESCRIPTION

Generated from the C<HealthcheckResult> definition of C<spec/v1.51.yaml>.

=head2 start

Date and time at which this check started in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 end

Date and time at which this check ended in L<RFC
3339|https://www.ietf.org/rfc/rfc3339.txt> format with nano-seconds.

=head2 exit_code

ExitCode meanings:

=over 4

=item * C<0> healthy

=item * C<1> unhealthy

=item * C<2> reserved (considered unhealthy)

=item * other values: error running probe

=back

=head2 output

Output from last check.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-api-docker/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
