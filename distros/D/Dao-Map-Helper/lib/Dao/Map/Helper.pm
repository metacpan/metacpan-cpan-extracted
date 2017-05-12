package Dao::Map::Helper;
#use warnings;
use strict;
use DBI;
use DBD::mysql;
use Error qw{:try};
use Getopt::Long;
use Pod::Usage;
use Carp;
our @ISA = qw(Exporter);
our @EXPORT = qw(
);

=head1 NAME

Dao::Map::Helper - Simplify the creation of DAO (Data Access Objects). Kind of a low level ORM, where you can still use SQL and then map the result set to the class objects.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Simplify the creation of Dao classes and the mapping between relational table and class.

    dao-map-helper --dsn=dbi:mysql:mydb:localhost:3306 --user=root --pwd=pwd --package=package

=head1 Description

You might have seen helper scripts which are part of Catalyst Devel framework.

The helper scripts create the inital structure based on which you can continue your work.

What does Dao::Map::Helper do?
The Dao::Map::Helper can be invoked via command line and inturn it will create .pm files that are also called Value Objects.
These are just class files with attributes in them.

Where do i use it?
Every time you fetch a result set from the database using DBI module like

    ...
    $sth = $dbh->prepare("select * from user");
    $sth->execute();
    while ($row = $sth->fetchrow_hashref() ) {
        push(@user_arry2,$row);
    }
    ...

Template toolkit file would look like:

    ...
    [% FOREACH user IN user_arry %]
        [% user.id %] : [% user.username %]
    [% END %]
    ...


With the above approach if the database layer changes then you would have to search every view where the column name is used and change it. Instead if you had a interface. A change in a single file is all that is needed. In the above approach since you are directly passing the database hash values the impact of a change is propogated across your website, making it hard to maintain.

The new approach would be


    ...
    $sth = $dbh->prepare("select * from user");
    $sth->execute();
    while ($row = $sth->fetchrow_hashref() ) {
        my $user_obj = web_app::Vo::UserVo->new($row);
        push(@user_arry,$user_obj);
    }
    ...


This way you get to create a mapping class that you can change if there is a change.

The mapping file looks like this:

    package MyApp::Vo::userVo;
    use strict;
    use warnings;
        sub new {
        shift;
        my($row) = @_;
        my $self = {};
        $self->{status}=$row->{status} || "";
        $self->{updated_by}=$row->{updated_by} || "";
        $self->{created_date}=$row->{created_date} || "";
        $self->{username}=$row->{username} || "";
        $self->{email}=$row->{email} || "";
        $self->{password}=$row->{password} || "";
        $self->{updated_date}=$row->{updated_date} || "";
        $self->{id}=$row->{id} || "";
        $self->{created_by}=$row->{created_by} || "";
        bless($self);
        return $self;
    }
    return 1;

So if the username in the database changes to 'user_name' you dont have to modify every template view where it is used. You just need to change this mapping file.
Also the mapping between the database and class attributes happens in this class. So it's kind of a low level ORM, where you can still use SQL and then map the result set to the class objects.

How do i create the mapping file?
If your database has say 20 tables, creating a mapping file similar to the one above is tedious task. Instead you can use the Dao::Map::Helper module which will create these classes for you. Just copy them over to the right folder and start using.

What is the command i need to run?
After you install Dao::Map::Helper the helper script is available in the command line.
You can run the following command in the directory you want the .pm files to be present in.

Examples:

    dao-map-helper --dsn=dbi:mysql:mydb:localhost:3306 --user=root --pwd=pwd --package=package

What are the dependencies and limitations?
As of now it just works with mysql.

=cut
##################################################################################################
sub Main{
  pod2usage(2) unless @ARGV;

  my ($dsn,$user,$pwd,$package);


  GetOptions(
        'dsn=s'    => \$dsn,
        'user=s'   => \$user,
        'pwd=s'      => \$pwd,
        'package=s'      => \$package
  ) || pod2usage(2);

  if (@ARGV) {
      pod2usage(
          -msg =>  "Unparseable arguments received: " . join(',', @ARGV),
          -exitval => 2,
      );
  }

  create_dao($dsn,$user,$pwd,$package);
  print "\nFinished!\n";
}
##################################################################################################
sub create_dao{

    my ($dsn,$user,$pwd,$package) = @_;
     my $dbh = DBI->connect( $dsn , $user, $pwd ) ||  croak("Unable to connect: $DBI::errstr\n");
    try{

        my $sth1;
        $sth1 = $dbh->table_info();
        my $table_info = $sth1->fetchall_hashref('TABLE_NAME');
        foreach my $table_name ( keys %$table_info )
        {
            
            my $sth2 = $dbh->column_info(undef, undef, $table_name, undef);
            my $col_info = $sth2->fetchall_hashref('COLUMN_NAME');

			$table_name = ucfirst($table_name);	
            print  "use " . $package . "::Vo::$table_name"."_Vo;" . "\n";
            open(FILE,">$table_name"."_Vo.pm");
            print FILE "package ". $package . "::Vo::".$table_name."_Vo;\n";
            print FILE "use strict;\n";
            print FILE "use warnings;\n";
            print FILE "sub new {\n";
            print FILE "\tshift;\n";
            print FILE "\tmy(\$row) = \@_;\n";
            print FILE "\tmy \$self = {};\n";

            foreach my $column_name ( keys %$col_info )
            {
              print FILE "\t\$self->{$column_name}=\$row->{$column_name} || \"\";\n";
            }
            $sth2->finish();

            print FILE "\tbless(\$self);\n";
            print FILE "\treturn \$self;\n";
            print FILE "}\n";
            print FILE "return 1;";

            close(FILE);

        }
        $sth1->finish();

    }
    catch Error with {

    }
    finally{
          $dbh->disconnect();
    };
}
##################################################################################################

=head1 AUTHOR

Arjun Surendra, C<< <arjun.surendra04 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dao-map-helper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dao-Map-Helper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dao::Map::Helper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dao-Map-Helper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dao-Map-Helper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dao-Map-Helper>

=item * Search CPAN

L<http://search.cpan.org/dist/Dao-Map-Helper/>

=back


=head1 ACKNOWLEDGEMENTS

Like to thank Rajesh and Venky for reviewing the code.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Arjun Surendra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
# End of Dao::Map::Helper
