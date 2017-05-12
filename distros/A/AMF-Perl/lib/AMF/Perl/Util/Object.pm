package AMF::Perl::Util::Object;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

=head1 NAME 

    AMF::Perl::Object
    Translated from PHP Remoting v. 0.5b from the -PHP project.        

=head1 DESCRIPTION    

    Package used for building and retreiving  header and body information

=head1 CHANGES

=head2 Wed Apr 14 11:06:28 EDT 2004

=item Saving column types in the __columnTypes__ field for the recordset object.

Sun Jul 27 16:52:12 EDT 2003

=item Added the pseudo_query() method to create a recordset object wanted by Flash.

=cut

use strict;

# constructor
sub new
{
    my ($proto)=@_;
    my $self = {};
    bless $self, $proto;
    # init the headers and bodys arrays
    $self->{_headers} = [];
    $self->{_bodies} = [];
    return $self;
}

# adds a header to our object
# requires three arguments key, required, and value
sub addHeader
{
    my ($self, $k, $r, $v)=@_;
    my $header = {};
    $header->{"key"} = $k;
    $header->{"required"} = $r;
    $header->{"value"} = $v;
    push @{$self->{_headers}}, $header;
}

# returns the number of headers
sub numHeader
{
    my ($self)=@_;
    return scalar(@{$self->{_headers}});
}

sub getHeaderAt
{
    my ($self, $id)=@_;
    $id=0 unless $id;
    return $self->{_headers}->[$id];
}

# adds a body to our bodys object
# requires three arguments target, response, and value
sub addBody
{
    my ($self, $t, $r, $v, $ty)=@_;
    $ty="unknown" unless $ty;
    my $body = {};
    $body->{"target"} = $t;
    $body->{"response"} = $r;
    $body->{"value"} = $v;
    $body->{"type"} = $ty;
    push @{$self->{_bodies}}, $body;
}
# returns the number of body elements
sub numBody
{
    my ($self)=@_;
    return scalar(@{$self->{_bodies}});
}
# returns the body element at a specific index
sub getBodyAt
{
    my ($self, $id)=@_;
    $id=0 unless $id;
    return $self->{_bodies}->[$id];
}

sub pseudo_query
{
    my ($self, $columnNames, $data, $columnTypes) = @_;

    my $result = new AMF::Perl::Util::Object;
    # create the serverInfo array
    $result->{"serverInfo"} = {};

# create an initialData array
    my (@initialData, @columnNames);
    $result->{serverInfo}->{initialData} = $data;
    $result->{serverInfo}->{columnNames} = $columnNames;
    $result->{serverInfo}->{totalCount}= scalar @$data;

    # create the id field --> i think this is used for pageable recordsets
    $result->{"serverInfo"}->{"id"} = "AMF::Perl";
    $result->{"serverInfo"}->{"cursor"} = 1; # maybe the current record ????
    $result->{"serverInfo"}->{"serviceName"} = "doStuff"; # in CF this is PageAbleResult not here
    # versioning
    $result->{"serverInfo"}->{"version"} = 1;

    $result->{_explicitType}='RecordSet';

    $result->{__columnTypes__}=$columnTypes;

    return $result;
}

1;
