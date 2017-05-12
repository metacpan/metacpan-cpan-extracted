package Bio::GenomeMap;
{
  $Bio::GenomeMap::VERSION = '0.03';
}
# ABSTRACT: Data structure store and query genomically indexed data efficiently using SQLite's R*Tree.

use strict;
use warnings;
use 5.010_000;
use autodie;    
use Carp qw/carp croak cluck/;
use Data::Dumper;
use DBI;
use Digest::SHA;
use File::stat;
use Moose;
use Storable qw/freeze thaw/;

# responsibility of this class: 
# create sqlite db if necessary. handle digest
# set up dbh
# set up statement handles

has sqlite_file => ( is => 'ro' );
has ro => (is => 'ro', default => 0);

has dbh                    => ( is => 'rw', init_arg => undef);
has sth_insert_rtree       => ( is => 'rw', init_arg => undef);
has sth_insert_data        => ( is => 'rw', init_arg => undef);
has sth_insert_sequence    => ( is => 'rw', init_arg => undef);
has sth_select_sequence    => ( is => 'rw', init_arg => undef);
has sth_select_seqid       => ( is => 'rw', init_arg => undef);
has sth_select_overlap     => ( is => 'rw', init_arg => undef);
has sth_select_surrounding => ( is => 'rw', init_arg => undef);
has sth_select_within      => ( is => 'rw', init_arg => undef);
has sth_select_all         => ( is => 'rw', init_arg => undef);
has sth_search_data        => ( is => 'rw', init_arg => undef);

sub BUILD{
    my ($self) = @_;
    my $sqlite = $self->sqlite_file // ':memory:';

    $self->dbh(DBI->connect("dbi:SQLite:dbname=$sqlite","","", {
                RaiseError => 1, 
                ReadOnly => $self->ro(),
                AutoCommit => 0}
        ));

    $self->dbh->do(q{PRAGMA automatic_index = OFF});
    $self->dbh->do(q{PRAGMA journal_mode = OFF});
    $self->dbh->do(q{PRAGMA cache_size = 80000});

    $self->dbh->do(q{ 
        create virtual table if not exists map using rtree_i32(
            id, 
            seqid1, 
            seqid2, 
            start, 
            end
        ); });
    $self->dbh->do(q{ 
        create table if not exists data (
            id integer primary key, 
            is_storable integer, 
            data
        ); });
    $self->dbh->do(q{ 
        create table if not exists sequence (
            id integer primary key, 
            name 
        ); });

    $self->sth_insert_rtree(
        $self->dbh->prepare(q{insert into map (seqid1, seqid2, start, end) values (?,?,?,?); })
    );
    $self->sth_insert_data(
        $self->dbh->prepare(q{insert into data (id, is_storable, data) values (last_insert_rowid(),?,?); })
    );
    $self->sth_insert_sequence(
        $self->dbh->prepare(q{insert into sequence (name) values (?); })
    );

    $self->sth_select_sequence(
        $self->dbh->prepare(q{select id from sequence where name = ?; })
    );

    $self->sth_select_seqid(
        $self->dbh->prepare(q{select name from sequence where id = ?; })
    );

    $self->sth_select_overlap(
        $self->dbh->prepare(
            q{
            select map.start, map.end, data.is_storable, data.data
            from data, map where 
            (data.id = map.id) 
                and 
            (? <= map.end and map.start <= ?)
                and 
            (map.seqid1 = ?) 
            order by map.start;
            }
        )
    );

    $self->sth_select_within(
        $self->dbh->prepare(
            q{
            select map.start, map.end, data.is_storable, data.data
            from data, map where 
            (data.id = map.id) 
                and 
            (? <= map.start and map.end <= ?)
                and 
            (map.seqid1 = ?) 
            order by map.start;
            }
        )
    );

    $self->sth_select_surrounding(
        $self->dbh->prepare(
            q{
            select map.start, map.end, data.is_storable, data.data
            from data, map where 
            (data.id = map.id) 
                and 
            (map.start <= ? and ? <= map.end)
                and 
            (map.seqid1 = ?) 
            order by map.start;
            }
        )
    );

    $self->sth_select_all(
        $self->dbh->prepare(
            q{
            select map.seqid1, map.start, map.end, data.is_storable, data.data
            from data, map
            where 
            data.id = map.id 
            order by map.seqid1, map.start
            ;
            }
        )
    );

    $self->sth_search_data(
        $self->dbh->prepare(
            q{
            select map.seqid1, map.start, map.end, data.is_storable, data.data
            from data, map
            where 
            data.data like ?
                and
            data.id = map.id 
            order by map.seqid1, map.start
            ;
            }
        )
    );
}

