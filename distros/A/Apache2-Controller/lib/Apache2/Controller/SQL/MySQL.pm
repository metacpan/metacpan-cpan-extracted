package Apache2::Controller::SQL::MySQL;

=head1 NAME

Apache2::Controller::SQL::MySQL - useful database methods for MySQL

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

 package UFP::SFC::Controller::Tools;
 use base qw( 
     Apache2::Controller 
     Apache2::Controller::SQL::MySQL
 );
 # ...

=head1 DESCRIPTION

Provides some useful methods for interacting with a MySQL database.

This isn't really standard or a necessary part of A2C, I just find it handy.

=head1 DEPRECATED

Don't depend on this.  I intend to remove it in a future
release because it is not relevant.

=head1 METHODS

=head2 insert_hash

 insert_hash( \%hashref )

Insert data into the database.  

 # http://sfc.ufp/tools/register_crew/enterprise?captain=kirk&sci=spock&med=mccoy
 sub register_crew {
     my ($self, $ship) = @_; 
     my $crew = $self->param();
     $self->insert_hash({
         table    => "crew_$ship",
         data     => $crew,
     });
     $self->print("Warp factor 5, engage.\n");
     return Apache2::Const::HTTP_OK;
 }

Requires a database handle be assigned to C<< $self->{dbh} >>.
See L<Apache2::Controller::DBI::Connector>.

Hashref argument supports these fields:

=over 4

=item table

The SQL table to insert into.

=item data

The hash ref of field data to insert.

=item on_dup_sql

Optional string of SQL for after 'ON DUPLICATE KEY UPDATE'.
Format it yourself.

=item on_dup_bind

Array ref of bind values for extra C<?> characters in C<on_dup_sql>.

=back

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';
use Apache2::Controller::X;

sub insert_hash {
    my ($self, $p) = @_;

    my ($table, $data, $on_dup_sql, $on_dup_bind) = @{$p}{qw(
         table   data   on_dup_sql   on_dup_bind
    )};

    my @bind = values %{$data};

    my $sql 
        = "INSERT INTO $table SET\n"
        . join(",\n", map {"    $_ = ".(ref $_ ? $_ : '?')} keys %{$data});

    if ($on_dup_sql) {
        $sql .= "\nON DUPLICATE KEY UPDATE\n$on_dup_sql\n";
        push @bind, @{$on_dup_bind} if $on_dup_bind;
    }

    my $dbh = $self->{dbh};
    my $id;
    eval {
        DEBUG("preparing handle for sql:\n$sql\n---\n");
        my $sth = $dbh->prepare_cached($sql);
        $sth->execute(@bind);
        ($id) = $dbh->selectrow_array(q{ SELECT LAST_INSERT_ID() });
    };
    if ($EVAL_ERROR) {
        a2cx message => "database error: $EVAL_ERROR",
            dump => { sql => $sql, bind => \@bind, };
    }
    return $id;
}

=head1 SEE ALSO

L<Apache2::Controller::DBI::Connector>

L<Apache2::Controller>

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)- formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut

1;

