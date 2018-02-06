package DBIx::Core::Handle::ReturnValue;

use strict;
use warnings;

use parent qw(Dancer::Plugin::Database::Core::Handle);

our $VERSION = '0.01';

=head1 NAME
 
DBIx::Core::Handle::ReturnValue - subclassed DBI connection handle
 
=head1 DESCRIPTION
 
Subclassed DBI connection handle with added convenience features. In addition
to the features added by Dancer::Plugin::Database::Core::Handle, this module 
adds a return value to C<quick_insert> if requested.
 
 
=head1 SYNOPSIS

Set this Handle in you app config:


    plugins:
        Database:
            driver: 'Pg'
            database: 'postgres'
            host: '172.17.0.3'
            port: 5432
            username: 'postgres'
            password: 'pwd'
            dbi_params:
                RaiseError: 1
                AutoCommit: 1
            log_queries: 1
            handle_class: 'DBIx::Core::Handle::ReturnValue'



  # in your Dancer app:
  my $id = database->quick_insert($tablename, \%data, { last_insert_id => [ ... ] });
 
  my $uuid = database->quick_insert('mytable', { foo => 'Bar', baz => 5 }, { returning => 'entry_uuid' });


=head1 Added features
 
A C<DBIx::Core::Handle::ReturnValue> object is a subclassed L<DBI::db> L<DBI>
database handle, with the following added convenience methods in addition to 
those added by Dancer::Plugin::Database::Core::Handle:
 
=over 4
 
=item quick_insert
 
  database->quick_insert('mytable', { foo => 'Bar', baz => 5 }, { returning => 'id' });
 
This is a PostgreSQL-specific functionality which is very flexible and easy. It is
especially useful when you use UUIDs as primary keys which are not returned by the
normal last_insert_id functionality.
 
  database->quick_insert('mytable', { foo => 'Bar', baz => 5 }, { last_insert_id => [ .. ] });

The C<last_insert_id> variant calls the DBI method C<last_insert_id> with the parameters 
given in the array ref above. It depends on your database driver what needs to be filled 
in there.

If no third parameter is given, the call acts like defined by 
Dancer::Plugin::Database::Core::Handle 

=back

=cut

sub quick_insert {
    my ($self, $table_name, $data, $options) = @_;
    my $type = 'INSERT';
    if (ref $options ne 'HASH' or (!exists $options->{returning} and !exists $options->{last_insert_id})) {
        return $self->_quick_query($type, $table_name, $data);
    }

    my ($sql, @bind_params) = $self->_generate_sql(
        $type, $table_name, $data
    );

    $sql .= ' RETURNING '.$options->{returning} if exists $options->{returning};

    # this is copied from Dancer::Plugin::Database::Core::Handle::_quick_query:
    if ($self->{private_dancer_plugin_database}{log_queries}) {
        $self->{private_dancer_plugin_database}{logger}->(debug =>
            "Executing $type query $sql with params " . join ',',
            map {
                defined $_ ?
                $_ =~ /^[[:ascii:]]+$/ ?
                    length $_ > 50 ? substr($_, 0, 47) . '...' : $_
                : "[non-ASCII data not logged]" : 'undef'
            } @bind_params
        );
    }

    return $self->selectrow_arrayref($sql, undef, @bind_params)->[0] if exists $options->{returning};

    $self->do($sql, undef, @bind_params);
    return $self->last_insert_id(@{ $options->{last_insert_id} });
}

1;
__END__

=head1 SUPPORT
 
Open an issue or Pull Request on GitHub: L<https://github.com/sonntagd/DBIx-Core-Handle-ReturnValue>.
 
=head1 AUTHOR
 
Dominic Sonntag <dominic@s5g.de>
 
=head1 SEE ALSO
 
L<Dancer::Plugin::Database>, Dancer::Plugin::Database::Core::Handle
and L<Dancer2::Plugin::Database>
 
=head1 LICENSE AND COPYRIGHT
 
Copyright 2018 Dominic Sonntag.
 
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:
 
L<http://www.perlfoundation.org/artistic_license_2_0>
 
Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.
 
If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.
 
This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
 
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, er to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.
 
Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