sub DEMOLISH{
    my $self = shift;
    # not sure about this
    if (defined $self->dbh){ 
        $self->dbh->commit;
        $self->dbh(undef);
    }
}


# seqid cache so that we don't have to get the sequence from db every single
# insert.  we also use cache to get id for SELECTION as well-- I couldn't
# figure out how to make the select statements to do 3 table joins using all
# indices... (I think the problem is that I'm using a dimension of the rtree as
# a foreign key (seqid1 and seqid2), 

has seqidcache => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[Str]',
    default   => sub { {} },
    handles   => {
        set_seqidcache     => 'set',
        get_seqidcache     => 'get',
        has_seqidcache     => 'exists',
    },
);
sub seqname_to_seqid{
    my ($self, $seqname) = @_;
    if ($self->has_seqidcache($seqname)){
        return $self->get_seqidcache($seqname);
    }
    else{
        my $select = $self->sth_select_sequence();
        $select->execute($seqname);
        if (my $row = $select->fetchrow_arrayref) {
            $self->set_seqidcache($seqname, $row->[0]);
            return $row->[0];
        }
        else{
            my $insert = $self->sth_insert_sequence();
            $insert->execute($seqname);
            my $row = $self->dbh->selectrow_arrayref('select last_insert_rowid();') or croak "couldn't get sequence insert last rowid";
            $self->set_seqidcache($seqname, $row->[0]);
            return $row->[0];
        }
    }
}

has seqnamecache => (
    traits    => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef[Str]',
    default   => sub { {} },
    handles   => {
        set_seqnamecache     => 'set',
        get_seqnamecache     => 'get',
        has_seqnamecache     => 'exists',
    },
);
sub seqid_to_seqname{
    my ($self, $seqid) = @_;
    if ($self->has_seqnamecache($seqid)){
        return $self->get_seqnamecache($seqid);
    }
    else{
        my $select = $self->sth_select_seqid();
        $select->execute($seqid);
        if (my $row = $select->fetchrow_arrayref) {
            $self->set_seqnamecache($seqid, $row->[0]);
            return $row->[0];
        }
        else{
            croak "no such seqid $seqid";
        }
    }

}

sub bulk_insert{
    my ($self, $sub) = @_;
    my $dbh              = $self->dbh;
    my $sth_insert_rtree = $self->sth_insert_rtree;
    my $sth_insert_data  = $self->sth_insert_data;

    my $counter = 1;
    my $inserter = sub{
        my ($seqname, $start, $end, $data) = @_;
        my $seqid = $self->seqname_to_seqid($seqname);

        $sth_insert_rtree->execute($seqid, $seqid, $start, $end);
        if (ref $data eq ''){
            $sth_insert_data->execute(0, $data);
        }
        else{
            $sth_insert_data->execute(1, freeze($data));
        }

        if (++$counter % 50_000 == 0){
            $dbh->commit;
        }
    };
    $sub->($inserter);
    $dbh->commit;
}

