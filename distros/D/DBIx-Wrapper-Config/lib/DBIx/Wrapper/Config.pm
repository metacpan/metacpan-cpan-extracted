# Creation date: 2005-10-23 19:43:33
# Authors: don
#
# Copyright (c) 2005 Don Owens <don@regexguy.com>.  All rights reserved.

# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.  See perlartistic.

# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.

=pod

=head1 NAME

 DBIx::Wrapper::Config -  Config Module for DBIx::Wrapper

=head1 SYNOPSIS

 use DBIx::Wrapper::Config;

 my $dbh = DBIx::Wrapper::Config->connect($db_key, $conf_path, \%dbix_wrapper_attrs);

=head1 DESCRIPTION

 This module allows you to create a configuration file in XML
 specifying information required to connect to databases using
 DBIx::Wrapper.  This way you can keep your database connection
 specifications in one place.  Each "db" element specifies a
 key/name for the database connection, which should be passed as
 the $db_key argument to connect() in order to connect to that
 database.  The "db" element's children specify the dsn,
 authentication, and attribute information.

    <?xml version="1.0" encoding="iso-8859-1"?>
    <config>
      <db name="test_db_key">
        <dsn>dbi:mysql:database=test_db;host=example.com;port=3306</dsn>

        <!-- You can also use attributes to specify each part of the
             dsn separately.
         -->
        <!-- <dsn driver="mysql" database="test_db" host="example.com" port="3306"/> -->

        <user>test_user</user>
        <password>test_pwd</password>

        <!-- attributes to pass to DBIx::Wrapper (and ultimately to DBI) -->
        <attribute name="RaiseError" value="0"/>
        <attribute name="PrintError" value="1"/>
      </db>

      <db name="test_db_key2">
        <dsn driver="mysql" database="test_db" host="test.example.com" port="3306"/>

        <user>test_user</user>
        <password>test_pwd</password>

        <attribute name="RaiseError" value="0"/>
        <attribute name="PrintError" value="1"/>
      </db>

    </config>


=cut

use strict;
use warnings;

use 5.006_00;

package DBIx::Wrapper::Config;

our $VERSION = '0.02';

use DBIx::Wrapper;
use XML::Parser::Wrapper;

sub new {
    my $proto = shift;
        
    return $proto->connect(@_);
}

=pod

=head2 connect($db_key, $conf_path, \%dbix_wrapper_attrs)

 Return a DBIx::Wrapper object connected to the database
 specified by $db_key in the file at $conf_path.
 %dbix_wrapper_attrs is the optional 5th argument to
 DBIx::Wrapper's connect() method, specifying handlers, etc.

 The file specified by $conf_path should be in the format
 specified in the DESCRIPTION section of this document.

=cut
sub connect {
    my $self = shift;
    my $db_key = shift;
    my $conf_path = shift;
    my $wrapper_attrs = shift;

    return unless $db_key;

    my $conf = $self->_read_conf($conf_path);
    unless ($conf and %$conf) {
        die "\n\nread conf failed";
        return;
    }

    my $conf_entry = $conf->{$db_key};
        
    unless ($conf_entry) {
        die "no conf entry";
    }

    return DBIx::Wrapper->connect($conf_entry->{dsn}, $conf_entry->{user},
                                  $conf_entry->{password}, $conf_entry->{attributes},
                                  $wrapper_attrs);
}

sub _read_conf {
    my $self = shift;
    my $conf_path = shift;

    unless (defined($conf_path) and $conf_path ne '') {
        $conf_path = '/etc/dbix.conf.xml';
    }

    return unless -r $conf_path;

    my $root = XML::Parser::Wrapper->new({ file => $conf_path });
    unless ($root->name eq 'config') {
        # bad format
        return;
    }

    my $dbs = {};
    my $db_tags = $root->kids('db');
    return unless $db_tags and @$db_tags;

    foreach my $db_element (@$db_tags) {
        my $name = $db_element->attr('name');
        next unless defined $name;

        my $dsn_element = $db_element->kid('dsn');
        next unless $dsn_element;

        my $dsn;
        my $dsn_attrs = $dsn_element->attrs;
        if ($dsn_attrs and %$dsn_attrs) {
            my $driver = $dsn_attrs->{driver};
#             unless (defined($driver)) {
#                 $driver = 'mysql';
#             }
            my @keys = sort grep { $_ ne 'driver' } keys %$dsn_attrs;
            
            $dsn = "dbi:$driver:"
                . join(';', map { "$_=$dsn_attrs->{$_}" } @keys);
        }
        else {
            $dsn = $dsn_element->text;
        }

        my $this_db = { dsn => $dsn };
        $dbs->{$name} = $this_db;
        $this_db->{user} = $db_element->kid('user')->text;
        $this_db->{password} = $db_element->kid('password')->text;

        my $attributes = {};
        $this_db->{attributes} = $attributes;
        my $attribute_list = $db_element->kids('attribute');
        if ($attribute_list and @$attribute_list) {
            foreach my $attribute_element (@$attribute_list) {
                $attributes->{$attribute_element->attr('name')}
                    = $attribute_element->attr('value');
            }
        }
    }

    return $dbs;
}

=pod

=head1 EXAMPLES


=head1 DEPENDENCIES

DBIx::Wrapper, XML::Parser::Wrapper

=head1 AUTHOR

Don Owens <don@regexguy.com>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005 Don Owens <don@regexguy.com>.  All rights reserved.

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See perlartistic.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

=head1 SEE ALSO

 DBIx::Wrapper, DBI

=head1 VERSION

 0.02

=cut

1;

# Local Variables: #
# mode: perl #
# tab-width: 4 #
# indent-tabs-mode: nil #
# cperl-indent-level: 4 #
# perl-indent-level: 4 #
# End: #
# vim:set ai si et sta ts=4 sw=4 sts=4:
