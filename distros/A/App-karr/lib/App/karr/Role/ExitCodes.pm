# ABSTRACT: Normalize MooX::Options option-parse errors to exit code 2 (ADR 0002)

package App::karr::Role::ExitCodes;
our $VERSION = '0.400';
use Moo::Role;


around options_usage => sub {
    my ($orig, $self, $code, @rest) = @_;
    $code = 2 if defined $code && $code > 0;
    return $orig->($self, $code, @rest);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::ExitCodes - Normalize MooX::Options option-parse errors to exit code 2 (ADR 0002)

=head1 VERSION

version 0.400

=head1 DESCRIPTION

Part of karr's exit-code contract (ADR 0002): C<0> success, C<1> runtime
failure, C<2> usage error.

MooX::Options handles an option-parse failure -- an unknown option, an invalid
option value, or a missing required option -- by printing a diagnostic and then
calling C<< $class->options_usage($code) >> with a positive C<$code>, which
C<exit>s that code. Historically that code was C<1>, which collided with genuine
runtime failures. Those are B<usage> errors, so this role wraps C<options_usage>
to force any positive (error) code to C<2>.

Help requests (C<-h>, C<--help>, C<--usage>) reach C<options_usage> with a code
of C<0> (or undef), so they are left untouched: they still print to STDOUT and
exit C<0>.

The complementary half of the contract -- catching the uncaught C<die>s raised
by command bodies and classifying them into runtime (C<1>) versus usage (C<2>)
-- lives in the central handler in F<bin/karr>. The root command's own
option-parse errors go through its C<_print_help> override instead of this role,
and that override applies the same positive-to-C<2> remap.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
