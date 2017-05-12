package DBIx::Class::ProxyTable;
use strict;
use warnings;
use base 'DBIx::Class';
use Carp::Clan qw/^DBIx::Class/;
use UNIVERSAL::require;

our $VERSION = '0.02';
use DBIx::Class::ResultSet;

{
    package DBIx::Class::ResultSet;
    sub proxy {
        my ($self, $table) = @_;
        $self->_auto_create_table($table);
        $self->result_source->schema->source_registrations->{$self->result_source->source_name}->name($table);
        return $self; 
    }

    sub _auto_create_table {
        my ($self, $new_table) = @_;

        my $driver = $self->result_source->schema->storage->dbh->{Driver}->{Name};
        my $module = 'DBIx::Class::ProxyTable::AutoCreateTable::'. $driver;
        $module->use or die $@;
        my $sql = $module->_get_table($self, $new_table);
        eval { $self->result_source->schema->storage->dbh->do($sql) };
    }
}
1;

__END__
=head1 NAME

DBIx::Class::ProxyTable - without generating a schema

=head1 SYNOPSIS

    package Your::Schema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->load_classes(qw//);
     
    package Your::Schema::Log;
    use base 'DBIx::Class';
     
    __PACKAGE__->load_components(qw/ProxyTable Core/);
    __PACKAGE__->table('log');
    __PACKAGE__->add_columns(qw/ id body /);
    __PACKAGE__->set_primary_key('id');
     
    1;
     
    # in your script:
    my $rs = $schema->resultset('Log');
    $rs->proxy('log2')->create({id => 1, body => 'hoge'});
    # insert data for log2 table
    my $log2 = $rs->proxy('log2')->single({id => 1});

=head1 DESCRIPTION

The cause can treat a table becoming the base in DBIC without generating a schema.
and auto create target table.

=head1 METHOD

=head2 proxy

    # get Log's resultset
    my $rs = $schema->resultset('Log');
    # insert data to log2 table
    $rs->proxy('log2')->create({id => 1, body => 'bar'});

=head2 __auto_create_table

=head1 FIXME

now:
$schema->resultset('Log')->proxy('log2')->create({id => 1, body => 'hoge'});

but 'log2' does not do proxy.
Is this place better?

$schema->proxy('Log','log2')->create({id => 1, body => 'hoge'});

or

$schema->proxy('Log')->table('log2')->create({id => 1, body => 'hoge'});

or

$schema->resultset('Log')->proxy_to('log2')->create({id => 1, body => 'hoge'});

any more idea?

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Atsushi Kobayashi  C<< <nekokak __at__ gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Atsushi Kobayashi C<< <nekokak __at__ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

