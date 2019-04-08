package DBIx::Class::Helper::SimpleStats;

# ABSTRACT: Simple grouping and aggregate functions for DBIx::Class

use v5.10.1;

use strict;
use warnings;

use base qw( DBIx::Class );

use Carp;
use List::Util 1.45 qw/ uniqstr /;
use Ref::Util qw/ is_plain_hashref is_ref /;

# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.1.2';



sub simple_stats {
    my ( $self, @args ) = @_;

    croak "No columns" unless @args;

    my @cols;
    my @funcs;

    my $me = $self->current_source_alias;

    my $alias = sub {
      my $ident = shift;
      $ident = "$me.$ident" unless $ident =~ /^(\w+)\./;
      return $ident;
    };

    foreach my $arg (@args) {

        if ( is_ref($arg) ) {

            if ( is_plain_hashref($arg) ) {

                my $as = delete $arg->{'-as'};
                my ( $func, $col ) = each %{$arg};

                $as //= "${col}_${func}";

                push @cols, $alias->($col);

                push @funcs, { $func => $alias->($col), -as => $as };

            }
            else {

                croak "Unsupported reference type: " . ref($arg);

            }

        }
        else {

            push @cols, $alias->($arg);

        }

    }

    unless (@funcs) {

        my $func = "count";
        my $col  = $cols[0];
        $col =~ s/^\w+\.// ;

        push @funcs, { $func => $alias->($col), -as => "${col}_${func}" };

    }

    my @names = map { delete $_->{'-as'} } @funcs;

    my @group = uniqstr @cols;

    return $self->search(
        undef,
        {
            group_by => \@group,
            select  => [ @group, @funcs ],
            as      => [ @group, @names ],
            order_by => \@group,
        }
    );

}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Helper::SimpleStats - Simple grouping and aggregate functions for DBIx::Class

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

In a resultset class:

  package My::Schema::ResultSet::Foo;

  use base 'DBIx::Class::ResultSet';

  __PACKAGE__->load_components('Helper::SimpleStats');

  ...

In code

  my @stats = $rs->simple_stats( 'name' )->all;

is roughly equivalent to

  my @stats = $rs->search_rs(
    undef,
    {
      select   => [qw/ name /, { count => 'name' }],
      as       => [qw/ name name_count /],
      group_by => [qw/ name /],
      order_by => [qw/ name /],
    }
  )->all;

=head1 DESCRIPTION

This is a simple helper method for L<DBIx::Class> resultsets to run
simple aggregate queries.

=head1 METHODS

=head2 C<simple_stats>

  my $stats_rs => $rs->simple_stats( @columns );

The simplest usage is to pass a single column name, and obtain a count
of rows for each value of that column.

However, you could specify multiple columns or functions, and optional
column names:

  $rs->simple_stats(
    { min => 'cost' },
    { max => 'cost' },
    { sum => 'cost',   -as => 'total_cost' },
    { count => 'cost', -as => 'num_purchases' },
  );

=head1 SEE ALSO

L<DBIx::Class>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/DBIx-Class-Helper-SimpleStats>
and may be cloned from L<git://github.com/robrwo/DBIx-Class-Helper-SimpleStats.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/DBIx-Class-Helper-SimpleStats/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
