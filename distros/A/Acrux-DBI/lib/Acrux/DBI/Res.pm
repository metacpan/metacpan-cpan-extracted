package Acrux::DBI::Res;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Acrux::DBI::Res - Results of your database queries

=head1 SYNOPSIS

    use Acrux::DBI::Res;

    my $res = Acrux::DBI::Res->new(sth => $sth);

    $res->collection->map(sub { $_->{foo} })->shuffle->join("\n")->say;

=head1 DESCRIPTION

Class to works with results of your database queries

=head2 new

    my $res = Acrux::DBI::Res->new( sth => $sth, dbi => $dbi );

Construct a new Acrux::DBI::Res object

=head1 ATTRIBUTES

This method implements the following attributes

=head2 dbi

    my $dbi = $res->dbi;
    $res = $res->dbi(Acrux::DBI->new);

L<Acrux::DBI> object these results belong to.

=head2 sth

    my $sth  = $res->sth;
    $res = $res->sth($sth);

L<Acrux::DBI> statement handle results are fetched from

=head1 METHODS

This class implements the following methods

=head2 affected_rows

    my $affected = $res->affected_rows;

Number of affected rows by the query. For example

    UPDATE testtable SET id = 1 WHERE id = 1

would return 1

=head2 array

    my $array = $res->array;

Fetch one row from L</"sth"> and return it as an array reference

=head2 arrays

    my $arrays = $res->arrays;

Fetch all rows from L</"sth"> and return them as an array of arrays

=head2 collection

    my $collection = $res->collection;

Fetch all rows from L</"sth"> and return them as a L<Mojo::Collection> object containing hash references

    # Process all rows at once
    say $res->hashes->reduce(sub { $a + $b->{money} }, 0);

=head2 collection_list

    my $collection_list = $res->collection_list;

Fetch all rows from L</"sth"> and return them as a L<Mojo::Collection> object containing array references

    # Process all rows at once
    say $res->collection_list->reduce(sub { $a + $b->[3] }, 0);

=head2 columns

    my $columns = $res->columns;

Return column names as an array reference

    # Names of all columns
    say for @{$res->columns};

=head2 err

    my $err = $res->err;

Error code received

=head2 errstr

    my $errstr = $res->errstr;

Error message received

=head2 finish

    $res->finish;

Indicate that you are finished with L</"sth"> and will not be fetching all the remaining rows

=head2 hash

    my $hash = $res->hash;

Fetch one row from L</"sth"> and return it as a hash reference

=head2 hashed_by

    my $hash = $res->hashed_by( $key_field );
    my $hash = $res->hashed_by( 'id' );

This method returns a reference to a hash containing a key for each distinct
value of the C<$key_field> column that was fetched.
For each key the corresponding value is a reference to a hash containing
all the selected columns and their values, as returned by C<fetchrow_hashref()>

For example:

    my $hash = $res->hashed_by( 'id' );

    # {
    #   1 => {
    #      'id'   => 1,
    #      'name' => 'foo'
    #   },
    #   2 => {
    #      'id'   => 2,
    #      'name' => 'bar'
    #   }
    # }

See L<DBI/fetchall_hashref> for details

=head2 hashes

    my $hashes = $res->hashes;

Fetch all rows from L</"sth"> and return them as an array containing hash references

=head2 last_insert_id

    my $last_id = $res->last_insert_id;

That value of C<AUTO_INCREMENT> column if executed query was C<INSERT> in a table with
C<AUTO_INCREMENT> column

=head2 more_results

    do {
      my $columns = $res->columns;
      my $arrays = $res->arrays;
    } while ($res->more_results);

Handle multiple results

=head2 rows

    my $num = $res->rows;

Number of rows

=head2 state

    my $state = $res->state;

Error state received

=head2 text

    my $text = $res->text;

Fetch all rows from L</"sth"> and turn them into a table with L<Mojo::Util/"tablify">.

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::mysql>, L<Mojo::Pg>, L<Mojo::DB::Connector>, L<CTK::DBI>, L<DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.01';

use Carp qw/croak/;
use Mojo::Collection;
use Mojo::JSON qw(from_json);
use Mojo::Util qw(tablify);

sub new {
    my $class = shift;
    my $args = scalar(@_) ? scalar(@_) > 1 ? {@_} : {%{$_[0]}} : {};
    my $sth = $args->{sth};
       croak 'Invalid STH' unless ref($sth);
    my $self  = bless {
            sth     => $sth,
            dbi     => undef,
            driver  => '',
            affected_rows => $args->{affected_rows} || 0,
        }, $class;
    $self->dbi($args->{dbi});
    return $self;
}

sub sth {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{sth} = shift;
        return $self;
    }
    return $self->{sth};
}
sub dbi {
    my $self = shift;
    if (scalar(@_) >= 1) {
        my $dbi = $self->{dbi} = shift;
        $self->{driver} = $dbi ? ($dbi->dbh->{Driver}{Name} || '') : '';
        return $self;
    }
    return $self->{dbi};
}
sub state { shift->sth->state }
sub err { shift->sth->err }
sub errstr { shift->sth->errstr }
sub finish { shift->sth->finish }

# Main Accessors
sub array { return shift->sth->fetchrow_arrayref() }
sub arrays { return shift->sth->fetchall_arrayref() }
sub collection_list { return Mojo::Collection->new(shift->sth->fetchall_arrayref()) }
sub columns { return shift->sth->{NAME} }
sub hash { return shift->sth->fetchrow_hashref() }
sub hashes { return shift->sth->fetchall_arrayref({}) }
sub collection { return Mojo::Collection->new(@{(shift->sth->fetchall_arrayref({}))}) }
sub rows { shift->sth->rows }
sub text { tablify shift->arrays }
sub affected_rows { shift->{affected_rows} }
sub more_results { shift->sth->more_results }
sub last_insert_id {
    my $self = shift;
    return $self->sth->last_insert_id() if $self->sth->can('last_insert_id');
    my $liid = sprintf('%s_insertid', $self->{driver});
    return $self->sth->{$liid};
}
sub hashed_by {
    my $self = shift;
    my $key_field = shift; # See keys (http://search.cpan.org/~timb/DBI-1.607/DBI.pm#fetchall_hashref)
    return unless defined($key_field);
    return $self->sth->fetchall_hashref($key_field)
}

sub DESTROY {
    my $self = shift;
    return unless my $sth = $self->{sth};
    $sth->finish;
}

1;

__END__
