package Apache2::Controller::DBI::Connector;

=head1 NAME

Apache2::Controller::DBI::Connector - 
connects L<DBI|DBI> to C<< $r->pnotes->{a2c}{dbh} >>
or the key that you select.

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

=head2 USAGE

 sub some_a2c_controller_method {
     my ($self, @path_args) = @_;
     my $dbh = $self->pnotes->{a2c}{dbh};
 }

=head2 CONFIGURATION

=head3 CONFIG ALTERNATIVE 1: APACHE CONF

 # virtualhost.conf:
 
 PerlLoadModule Apache::DBI
 PerlLoadModule Apache2::Controller::Directives
 <Location '/'>
     A2C_DBI_DSN        DBI:mysql:database=foobar;host=localhost
     A2C_DBI_User       heebee
     A2C_DBI_Password   jeebee
     A2C_DBI_Options    RaiseError  1
     A2C_DBI_Options    AutoCommit  0

     # this boolean pushes a PerlLogHandler to run rollback if in_txn
     A2C_DBI_Cleanup    1

     SetHandler                 modperl
     PerlInitHandler            MyApp::Dispatch
     PerlHeaderParserHandler    Apache2::Controller::DBI::Connector
 </Location>

=head3 CONFIG ALTERNATIVE 2: SUBCLASS 

If you need to make your life more complicated,
subclass this module and implement your own C<<dbi_connect_args()>>
subroutine, which returns argument list for C<<DBI->connect()>>.

 PerlLoadModule Apache::DBI
 <Location '/'>
     SetHandler                 modperl

     PerlInitHandler            MyApp::Dispatch
     PerlHeaderParserHandler    MyApp::DBIConnect
 </Location>

 package MyApp::DBIConnect;
 use base qw( Apache2::Controller::DBI::Connector );
 sub dbi_connect_args {
     my ($self) = @_;
     return (
         'DBI:mysql:database=foobar;host=localhost',
         'heebee', 'jeebee',
         { RaiseError => 1, AutoCommit => 0 }
     );
 }
 sub dbi_cleanup { 1 }
 sub dbi_pnotes_name { 'dbh' }

 1;

You also have to use overloaded subs in a subclass if you want
to set up multiple DBH handles by specifying the name for the
key in pnotes using C<< A2C_DBI_PNOTES_NAME >> or C<< dbi_pnotes_name() >>.

=head1 DESCRIPTION

Connects a package-space L<DBI> handle to C<< $r->pnotes->{a2c}{dbh} >>.

You only need this where you need a database handle for every
request, for example to connect to a session database regardless of
whether the user does anything.

You can load it only for certain locations, so the handle will get
connected only there.

Otherwise you probably just want to use L<Apache::DBI> and connect
your database handles on an ad-hoc basis from your controllers.

If directive C<< A2C_DBI_Cleanup >> is set, a C<< PerlLogHandler >>
gets pushed which will roll back any open transactions.  So if your
controller does some inserts and then screws up, you don't have to 
worry about trapping these in eval if you want the DBI errors to
bubble up.  They will be automatically rolled back since C<< commit() >>
was never called.

(This used to be a PerlCleanupHandler, but it appears that Apache
hands this off to a thread even if running under prefork, and
cleanup doesn't always get processed before the child handles
the next request.  At least, this is true under L<Apache::Test>.
Wacky.  So, it's a PerlLogHandler to make sure the commit or
rollback gets done before the connection dies.)

If you subclass, you can set up multiple dbh handles with different params:

 <Location '/busy/database/page'>
     SetHandler modperl

     PerlInitHandler         MyApp::Dispatch
     PerlHeaderParserHandler MyApp::DBI::Writer MyApp::DBI::Read
 </Location>

If you use a tiered database structure with one master record
and many replicated nodes, you can do it this way.  Then you 
overload C<< dbi_pnotes_name >> to provide the pnotes key,
say "dbh_write" and "dbh_read".  In the controller get them
with C<< $self->pnotes->{a2c}{dbh_write} >> and
C<< $self->pnotes->{a2c}{dbh_read} >>, etc.

If you subclass DBI, specify your DBI subclass name with
the directive C<< A2C_DBI_Class >>.  Note that this has
to be connected using a string C<< eval() >> instead of
the block C<< eval() >> used for normal L<DBI> if you
do not specify this directive.

=head1 Accessing $dbh from controller

In your L<Apache2::Controller> module for the URI, access the
database handle with C<< $self->pnotes->{a2c}{dbh} >>, or instead of
"dbh", whatever you set in directive C<< A2C_DBI_PNOTES_NAME >> 
or return from your overloaded C<< dbi_pnotes_name() >> method.

=head1 WARNING - DATABASE MEMORY USAGE

Because a reference persists in package space, the database handle
will remain connected after a request ends.

Usually Apache will rotate requests through child processes.

This means that on a lightly-loaded server with a lot of spare child processes,
you will quickly get a large number of idle database connections, one per child.

To solve this you need to set your database handle idle timeout
to some small number of seconds, say 5 or 10.  Then you load
L<Apache::DBI> in your Apache config file so they automatically
get reconnected if needed.  

Then when you get a load increase, handles are connected that persist
across requests long enough to handle the next request, but during
idle times, your database server conserves resources.

There are various formulas for determining how much memory is
needed for the maximum number of connections your database server 
provides.  MySQL has a formula in their docs somewhere to calculate
memory needed for InnoDB handles. It is weird. 

When using
persistent database connections, it's a good idea to limit the
max number of Apache children to the max number of database connections
that your server can provide.  Find a formula from your vendor's 
documentation, if one exists, or wing it.

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( 
    Apache2::Controller::NonResponseBase 
    Apache2::Controller::Methods
);

use Log::Log4perl qw(:easy);
use YAML::Syck;

use Apache2::Const -compile => qw( OK SERVER_ERROR );

use Apache2::Controller::X;
#use Apache2::Controller::DBI;
use DBI;

=head1 METHODS

=head2 process

Gets DBI connect arguments by calling C<< $self->dbi_connect_args() >>,
then connects C<< $dbh >> and stashes it in C<< $r->pnotes->{a2c}{dbh} >>
or the name you select.

The $dbh has a reference in package space, so controllers using it
should always call commit or rollback.  It's good practice to use
C<< eval >> anyway and throw an L<Apache2::Controller::X> or
your subclass of it (using C<< a2cx() >>,
so you can see the function path trace in the logs when the error occurs.

The package-space $dbh for the child persists across requests, so
it is never destroyed.  However, it is assigned with C<< DBI->connect() >>
on every request, so that L<Apache::DBI> will cache the database handle and
actually connect it only if it cannot be pinged.

=cut

# the dbh is always connected, but there is only one instance of it.
my $dbh;
sub process {
    my ($self) = @_;

    my $r = $self->{r};

    # connect the database:
    my @args        = $self->dbi_connect_args;
    my $pnotes_name = $self->dbi_pnotes_name;

    a2cx "Already a dbh in pnotes->{$pnotes_name}"
        if exists $r->pnotes->{a2c}{$pnotes_name};

    my $dbi_subclass = $self->get_directive('A2C_DBI_Class');

    if ($dbi_subclass) {
        eval '$r->pnotes->{a2c}{'.$pnotes_name.'} = '.$dbi_subclass.'->connect(@args)';
    }
    else {
        eval { $r->pnotes->{a2c}{$pnotes_name} = DBI->connect(@args) };
    }
    a2cx $EVAL_ERROR if $EVAL_ERROR;

    # push the log rollback handler if requested
    if ($self->dbi_cleanup) {
        # using a closure on '$pnotes_name' ... is this kosher?
        # maybe this should push a class name of a separate cleanup class,
        # which calls get_directives()?
        # or, re-emulate getting the directive name?  argh
        $r->push_handlers(PerlLogHandler => sub {
            my ($r) = @_;
            my $dbh = $r->pnotes->{a2c}{$pnotes_name} || return Apache2::Const::OK;
            if ($dbh->FETCH('BegunWork')) {
                DEBUG("Cleanup handler: in txn.  Rolling back...");
                eval { $dbh->rollback() };
                if ($EVAL_ERROR) {
                    my $error = "cleanup handler cannot roll back: $EVAL_ERROR";
                    ERROR($error);
                    $r->status_line(__PACKAGE__." $error");
                    return Apache2::Const::SERVER_ERROR;
                }
                else {
                    DEBUG("Cleanup handler rollback successful.");
                }
            }
            else {
                DEBUG("Cleanup handler not in txn.");
            }
            return Apache2::Const::OK;
        });
    }

    return;
}

=head2 dbi_connect_args

Default interprets directives.  L<Apache2::Controller::Directives>.
You can override this in a subclass to provide your own connect args.

=cut

sub dbi_connect_args {
    my ($self) = @_;
    my $directives = $self->get_directives;
    my @names = qw( DSN User Password Options );
    my %opts = map {($_ => $directives->{"A2C_DBI_$_"})} @names;
    return @opts{@names};
}

=head2 dbi_cleanup

Default interprets directive.  L<Apache2::Controller::Directives/A2C_DBI_Cleanup>.
You can override this in a subclass.

=cut

sub dbi_cleanup { return shift->get_directive('A2C_DBI_Cleanup') }

=head2 dbi_pnotes_name 

Maybe it would be useful to you to overload this.
But you'd probably better use the directive 
L<Apache2::Controller::Directives/A2C_DBI_Pnotes_Name>
in case other modules (like session) depend on it.

=cut

sub dbi_pnotes_name { 
    my ($self) = @_;
    return $self->get_directive('A2C_DBI_Pnotes_Name') || 'dbh';
}

=head1 SEE ALSO

L<Apache2::Controller::Directives>

L<Apache2::Controller::SQL::MySQL>

L<Apache2::Controller>

L<Apache::DBI>

L<DBI>

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)- formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut

1;

