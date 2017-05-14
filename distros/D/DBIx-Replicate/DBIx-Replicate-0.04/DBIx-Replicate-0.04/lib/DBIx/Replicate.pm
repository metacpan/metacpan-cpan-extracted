# $Id: Replicate.pm 22870 2008-11-06 16:06:55Z kazuho $

package DBIx::Replicate;
use strict;
use warnings;
use Carp::Clan;
use DBI;
use DBIx::Replicate::Node;
use UNIVERSAL::require;
use Exporter 'import';
use base qw(Class::Accessor::Fast);

our %EXPORT_TAGS = (
    'all' => [ qw/dbix_replicate/ ],
);
our @EXPORT_OK = map { @{$EXPORT_TAGS{$_}} } qw/all/;
our $VERSION = '0.04';

__PACKAGE__->mk_accessors($_) for qw(src dest columns block extra_cond limit_cond strategy);

sub new
{
    my $class = shift;
    my $args  = shift || {};

    if (! $args->{strategy}) {
        $args->{strategy_class} ||= 'DBIx::Replicate::Strategy::PK';
    }

    if ( my $strategy_class = $args->{strategy_class}) {
        my $strategy_args = $args->{strategy_args} || {};
        $strategy_class->require or die;
        $args->{strategy} = $strategy_class->new($strategy_args);
    }

    foreach my $p (qw/src dest columns strategy/) {
        croak "required parameter $p is missing\n"
            unless $args->{$p};
    }
    $args->{block} ||= 1000;

    my $self  = $class->SUPER::new({
        strategy   => $args->{strategy},
        columns    => $args->{columns},
        block      => $args->{block},
        src        => $args->{src},
        dest       => $args->{dest},
        extra_cond => $args->{extra_cond},
        limit_cond => $args->{limit_cond},
    });
        
    return $self;
}

sub dbix_replicate {
    my $args = shift;

    $args = { %$args };

    foreach my $p (qw/src_table src_conn dest_table dest_conn columns/) {
        croak "required parameter $p is missing\n"
            unless $args->{$p};
    }

    my $src = DBIx::Replicate::Node->new( {
        table => delete $args->{src_table},
        conn  => delete $args->{src_conn},
    } );
    my $dest = DBIx::Replicate::Node->new( {
        table => delete $args->{dest_table},
        conn  => delete $args->{dest_conn}
    });

    if (! $args->{strategy} && ! $args->{strategy_class}) {
        if ($args->{copy_by}) {
            $args->{strategy_class} ||= 'DBIx::Replicate::Strategy::CopyBy';
        } else {
            $args->{strategy_class} ||= 'DBIx::Replicate::Strategy::PK';
        }
    }

    my %args = (
        src            => $src,
        dest           => $dest,
        columns        => delete $args->{columns},
        block          => delete $args->{block},
        extra_cond     => delete $args->{extra_cond},
        limit_cond     => delete $args->{limit_cond},
        strategy       => delete $args->{strategy},
        strategy_class => delete $args->{strategy_class},
        strategy_args  => delete $args->{strategy_args},
    );

    my $dr = DBIx::Replicate->new( \%args );
    $dr->replicate($args);
}

sub replicate
{
    my ($self, $args) = @_;

    $self->strategy->replicate( $self, $args );
}


1;
__END__
=head1 NAME

DBIx::Replicate - Synchornizes an SQL table to anther table

=head1 SYNOPSIS

  use DBIx::Replicate qw/dbix_replicate/;
  
  # incrementally copy table to other database (copy by each zipcode)
  dbix_replicate({
    src_conn     => $src_dbh,
    src_table    => 'tbl',
    dest_conn    => $dest_dbh,
    dest_table   => 'tbl',
    copy_by      => [ qw/zipcode/ ],
    load         => 0.5,
  });
  
  # incrementally extract (by every 1000 rows) people younger than 20 years old
  dbix_replicate({
    src_conn     => $dbh,
    src_table    => 'all_people',
    dst_conn     => $dbh,
    dest_table   => 'young_people',
    primary_keys => [ qw/id/ ],
    columns      => [ qw/id name age/ ],
    block        => 1000,
    extra_cond   => 'age<20',
    load         => 0.1,
  });


  # OO interface
  my $dr = DBIx::Replicate->new(
    src => DBIx::Replicate::Node->new(...)
    dest => DBIx::Replicate::Node->new(...)
    strategy => DBIx::Replicate::Strategy::PK->new()
  );
  $dr->replicate();
  
=head1 DESCRIPTION

DBIx::Replicate is a perl module that incrementally copies SQL tables using C<DBI> connections.  The granuality and speed of the copy can be controlled.

=head1 FUNCTIONS

=head2 dbi_replicate

A functional interface of DBIx::Replicate.  Accepts following parameters through a hashref argument.

=head3 src_conn

C<DBI> connection to source database

=head3 src_table

name of the source table (mandatory)

=head3 dest_conn

C<DBI> connection to destination database (mandatory)

=head3 dest_table

name of the destination table (mandatory)

=head3 columns

an arrayref containing the name of columns to be copied (mandatory)

=head3 extra_cond

sql expression to filter rows to be copied.  Only the rows that match the condition will be copied.  Rows that do not match the condition will be removed from the destination table. (optional)

=head3 limit_cond

sql expression to limit replication to rows that match the condition.  Unlike C<extra_cond>, the rows that do not match the condition will be preserved. (optional)

=head3 load

load average of the copy operation (optional).  The value should be greater than 0 and less or equal to 1.

=head3 copy_by

optionally takes an arrayref of column names.  If given, C<DBIx::Replicate::Strategy::CopyBy> will be used for copying tables.  The strategy repeatedly copies a set of rows that contain identical values in the specified columns.

=head3 primary_key

optionally takes an arrayref of primary key column names.  If given, C<DBIx::Replicate::Strategy::PK> will be used for copying tables.  The strategy copies certain number of rows at once specified by parameter C<block>, in the order sorted by C<primary_key>.

=head3 block

used together with C<primary_key> to specify the number of rows copied at once

=head1 AUTHOR

Kazuho Oku

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Cybozu Labs, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
