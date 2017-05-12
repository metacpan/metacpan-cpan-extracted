package CGI::Ex::Recipes::DBIx;

use strict;
use warnings;
use utf8;
use DBI;
use DBD::SQLite;
use SQL::Abstract;
use Carp qw(carp cluck croak);
use vars qw(@EXPORT_OK);
require Exporter;
use base qw(Exporter);
@EXPORT_OK = qw(
    dbh
    sql
    create_tables
    categories
    recipes
    
);
our $VERSION = '0.02';

sub dbh {
    my $self = shift;
    if (! $self->{'dbh'}) {
        
        my $file   = ($ENV{SITE_ROOT} || $self->base_dir_abs->[0] ) . '/' . $self->conf->{'db_file'}
                        || './data/recipes.sqlite';
        my $exists = -e $file;
        my $package =  $self->{'_package'} || 'somethingsligthlylessborring';
        $self->{'dbh'} = DBI->connect(
            "dbi:SQLite:dbname=$file", '', '', 
            {
                #'private_'. $package => $package , 
                RaiseError => 1,
            }
        );
        $self->create_tables if !$exists;
        warn 'New db connetion initiated!';
    }
    return $self->{'dbh'};
}


sub create_tables {
    my $self = shift;
    #TODO:move SQL in a file
    $self->dbh->do("CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
            -- pid: id of the category in which this row will be placed
        pid INTEGER NOT NULL,
            -- is_category: is this recipe a category or not
        is_category INTEGER NOT NULL DEFAULT 0,
            -- sortorder: id of the field after which this field will be showed
        sortorder INTEGER NOT NULL,
            -- title: title of the recipe
        title VARCHAR(100) NOT NULL,
            -- problem: short description of the problem which this recipe solves
        problem VARCHAR(255) NOT NULL,
            -- analysis: analysis of the problem (why it occured etc.)
        analysis TEXT NOT NULL,
            -- solution: provide one or several solutions 
        solution  TEXT NOT NULL,
            -- tstamp: last modification in unix timestamp format
        tstamp  INTEGER NOT NULL,
            -- date_added: creation date in unix timestamp format
        date_added INTEGER NOT NULL
    )");

$self->dbh->do("CREATE TABLE cache (
        id VARCHAR(32) PRIMARY KEY,
        value TEXT NOT NULL,
        tstamp  INTEGER NOT NULL,
        expires  INTEGER NOT NULL
    )");
}

sub sql {
    my $self = shift;
    if (! $self->{'sql'}) {
        $self->{'sql'} = SQL::Abstract->new;
    }
    return $self->{'sql'};
}

#Suitable for preparing a left menu in some view/template
sub categories {
    my $self   = shift;
    my $fields = shift || [qw(id pid is_category title)];
    my $where  = shift || {pid=>0};
    #make shure we want categories
    $where->{is_category} ||= 1;
    my $order  = shift || ['sortorder'];
    my ($s, @bind) = $self->sql->select('recipes',$fields,$where,$order);
    return $self->dbh->selectall_arrayref($s,{Slice => {} ,MaxRows=>1000,},@bind);
}

#note: this method is more general than categories. returns all recipes with given pid||0
sub recipes {
    my $self   = shift;
    my $fields = shift || '*';
    my $where  = shift || { pid => 0, id => { '!=', 0 } };
    my $order  = shift || ['sortorder'];
    my ($s, @bind) = $self->sql->select('recipes',$fields,$where,$order);
    return $self->dbh->selectall_arrayref($s,{Slice => {} ,MaxRows=>1000,},@bind);
}

1; # End of CGI::Ex::Recipes::DBIx

__END__

=head1 NAME

CGI::Ex::Recipes::DBIx - Our minimal model!

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    #in CGI::Ex::Recipes
    use CGI::Ex::Recipes::DBIx qw(dbh create_tables);
    #..then somewhere in the application
    my $recipes = $self->dbh->selectall_arrayref('select * from recipes',{ Slice => {}})
    #or in some template
    [% app.dbh.ping() %]

=head1 DESCRIPTION

This class does not use or tries to mimic, or be like any of the powerfull objects-relational mappers
on CPAN. It is here just to encourage you to go and use whatever you wish.
If you look at the code, you will see how, if you want something more, you have 
to write more mixture of SQL and perl. And this is just one of the motivations of various DBIx* modules to exist.

=head1 EXPORT_OK

=head2 dbh

Exports it to be used by the application and templates.
    
    my $recipes = $self->dbh->selectall_arrrayref('select * from recipes');

in templates
    
    [% app.dbh.selectall_arrrayref('select * from recipes') %]

=head2 create_tables

Creates the only table in the database. This method is executed only if the database is empty. on the very first connect. 

=head1 METHODS

=hed2 sql 

Returns the SQL::Abstract object foreach SQL generation

=head2 categories

Returns all records in the recipes table as arrays of hashes which are categories 
(can hold other recipes).

=head2 recipes

This method is more general than categories. returns all recipes with given pid||0.

=head1 AUTHOR

Красимир Беров, C<< <k.berov at gmail.com> >>

=head1 BUGS

Not known

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Ex::Recipes::DBIx

=head1 ACKNOWLEDGEMENTS

    Larry Wall - for Perl
    
    Paul Seamons - for all his modules and especially for CGI::Ex didtro
    
    Anyone which published anything on CPAN

=head1 COPYRIGHT & LICENSE

Copyright 2007 Красимир Беров, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

