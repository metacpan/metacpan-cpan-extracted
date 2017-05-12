package DBIx::Class::ElasticSync;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.06";



1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::ElasticSync - Helps keep your data in sync with elasticsearch


=head2 Description

DBIx::Class::ElasticSync is a Module to link your DBIx::Class Schema to elasticsearch faster.

It helps you, to denormalize your relational database schema to fit into the document orientated elasticsearch store

=head2 Warning

This repository is under development. API changes are possible at this point of time. We will create more documentation if we tested this in the wild.

=head2 TODO

=over

=item Add an Application Example

=item Complete the Docs

=back

=head2 Setting up your DBIx::Model

=head3 Adding role to your Schema Class

    with 'DBIx::Class::ElasticSync::Role::ElasticSchema';

In advanced you need to handle over your Schema the connection informations for Elasticsearch

    $schema->connect_elastic( { nodes => "localhost:9200" } );

=head3 Adding role to your Result Class

    with 'DBIx::Class::ElasticSync::Role::ElasticResult';

=head3 Building your own ElasticResultSet Classes

    extends 'ElasticSync::ResultSet';

=head3 Running your Application

DBIx::Class::ElasticSync::Role will hook into your insert, update and delete DBIx::Class::Row methods. If you change Data in your Database, it will be synced with the elasticsearch.

=head2 Credits

This module is based on Chris 'SchepFc3' Shepherd work, which you can find here:

    https://github.com/ShepFc3/ElasticDBIx

=head2 Authors

=over

=item Jens Gassmann  <jg@gassmann.it>
=item Patrick Kilter <pk@gassmann.it>

=back

=cut

