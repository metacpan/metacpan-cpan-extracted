package Data::AnyXfer::From::DBIC;

use v5.16.3;

use Carp;
use Moo::Role;

use MooX::Types::MooseLike::Base qw(:all);
use DBIx::Class::ResultSet ();

with 'Data::AnyXfer::From::Iterator';

requires 'log';

=head1 NAME

Data::AnyXfer::From::DBIC - transfer from from DBIC sources

=head1 SYNOPSYS

  use Moo;
  use MooX::Types::MooseLike::Base qw(:all);


  extends 'Data::AnyXfer';
  with 'Data::AnyXfer::From::DBIC';

  use MyResultClass;

  has '+from_rs' => (
    default => sub { MyResultClass->resultset('MyTableName')  }
  );

=head1 DESCRIPTION

This role configures L<Data::AnyXfer> to use a
L<DBIx::Class::ResultSet> as a data source.

=cut

has 'from_rs' => (
    is       => 'ro',
    isa      => InstanceOf['DBIx::Class::ResultSet'],
    lazy     => 1,
    required => 1,
    default =>
        sub { shift->log->logdie("The from_rs attribute was not set") },
    handles => [qw/ result_source /],
);

has 'force_dbic_inflate' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

sub get_iterator {

    my $rs = $_[0]->from_rs;

    # check that resultset has some data to iterate over - this
    # should prevent empty iterations caused by an empty table or some
    # other glitch returning zero results. Please note there may still
    # be issues after this in the iteration phase which this check will
    # not catch?
    if ( $rs->count < 1 ) {
        croak sprintf 'ERROR: %s has a row count of 0', ref $rs;
    }


    unless ( $_[0]->force_dbic_inflate ) {
        $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    }
    return $rs;
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

