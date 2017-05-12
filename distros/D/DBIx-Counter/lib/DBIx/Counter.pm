package DBIx::Counter;

use DBI;
use Carp qw(carp croak);
use strict;

require 5.004;

use overload (
               '++'     => \&inc,
               '--'     => \&dec,
               '""'     => \&value,
               fallback => 1,
             );

use vars qw( $VERSION $DSN $LOGIN $PASSWORD $TABLENAME );

$VERSION = '0.03';

sub new
{
    my $pkg         = shift;
    my $countername = shift or croak("No counter name supplied");
    unshift @_, 'initial' if @_ % 2;
    my %opts        = @_;

    my $self = {
                 countername => $countername,
                 dbh         => $opts{dbh},
                 dsn         => $opts{dsn}       || $DSN,
                 login       => $opts{login}     || $LOGIN,
                 password    => $opts{password}  || $PASSWORD,
                 tablename   => $opts{tablename} || $TABLENAME || 'counters',
                 initial     => $opts{initial}   || '0',
               };

    croak("Unable to connect to database: no valid connection handle or DSN supplied")
      unless $self->{dbh} or $self->{dsn};

    bless $self, $pkg;
    $self->_init;
    $self;
}

sub _init
{
    my $self = shift;

    # create counter record if not exists
    eval {
        my $dbh = $self->_db;
        my ($exists) = $dbh->selectrow_array( qq{select count(*) from $self->{tablename} where counter_id=?}, undef, $self->{countername} );
        unless ( $exists > 0 )
        {
            $dbh->do( qq{insert into $self->{tablename} (counter_id,value) values (?,?)}, undef, $self->{countername}, $self->{initial} );
        }
    } or croak "Error creating counter record: $@";
}

sub _db
{
    my $self = shift;

    return $self->{dbh}
      || DBI->connect_cached( $self->{dsn}, $self->{login}, $self->{password}, { PrintError => 0, RaiseError => 1 } );
}

sub _add
{
    my ( $self, $add ) = @_;
    my $dbh     = $self->_db;
    my $sth_set = $dbh->prepare_cached(qq{update $self->{tablename} set value=value+? where counter_id=?});
    $sth_set->execute( $add, $self->{countername} );
}

sub inc
{
    my $self = shift;
    $self->_add(1);
}

sub dec
{
    my $self = shift;
    $self->_add(-1);
}

sub value
{
    my $self    = shift;
    my $dbh     = $self->_db;
    my $sth_get = $dbh->prepare_cached(qq{select value from $self->{tablename} where counter_id=?});

    $sth_get->execute( $self->{countername} );
    my ($v) = $sth_get->fetchrow_array;
    $sth_get->finish;

    return $v;
}

sub lock   { 0 }
sub unlock { 0 }
sub locked { 0 }

1;

__END__

=pod

=head1 NAME

DBIx::Counter - Manipulate named counters stored in a database

=head1 WARNING

This is the initial release! It has been tested to work with SQLite, Mysql,
Postgresql and MS SQL Server, under perl 5.6 and 5.8. 

I would appreciate feedback, and some help on making it compatible with older
versions of perl. I know 'use warnings' and 'our' don't work before 5.6, but
that's where my historic knowledge ends.

=head1 SYNOPSIS

    use DBIx::Counter;
    $c = DBIx::Counter->new('my counter', 
                            dsn       => 'dbi:mysql:mydb',
                            login     => 'username',
                            password  => 'secret'
                           );
    $c->inc;
    print $c->value;
    $c->dec;

=head1 DESCRIPTION

This module creates and maintains named counters in a database. It has a simple
interface, with methods to increment and decrement the counter by one, and a
method for retrieving the value. It supports operator overloading for
increment (++), decrement (--) and stringification ("").

It should perform well in persistent environments, since it uses the
L<connect_cached|DBI/item_connect_cached> and L<prepare_cached|DBI/item_prepare_cached> methods of L<DBI>.

The biggest advantage over its main inspiration - L<File::CounterFile> - is that
it allows distributed, concurrent access to the counters and isn't tied to a
single file system.

Connection settings can be set in the constructor. The table name is
configurable, but the column names are currently hard-coded to counter_id and
value.

The following SQL statement can be used to create the table:

    CREATE TABLE counters (
        counter_id  varchar(64) primary key,
        value       int not null default 0
    );

This module attempts to mimick the File::CounterFile interface, except
currently it only supports integer counters. The locking functions in
File::CounterFile are present for compatibility only: they always return 0.

=head2 EXAMPLES

Some other ways to call new():

    # with an initial value, and a different table name
    $c = DBIx::Counter->new('my counter',
                            42,
                            dsn       => 'dbi:mysql:mydb',
                            tablename => 'gauges'
                           );

    # with a predefined connection
    $c = DBIx::Counter->new('my counter', dbh => $dbh);
    
A very basic real-world example:

    # a hit counter!
    # demonstrates operator overloading and stringification
    use CGI qw/:standard/;
    use DBIx::Counter;

    print header(),
          start_html(),
          h1("Welcome");
    
    my $c = DBIx::Counter->new('my_favorite_page', 
                            dsn       => 'dbi:mysql:mydb',
                            login     => 'username',
                            password  => 'secret'
                           );
    
    $c++;
    
    print 
       em("this page has been accessed $c times!"),
       end_html();

=head2 METHODS

=over

=item new

Creates a new counter instance. 

First parameter is the required counter name. Second, optional, argument is
an initial value for the counter on its very first use. It also accepts named
parameters for an already existing database handle, or the dbi connection
string, dbi login and dbi password, and the table name:

=over

=item dbh - A pre-existing DBI connection

=item dsn - A valid dbi connection string

=item login - Optional

=item password - Optional

=item tablename - Defaults to 'counters'

=back

=item inc

increases the counter by one.

    $c->inc;
    # or using overload:
    $c++;

=item dec

decreases the counter by one.

    $c->dec;
    # or using overload:
    $c--;

=item value

returns the current value of the counter.

    print $c->value;
    # or using overload: 
    print "Item $c is being processed\n";

=item lock

Noop. Only provided for API compatibility with File::CounterFile.

=item unlock

Noop. Only provided for API compatibility with File::CounterFile.

=item locked

Noop. Only provided for API compatibility with File::CounterFile.

=back

=head2 GLOBAL SETTINGS

In addition to passing settings through the constructor, it's also possible
to use the package variables $DSN, $LOGIN and $PASSWORD and $TABLENAME. This
allows you to specify the settings application-wide, or within a block of code
where you need multiple counters. Each of those variables supplies a default
for the lowercase parameters to L</new>.

However, be aware that using global variables is B<not recommended>. Setting them
in more than one place will make it difficult to track down bugs. Using them in
multiple applications in persistent environments such as mod_perl B<will>
result in unpredictable behaviour. If you really need to use this feature,
always try to use "local".

Here's an example:

    use DBIx::Counter;
    
    sub count_stuff {
        local $DBIx::Counter::DSN       = 'dbi:SQLite:dbname=counters.sqlt';
        local $DBIx::Counter::TABLENAME = 'my_own_counters';
        
        my $c1 = DBIx::Counter->new('gauge one');
        my $c2 = DBIx::Counter->new('gauge two');
        
        # ...
    }


=head1 SEE ALSO

L<File::CounterFile>

=head1 AUTHOR

Rhesa Rozendaal, E<lt>rhesa@cpan.orgE<gt>. 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Rhesa Rozendaal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

