package DBIx::Simple::Inject;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.04';
use parent 'DBI';

package DBIx::Simple::Inject::db;
use strict;
our @ISA = qw(DBI::db);

use Class::Load;
use DBIx::Simple;
use Scalar::Util qw/weaken/;

sub simple {
    my ($dbh) = @_;
    $dbh->{private_dbixsimple_object} ||= do {
        my $dbis = DBIx::Simple->connect($dbh);
        weaken($dbis->{dbh});
        
        for my $k (keys %{ $dbh->{private_dbixsimple} || {} }) {
            my $v = $dbh->{private_dbixsimple}{$k};
            # lvalue method
            $dbis->$k = ref $v eq 'CODE' ? $v->($dbh)
                      : $k eq 'abstract' ? _abstract($dbis->{dbh}, $v) : $v;
        }
        
        $dbis;
    };
}

sub _abstract {
    my ($dbh, $class) = @_;
    Class::Load::load_class($class);
    if ($class eq 'SQL::Abstract') {
        $class->new();
    } elsif ($class eq 'SQL::Abstract::Limit') {
        $class->new(limit_dialect => $dbh);
    } elsif ($class eq 'SQL::Maker') {
        $class->new(driver => $dbh->{Driver}{Name});
    } else {
        $class->new($dbh); # fallback
    }
}

{
    no strict 'refs';
    for my $method (
        qw(
            error
            query
            begin
            disconnect
            select insert update delete
            iquery
        ),
        # unnecessary begin_work(), commit(), rollback(), func() and last_insert_id()
        # there are just alias for DBI::db::*
    ) {
        *$method = sub {
            use strict 'refs';
            shift->simple->$method(@_);
        };
    }
    
    for my $property (
        qw(
            keep_statements
            lc_columns
            result_class
            abstract
        ),
    ) {
        *$property = sub {
            my ($self, $val) = @_;
            use strict 'refs';
            if ($val) {
                $self->simple->$property = $val;
            } else {
                $self->simple->$property;
            }
        };
    }
}

package DBIx::Simple::Inject::st;
our @ISA = qw(DBI::st);

1;

__END__

=encoding utf-8

=head1 NAME

DBIx::Simple::Inject - Injects DBIx::Simple methods into DBI

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect(
      'dbi:SQLite:dbname=:memory:', '', '', {
          RootClass          => 'DBIx::Simple::Inject',
          RaiseError         => 1,
          PrintError         => 0,
          ShowErrorStatement => 1,
      }
  );
  
  # of course can use dbh methods,
  $dbh->do('create table users (id, name)');
  
  # and also can use DBIx::Simple methods!
  my $row = $dbh->query('select * from users where id = ?', 123)->hash;
  my $res = $dbh->insert(users => {
      name => "John",
  });

=head1 DESCRIPTION

DBIx::Simple::Inject is-a DBI::db. This module injects DBIx::Simple power into DBI itself.
So you can use this module directly or via C<"RootClass">.

  use DBIx::Simple::Inject;
  my $dbh = DBIx::Simple::Inject->connect( ... );

or

  use DBI;
  my $dbh = DBI->connect( ..., {
      RootClass => 'DBIx::Simple::Inject',
  });

This is useful when you use several modules (like DBIx::Connector)
that take same as DBI's connect info.

=head1 ATTRIBUTE

=over 4

=item private_dbixsimple

You can set or access L<DBIx::Simple's property|DBIx::Simple/Object_properties>
using C<"private_dbixsimple"> attribute.

  my $db = DBI->connect(
      'dbi:...',
      'user',
      'pass',
      {
          RootClass  => 'DBIx::Simple::Inject',
          RaiseError => 1,
          private_dbixsimple => {
              lc_columns      => 0,
              keep_statements => 20,
              result_class    => 'MyApp::Result',
              abstract        => 'SQL::Maker',
          },
      },
  );

=over 4

=item abstract

For convenience, C<abstract> can take some module names.
Supported module names are as follows:

  SQL::Abstract
  SQL::Abstract::Limit
  SQL::Maker

You can also set callback for your own modules as follows.

  my $db = DBI->connect(
      ...,
      {
          RootClass => 'DBIx::Simple::Inject',
          private_dbixsimple => {
              abstract => sub {
                  my $dbh = shift;
                  My::SQL::Generator->new(driver => $dbh->{Driver}{Name});
              },
          },
      },
  );

=back

=back

=head1 INJECT METHODS

You can use the following methods from L<DBIx::Simple> in addition to
all DBI database handle methods.

=over 4

=item C<< $dbh->query() >>, C<< $dbh->select() >>, C<< $dbh->insert() >>, C<< $dbh->update() >>,
C<< $dbh->delete() >>, C<< $dbh->iquery() >>, C<< $dbh->error() >>, C<< $dbh->begin() >>

Note: Besides these, DBIx::Simple provides C<commit()>, C<rollback()> and C<func()>, etc.
DBI database handles already provides these methods.

=item C<< $dbh->lc_columns() >>, C<< $dbh->keep_statements() >>, C<< $dbh->result_class() >>, C<< $dbh->abstract() >>

These are accessor methods to DBIx::Simple properties.

=back

=head1 ANOTHER DBIx ?

Yes.

OK I know that DBIx namespace is hodgepodge. Several authors should know that
DBI itself has a lot of useful features already (like "Callbacks").

However, if you don't want ORM but want result set object (blessed result),
I think DBIx::Simple makes great success. The module has nice API.

Some useful CPAN modules (that knows DBI's true power) takes C<$dbh>
or same arguments as C<< DBI->connect() >>. That's why I made this module.

=head1 SEE ALSO

L<DBIx::Simple>, L<DBI>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