# this is a higher level insert function.  Commits every time so not efficient.
# use bulk_insert() instead.
sub insert{
    my ($self, $seqname, $start, $end, $data) = @_;
    my $seqid = $self->seqname_to_seqid($seqname);
    $self->sth_insert_rtree->execute($seqid, $seqid, $start, $end);
    if (ref $data eq ''){
        $self->sth_insert_data->execute(0, $data);
    }
    else{
        $self->sth_insert_data->execute(1, freeze($data));
    }
    $self->dbh->commit;
}

sub commit{
    my $self = shift;
    $self->dbh->commit;
}

# select

sub _select_iter{
    my ($sth, $seqid, $start, $end, $code) = @_;

    $sth->execute( $start, $end, $seqid);
    while (my $row = $sth->fetchrow_arrayref) {
        my ($s, $e, $is_storable, $data) = @$row;
        if ($is_storable){
            $code->($s, $e, thaw($data));
        }
        else{
            $code->($s, $e, $data);
        }
    }
}
sub iter_overlaps{
    my ($self, $seqname, $start, $end, $code) = @_;
    my $seqid = $self->seqname_to_seqid($seqname);
    _select_iter($self->sth_select_overlap, $seqid, $start, $end, $code);
}

sub iter_surrounding{
    my ($self, $seqname, $start, $end, $code) = @_;
    my $seqid = $self->seqname_to_seqid($seqname);
    _select_iter($self->sth_select_surrounding, $seqid, $start, $end, $code);
}
sub iter_within{
    my ($self, $seqname, $start, $end, $code) = @_;
    my $seqid = $self->seqname_to_seqid($seqname);
    _select_iter($self->sth_select_within, $seqid, $start, $end, $code);
}

sub iter_all{
    my ($self, $code) = @_;
    my $sth = $self->sth_select_all;
    $sth->execute();

    while (my $row = $sth->fetchrow_arrayref) {
        my ($seqid, $s, $e, $is_storable, $data) = @$row;
        my $seqname = $self->seqid_to_seqname($seqid);
        if ($is_storable){
            $code->($seqname, $s, $e, thaw($data));
        }
        else{
            $code->($seqname, $s, $e, $data);
        }
    }
}

# slurping

sub _slurp{
    my ($sth, $seqid, $start, $end) = @_;
    my @accum;
    _select_iter($sth, $seqid, $start, $end, sub{
            my ($start, $end, $data) = @_;
            push @accum, [$start, $end, $data]
        });
    return \@accum;
}

sub slurp_overlaps{
    my ($self, $seqname, $start, $end) = @_;
    my $seqid = $self->seqname_to_seqid($seqname);
    _slurp($self->sth_select_overlap, $seqid, $start, $end);
}

sub slurp_surrounding{
    my ($self, $seqname, $start, $end) = @_;
    my $seqid = $self->seqname_to_seqid($seqname);
    _slurp($self->sth_select_surrounding, $seqid, $start, $end);
}

sub slurp_within{
    my ($self, $seqname, $start, $end) = @_;
    my $seqid = $self->seqname_to_seqid($seqname);
    _slurp($self->sth_select_within, $seqid, $start, $end);
}

sub slurp_all{
    my ($self) = @_;
    my @accum;
    $self->iter_all(sub{
            my ($seq, $start, $end, $data) = @_;
            push @accum, [$seq, $start, $end, $data]
        });
    return \@accum;
}

sub sequences{
    my $self = shift;
    my $dbh = $self->dbh;

    my $select_sth = $dbh->prepare(q{
        select name from sequence order by name asc;
        });
    $select_sth->execute();

    my @accum;
    while (my $row = $select_sth->fetchrow_hashref) {
        push @accum, $row->{name};
    }
    return @accum;
}

