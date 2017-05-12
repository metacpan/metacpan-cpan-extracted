package DBIx::Pager;
# $Id: Pager.pm,v 1.2 2002/08/06 02:06:14 ikechin Exp $
use strict;
use Carp;
use vars qw($VERSION);
use base qw(Class::Accessor);
use POSIX ();

__PACKAGE__->mk_accessors(qw(total limit offset));

$VERSION = '0.02';

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {
	dsn => $args{dsn},
	user => $args{user},
	password => $args{password},
	dbh => $args{dbh},
	table => $args{table},
	offset => $args{offset} || 0,
	limit => $args{limit},
	where_clause => $args{where_clause},
    }, $class;
    if ($self->{dsn}) {
	eval " require DBI; ";
	$self->{dbh} = DBI->connect(
	    $self->{dsn}, $self->{user}, $self->{password},
	    {
		RaiseError => 1,
		PrintError => 1
	    }
	) or die $DBI::errstr;
    }
    $self->_load_page_info;
    $self;
}

sub _load_page_info {
    my $self = shift;
    my $dbh = $self->{dbh};
    my $table = $self->{table};
    my $sth;
    if (ref $self->{where_clause} eq 'ARRAY') {
	my @args = @{$self->{where_clause}};
	my $where = shift @args;
	$sth = $dbh->prepare("SELECT COUNT(*) FROM $table $where");
	$sth->execute(@args)
    }
    else {
	my $where = $self->{where_clause} || "";
	$sth = $dbh->prepare("SELECT COUNT(*) FROM $table $where");
	$sth->execute;
    }
    my $count = $sth->fetchrow_arrayref->[0];
    $sth->finish;
    $dbh->disconnect;
    $self->{total} = $count;
}

sub has_next {
    my $self = shift;
    if ($self->{total} > $self->{offset} + $self->{limit}) {
	return 1;
    }
    return 0;
}

sub has_prev {
    my $self = shift;
    return $self->{offset} ? 1 : 0;
}

sub next_offset {
    my $self = shift;
    return $self->{offset} + $self->{limit};
}

sub prev_offset {
    my $self = shift;
    my $prev = $self->{offset} - $self->{limit};
}

sub page_count {
    my $self = shift;
    return POSIX::ceil($self->{total} / $self->{limit});
}

sub current_page {
    my $self = shift;
    return int($self->{offset} / $self->{limit}) + 1;
}

1;
__END__

=head1 NAME

DBIx::Pager - SQL paging helper.

=head1 SYNOPSIS

  use DBIx::Pager;

  my $pager = DBIx::Pager->new(
       dsn => 'dbi:mysql:test',
       user => 'root',
       table => 'table',
       offset => 0,
       limit => 20
  );

  if($pager->has_next) {
      # ...
  }

=head1 DESCRIPTION

DBIx::Pager supports calculation about paging when SELECT a lot of data.
this module is suitable for Web application using MySQL and Template-Toolkit. 

=head1 METHODS

=over 4

=item $pager = DBIx::Pager->new(%args)

construct DBIx::Pager object. the optios are below.

=over 5

=item dsn 

DBI datasource.

=item user

DBI username

=item password

DBI password

=item dbh

connected database handle.

=item table

setup table name. (require)

=item limit

limit of data per page. (require)

=item offset

offset of page. (default 0)

=item where_clause

SQL where clause.

  
  my $pager = DBIx::Pager->new(
       dbh => $dbh
       table => 'table',
       offset => 0,
       limit => 20,
       where_clause => 'WHERE id < 1000'
  );
  
  # with place holder.
  my $pager = DBIx::Pager->new(
       dbh => $dbh
       table => 'table',
       offset => 0,
       limit => 20,
       where_clause => [ 'WHERE id < ?', $id ]
  );

=back

=item $total = $pager->total

total count of rows.

=item $pager->has_next

return true when pager has next pages.

=item $pager->has_prev

return true when pager has previous pages.

=item $pager->next_offset

return next offset.

=item $pager->prev_offset

return previous offset.

=item $pager->page_count

return total "page" count.

=item $page->current_page

reutrn current page number. first is 1.

=back

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::Page> L<DBI>

=cut
