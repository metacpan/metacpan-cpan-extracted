package DBIx::Class::Schema::PgLog;

use base qw/DBIx::Class::Schema/;

use strict;
use warnings;

use Class::C3::Componentised ();
use DBIx::Class::Schema::PgLog::Structure;
use Scalar::Util 'blessed';

__PACKAGE__->mk_classdata('pg_log_connection');
__PACKAGE__->mk_classdata('pg_log_schema');
__PACKAGE__->mk_classdata('pg_log_schema_template');
__PACKAGE__->mk_classdata('pg_log_storage_type');

=head1 NAME

DBIx::Class::Schema::PgLog - Schema PgLog Module 

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Perhaps a little code snippet.

    use DBIx::Class::Schema::PgLog;

    my $foo = DBIx::Class::Schema::PgLog->new();
    ...

=head1 DBIx::Class OVERRIDDEN METHODS

=head2 connection

Overrides the DBIx::Class connection method to create an PgLog schema.

=cut

sub connection {
    my $self = shift;

    my $schema = $self->next::method(@_);

    my $pg_log_schema = ( ref $self || $self )
        ->find_or_create_pg_log_schema_template->clone;

    if ( $self->pg_log_connection ) {
        $pg_log_schema->storage_type( $self->pg_log_storage_type )
            if $self->pg_log_storage_type;
        $pg_log_schema->connection( @{ $self->pg_log_connection } );
    }
    else {
        $pg_log_schema->storage( $schema->storage );
    }

    $self->pg_log_schema($pg_log_schema);

    $self->pg_log_schema->storage->disconnect();

    return $schema;
}

=head2 txn_do

Wraps the DBIx::Class txn_do method with a new logset whenever required.

=cut
sub txn_do {
    my ( $self, $user_code, @args ) = @_;

    my $pg_log_schema = $self->pg_log_schema;

    my $code = $user_code;

    my $logset_data = $args[0];

    my $current_logset = $pg_log_schema->_current_logset;
    if ( !$current_logset ) {
        my $current_logset_ref
            = $pg_log_schema->_current_logset_container;

        unless ($current_logset_ref) {
            $current_logset_ref = {};
            $pg_log_schema->_current_logset_container(
                $current_logset_ref);
        }

        $code = sub {
            # creates local variables in the transaction scope to store
            # the changset args, and the logset id
            local $current_logset_ref->{args}      = $args[0];
            local $current_logset_ref->{logset} = '';
            $user_code->(@_);
        };
    }

    if ( $pg_log_schema->storage != $self->storage ) {
        my $inner_code = $code;
        $code = sub { $pg_log_schema->txn_do( $inner_code, @_ ) };
    }

    return $self->next::method( $code, @args );
}

=head1 HELPER METHODS

=head2 pg_log_sources

returns the list of sourcenames which have DBIx::Class::PgLog loaded

=cut

sub pg_log_sources{
    my $self = shift;
    grep { $self->class($_)->isa("DBIx::Class::PgLog") }
        $self->sources;
}

=head2 pg_log_source

=over 

=item Arguments: $source_name

=back

Like L<DBIx::Class::Schema/source>, but returns 0 if the resulting source does not have
PgLog loaded

=cut

sub pg_log_source {
    my $source = shift->source(@_);

    return $source if $source && $source->isa("DBIx::Class::PgLog");
    return 0;
}

=head2 find_or_create_pg_log_schema_template

Finds or creates a new schema object using the PgLog tables.

=cut
sub find_or_create_pg_log_schema_template {
    my $self = shift;

    my $schema = $self->pg_log_schema_template;

    return $schema if $schema;

    my $c = blessed($self) || $self;

    my $class = "${c}::_PGLOG";

    Class::C3::Componentised->inject_base( $class,
        'DBIx::Class::Schema::PgLog::Structure' );

    $schema = $self->pg_log_schema_template(
        $class->compose_namespace( $c . '::PgLog' ) );

    my $prefix = 'PgLog';
    foreach my $pg_log_table (
        qw< Log LogSet>)
    {
        my $class = blessed($schema) . "::$pg_log_table";

        Class::C3::Componentised->inject_base( $class,
            "DBIx::Class::Schema::PgLog::Structure::$pg_log_table" );

        $schema->register_class( $prefix . $pg_log_table, $class );

    }

    return $schema;
}

=head1 AUTHOR

Sheeju Alex, C<< <sheeju at exceleron.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-pglog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-PgLog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Schema::PgLog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-PgLog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-PgLog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-PgLog>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-PgLog/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sheeju Alex.

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
patent license to make, have made, use, offer to sell, sell, import and
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


=cut

1; # End of DBIx::Class::Schema::PgLog
