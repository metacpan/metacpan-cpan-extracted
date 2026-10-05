package Airlock::Policy;

# ABSTRACT: Decide which factors an Airlock approval needs

use Moo;
use Types::Standard qw( ArrayRef CodeRef HashRef Int Str );
use namespace::autoclean;

our $VERSION = '0.001';


has always => (
  is      => 'ro',
  isa     => ArrayRef[Str],
  default => sub { [] }
);


has step_up => (
  is      => 'ro',
  isa     => HashRef[ArrayRef[Str]],
  default => sub { {} }
);


has max_auth_age => (
  is        => 'ro',
  isa       => Int,
  predicate => 'has_max_auth_age'
);


has decide => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_decide'
);


sub clock_skew { 60 }


sub required {
  my ( $self, $request, $subject ) = @_;
  my %seen;
  my @names = grep { !$seen{$_}++ } @{ $self->always },
    map { @{ $self->step_up->{$_} || [] } } @{ $request->{scopes} || [] };
  return $self->has_decide ? $self->decide->( $request, $subject, \@names ) : \@names;
}


sub fresh {
  my ( $self, $subject, $now ) = @_;
  return 1 unless $self->has_max_auth_age;
  return 0 unless defined $subject->{auth_time};
  my $age = $now - $subject->{auth_time};
  return $age >= -$self->clock_skew && $age <= $self->max_auth_age ? 1 : 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Policy - Decide which factors an Airlock approval needs

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $policy = Airlock::Policy->new(
      always       => ['upstream'],
      step_up      => { admin => ['totp'] },
      max_auth_age => 300,
    );

=head1 DESCRIPTION

Maps a request and the approving subject to the names of the factors that have
to verify before the approval counts. Declarative for the usual case, a coderef
for everything else.

=head2 always

Factor names required for every approval.

=head2 step_up

Hash of scope to factor names. A request asking for that scope needs those
factors.

=head2 max_auth_age

Optional. Seconds since the subject's C<auth_time> after which no approval is
accepted at all. A subject without C<auth_time> then counts as too old.

=head2 decide

Optional. Coderef called with the request view, the subject and the list the
declarative rules produced; returns the list to use.

=head2 clock_skew

Seconds an C<auth_time> may lie in the future before it is taken for wrong
rather than for clock drift. 60.

=head2 required

    my $names = $policy->required( $view, $subject );

The factor names this approval needs, without duplicates, in a stable order.

=head2 fresh

    $policy->fresh( $subject, time ) or return;

True when the subject's authentication is recent enough to approve anything.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-airlock/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
