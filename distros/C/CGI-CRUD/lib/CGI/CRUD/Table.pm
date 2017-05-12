# Table.pm
#
# $Id: Table.pm,v 1.3 2005/01/27 21:33:26 rsandberg Exp $
#

package CGI::CRUD::Table;

use strict;

use vars qw(%insert_tags %update_tags @ISA);

use DBIx::IO::Table;
use DBIx::IO::GenLib ();

@ISA = qw(DBIx::IO::Table);


%insert_tags = (
    CREATE_USER => q[defined($self->user()) ? $self->user() : 'UNKNOWN'],
    UPDATE_USER => q[defined($self->user()) ? $self->user() : 'UNKNOWN'],
    CREATE_DATE => 'DBIx::IO::GenLib::local_normal_sysdate()',
    LAST_UPDATE => 'DBIx::IO::GenLib::local_normal_sysdate()',
);

%update_tags = (
    UPDATE_USER => q[defined($self->user()) ? $self->user() : 'UNKNOWN'],
    LAST_UPDATE => 'DBIx::IO::GenLib::local_normal_sysdate()',
);

=pod

=head1 NAME

CGI::CRUD::Table - Convenient database triggers for a web front-end

=head1 DESCRIPTION

Subclass of DBIx::IO::Table convenient for CGI forms.
Provides database trigger-like functions to tag records with the authenticated operator ID and timestamp of last update/insertion.

Default column names that get tagged are:
    CREATE_USER
    UPDATE_USER
    CREATE_DATE
    LAST_UPDATE

so that any columns with these names in any table get automagically populated with their likely value.
These column names and the routines that populate them may be overridden by re-defining %CGI::CRUD::Table::insert_tags and %CGI::CRUD::Table::update_tags.

=cut


sub new
{
    my ($caller,$dbh,$user,$fetch_or_ins,$key_name,$table_name) = @_;
    my $self;
    $self = $caller->SUPER::new($dbh,$fetch_or_ins,$key_name,$table_name) || return $self;
    $self->{user} = $user;
    return $self;
}

sub user
{
    my $self = shift;
    return $self->{user};
}

sub insert
{
    my $self = shift;
    my $insert = shift() || {};
    my $types = $self->column_types();
    foreach my $tag (keys(%insert_tags))
    {
        next unless exists($types->{$tag});
        my $ins = eval($insert_tags{$tag});
        $insert->{$tag} = $ins;
    }
    return $self->SUPER::insert($insert,@_);
}

sub _prepare_update
{
    my $self = shift();
    my $upd = $self->SUPER::_prepare_update(@_);
    if (%$upd)
    {
        my $types = $self->column_types();
        foreach my $tag (keys(%update_tags))
        {
            next unless exists($types->{$tag});
            my $new_val = eval($update_tags{$tag});
            $self->_post_update($tag,$new_val,$upd) || return undef;
        }
    }
    return $upd;
}

sub _post_update
{
    my ($self,$field,$new_val,$upd) = @_;
    defined(eval("\$self->${field}(\$new_val)")) || ($self->{io}->_alert("Check routine failed for $field: $new_val"), return undef);
    defined(eval("\$self->__update__${field}(\$new_val)")) ||
        ($self->{io}->_alert("pre-update routine failed for $field: $new_val"), return undef);
    $upd->{$field} = $new_val;
    return 1;
}

1;

__END__

=head1 SEE ALSO

L<DBIx::IO>, L<DBIx::IO::Table>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2007 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