sub search{
    my ($self, $query, $start, $limit) = @_;
    $query = '%' . $query . '%';
    my $sth = $self->sth_search_data();
    $sth->execute($query);

    my @accum;
    my $counter = 0;
    my $end = $start + $limit - 1;

    # select map.seqid1, map.start, map.end, data.is_storable, data.data
    while (my $row = $sth->fetchrow_arrayref) {
        my ($seqid, $s, $e, $sto, $data) = @$row;
        my $seqname = $self->seqid_to_seqname($seqid);
        if ($start <= $counter && $counter <= $end){
            push @accum, [$seqname, $s, $e, $data];
            $counter++;
        }
        last if ($counter > $end);
    }
    return @accum;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Bio::GenomeMap - Data structure store and query genomically indexed data efficiently using SQLite's R*Tree.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 my $gm = Bio::GenomeMap->new(sqlite_file => 'gm.sqlite3', ro => BOOL);

 $gm->bulk_insert(sub{
     my ($inserter) = @_;

     while (<ARGV>){ # get line
        # parse into seqid, start, end, data.
        chomp; 
        my ($seqid, $start, $end, $data) = split /\t/, $line;
        $inserter->($seqid, $start, $end, $data);
     }
 });

 $gm->iter_overlaps('chr1', 10000, 20000, sub {
    my ($start, $end, $data) = @_;
    ...
 });

=head1 METHODS

=head2 $gm->bulk_insert($code)

Main insertion method.  $code is called with a single argument, an $inserter
coderef, which itself should be called with a $seqid, $start coord, $end coord,
and $data.  Data can be either a scalar, or a more complicated perl structure,
which will be frozen with Storable (and thawed automatically when retrieved
with the iter_* and slurp_* methods.  This method is smart enough to commit to
the underlying database every-so-often (currently hardcoded to 50000
insertions/commit).

 $gm->bulk_insert(sub{
     my ($inserter) = @_;

     # iterate over file/whatever and call $inserter on the parsed data:
     while (...){ # get line
        # parse into seqid, start, end, data.
        $inserter->($seqid, $start, $end, $data);
     }
 });

=head2 $gm->iter_overlaps($seqid, $start, $end, $code)

Iterate over all entries on $seqid overlapping interval [$start, $end].  $code
is called for each matching entry with arguments $start, $end, and $data:

 $gm->iter_overlaps('chr1', 10000, 20000, sub {
    my ($start, $end, $data) = @_;
 });

=head2 $gm->iter_surrounding($seqid, $start, $end, $code)

Iterate over all entries on $seqid surrounding interval [$start, $end].  $code
is called for each matching entry with arguments $start, $end, and $data:

 $gm->iter_surrounding('chr1', 10000, 20000, sub {
    my ($start, $end, $data) = @_;
 });

=head2 $gm->iter_within($seqid, $start, $end, $code)

Iterate over all entries on $seqid within interval [$start, $end].  $code is
called for each matching entry with arguments $start, $end, and $data:

 $gm->iter_within('chr1', 10000, 20000, sub {
    my ($start, $end, $data) = @_;
 });

=head2 $gm->iter_all($code)

Iterate over everything.  $code is called for each entry with arguments $seq,
$start, $end, $data:

 $gm->iter_all(sub{
     my ($seq, $start, $end, $data) = @_;
 });

=head2 slurp_overlaps($seqid, $start, $end)

 $gm->slurp_overlaps('Chr1', 30000, 32000);

Returns array reference, each element of the form: [$start, $end, $data]

=head2 slurp_within($seqid, $start, $end)

 $gm->slurp_within('Chr1', 30000, 32000);

Returns array reference, each element of the form: [$start, $end, $data]

Returns arefs of [start, end, data]:

=head2 slurp_surrounding($seqid, $start, $end)

 $gm->slurp_surrounding('Chr1', 30000, 32000);

Returns array reference, each element of the form: [$start, $end, $data]

Returns arefs of [start, end, data]:

=head2 $gm->slurp_all()

Returns array reference of [seqid, start, end, data]:

 my $res = $gm->slurp_all();

=head2 $gm->search($search_term);

Search data column textually, returns list or [$seqid, $start, $end, $data].
Up to $limit results returned, starting from $start.

 my @results = $gm->search('chromatin');

=head1 AUTHOR

T. Nishimura <tnishimura@fastmail.jp>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by T. Nishimura.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
