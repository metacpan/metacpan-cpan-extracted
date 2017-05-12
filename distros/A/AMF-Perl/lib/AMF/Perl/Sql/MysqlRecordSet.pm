package AMF::Perl::Sql::MysqlRecordSet;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the AMF-PHP project (http://amfphp.sourceforge.net/)

=head1 NAME

    AMF::Perl::Sql::MysqlRecordSet

    Translated from PHP Remoting v. 0.5b from the -PHP project.

=head1 DESCRIPTION

    Encode the information returned by a Mysql query into the AMF RecordSet format.

=head1 CHANGES

=head2 Wed Apr 14 11:06:28 EDT 2004

=item Started taking column types from statement handle.

=head2 Sun Jul 27 16:50:28 EDT 2003

=item Moved the formation of the query object into Util::Object->pseudo_query().

=head2 Sun May 11 18:22:33 EDT 2003

=item Since Serializer now supports generic AMFObjects, made sure we conform.
We need to have the _explicitType attribute...

=head2 Sun Apr  6 14:24:00 2003

=item Created after AMF-PHP, but something is not working yet...

=cut

use strict;
use AMF::Perl::Util::Object;

sub new
{
	my ($proto, $dbh) = @_;
	my $self = {};
	bless $self, $proto;
	$self->dbh($dbh);
	return $self;
}

sub dbh
{
    my ($self, $val) = @_;
    $self->{dbh} = $val if $val;
    return $self->{dbh};
}

sub query
{
    my ($self, $queryText) = @_;

	my $sth = $self->dbh->prepare($queryText);
    $sth->execute();

    my @initialData;

	my $columnNames = $sth->{NAME};

	my $columnTypes = $sth->{TYPE};

    # grab all of the rows
	# There is a reason arrayref is not used - if it is, 
	#the pointer is reused and only the last element gets added, though many times.
    while (my @array = $sth->fetchrow_array) 
    {
        # add each row to the initial data array
        push @initialData, \@array;
    }	

    return AMF::Perl::Util::Object->pseudo_query($columnNames, \@initialData, $columnTypes);
}

1;
