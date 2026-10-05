package Airlock::Test::Store;

# ABSTRACT: Contract tests for an Airlock store

use Moo;
use Test::More;
use Types::Standard qw( CodeRef HashRef );
use namespace::autoclean;

our $VERSION = '0.001';


has store => (
  is       => 'ro',
  isa      => HashRef[CodeRef],
  required => 1
);


sub row {
  my ( $self, %override ) = @_;
  return {
    hash            => 'airlock-test-1',
    kind            => 'request',
    user_code       => 'BCDFGHJK',
    client_id       => 'client',
    scope           => 'read write',
    state           => 'pending',
    created         => 1000,
    expires         => 1600,
    poll_interval   => 5,
    last_poll       => undef,
    subject         => undef,
    amr             => undef,
    acr             => undef,
    auth_time       => undef,
    approved        => undef,
    origin_ip       => '192.0.2.1',
    origin_ua       => 'test/1.0',
    factor_failures => 0,
    %override
  };
}


sub run {
  my ( $self ) = @_;
  my $store = $self->store;

  subtest 'store has the required subs' => sub {
    ok( ref $store->{$_} eq 'CODE', $_.' is a coderef' ) for qw( insert find update );
  };

  subtest 'insert and find' => sub {
    $store->{insert}->( $self->row );
    my $by_hash = $store->{find}->( 'hash', 'airlock-test-1' );
    ok( $by_hash, 'found by hash' ) or return;
    my $want = $self->row;
    is( $by_hash->{$_}, $want->{$_}, 'field '.$_.' round-trips' ) for sort keys %$want;
    my $by_code = $store->{find}->( 'user_code', 'BCDFGHJK' );
    is( $by_code && $by_code->{hash}, 'airlock-test-1', 'found by user_code' );
    ok( !$store->{find}->( 'hash', 'airlock-test-nope' ), 'unknown hash finds nothing' );
    ok( !$store->{find}->( 'user_code', 'ZZZZZZZZ' ), 'unknown user_code finds nothing' );
    ok( !$store->{find}->( 'user_code', undef ), 'undef finds nothing' );
  };

  subtest 'uniqueness' => sub {
    ok( !eval { $store->{insert}->( $self->row ); 1 }, 'duplicate hash is refused' );
    ok(
      !eval { $store->{insert}->( $self->row( hash => 'airlock-test-2' ) ); 1 },
      'duplicate user_code is refused'
    );
    ok( !$store->{find}->( 'hash', 'airlock-test-2' ), 'the refused row is not there' );
    ok(
      eval { $store->{insert}->( $self->row( hash => 'airlock-test-3', user_code => undef, kind => 'token', state => 'active' ) ); 1 },
      'a row without user_code goes in'
    ) or diag $@;
    ok(
      eval { $store->{insert}->( $self->row( hash => 'airlock-test-4', user_code => undef, kind => 'token', state => 'active' ) ); 1 },
      'a second row without user_code goes in too'
    ) or diag $@;
  };

  subtest 'update is conditional on the old state' => sub {
    ok( !$store->{update}->( 'airlock-test-1', 'approved', { state => 'redeemed' } ), 'wrong old state: refused' );
    is( $store->{find}->( 'hash', 'airlock-test-1' )->{state}, 'pending', 'and nothing changed' );
    ok( !$store->{update}->( 'airlock-test-nope', 'pending', { state => 'approved' } ), 'unknown hash: refused' );
    ok(
      $store->{update}->( 'airlock-test-1', 'pending', { last_poll => 1010, poll_interval => 10 } ),
      'right old state, state itself untouched: applied'
    );
    my $polled = $store->{find}->( 'hash', 'airlock-test-1' );
    is( $polled->{last_poll}, 1010, 'last_poll written' );
    is( $polled->{poll_interval}, 10, 'poll_interval written' );
    is( $polled->{state}, 'pending', 'state still pending' );
    ok( $store->{update}->( 'airlock-test-1', 'pending', { factor_failures => \1 } ), 'increment: applied' );
    ok( $store->{update}->( 'airlock-test-1', 'pending', { factor_failures => \1, poll_interval => \5 } ), 'two increments at once: applied' );
    my $counted = $store->{find}->( 'hash', 'airlock-test-1' );
    is( $counted->{factor_failures}, 2,  'a reference to a number is added, not stored' );
    is( $counted->{poll_interval},   15, 'for any numeric field' );
    ok( !$store->{update}->( 'airlock-test-1', 'approved', { factor_failures => \1 } ), 'increment from the wrong state: refused' );
    is( $store->{find}->( 'hash', 'airlock-test-1' )->{factor_failures}, 2, 'and not counted' );
    ok(
      $store->{update}->( 'airlock-test-1', 'pending', {
        state => 'approved', user_code => undef, subject => 'alice', amr => 'pwd otp', auth_time => 1005, approved => 1020
      } ),
      'approve: applied'
    );
    my $approved = $store->{find}->( 'hash', 'airlock-test-1' );
    is( $approved->{state},   'approved', 'state written' );
    is( $approved->{subject}, 'alice',    'subject written' );
    is( $approved->{amr},     'pwd otp',  'amr written' );
    is( $approved->{user_code}, undef,    'user_code cleared' );
    ok( !$store->{find}->( 'user_code', 'BCDFGHJK' ), 'the cleared user_code no longer finds the row' );
    ok(
      eval { $store->{insert}->( $self->row( hash => 'airlock-test-5' ) ); 1 },
      'and the user_code is free for a new row'
    ) or diag $@;
    ok( $store->{update}->( 'airlock-test-1', 'approved', { state => 'redeemed' } ), 'first redeem: applied' );
    ok( !$store->{update}->( 'airlock-test-1', 'approved', { state => 'redeemed' } ), 'second redeem: refused' );
  };

  subtest 'purge' => sub {
    plan skip_all => 'store has no purge' unless ref $store->{purge} eq 'CODE';
    $store->{insert}->( $self->row( hash => 'airlock-test-6', user_code => 'CCCCDDDD', expires => 5000 ) );
    my $removed = $store->{purge}->(1601);
    is( $removed, 4, 'purge reports how many rows it removed' );
    ok( !$store->{find}->( 'hash', 'airlock-test-'.$_ ), 'row '.$_.' is gone' ) for 1, 3, 4, 5;
    ok( $store->{find}->( 'hash', 'airlock-test-6' ), 'the row that has not expired stays' );
    is( $store->{purge}->(1601), 0, 'a second purge removes nothing' );
    is( $store->{purge}->(5001), 1, 'and the last row goes once it has expired' );
  };

  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Airlock::Test::Store - Contract tests for an Airlock store

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Test::More;
    use Airlock::Test::Store;

    Airlock::Test::Store->new( store => {
      insert => sub { ... },
      find   => sub { ... },
      update => sub { ... },
      purge  => sub { ... },
    } )->run;

    done_testing;

=head1 DESCRIPTION

Whoever writes the four store subs for L<Airlock> runs this suite against them.
It checks what Airlock relies on: rows come back as they went in, a secret or a
user code is unique, C<update> only fires from the expected state and adds
where it is given a reference to a number, and C<purge>
removes what has expired and nothing else.

The suite inserts rows whose C<hash> starts with C<airlock-test->. Run it against
an empty table.

=head2 store

Required. The hash of coderefs under test: C<insert>, C<find>, C<update> and,
if the store has one, C<purge>.

=head2 row

    my $row = $suite->row( hash => 'airlock-test-2', user_code => undef );

A complete row with every field Airlock writes, for use in own tests.

=head2 run

    $suite->run;

Runs the contract as subtests of the calling test file.

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
