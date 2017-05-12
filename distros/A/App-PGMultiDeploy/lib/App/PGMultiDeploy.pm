
use 5.006;
use strict;
use warnings;
package App::PGMultiDeploy;
use Moo;
use DBI;
use Carp;
use Config::IniFiles;
use PGObject::Util::DBChange;
use Try::Tiny;

=head1 NAME

App::PGMultiDeploy - OO deployment to multiple dbs for Pg

=head1 VERSION

Version 0.004

=cut

our $VERSION = 0.004000;


=head1 SYNOPSIS

This package provides a library and a command line utility to run sql scripts
on multiple pg databases relying on two phase commit to ensure the script 
succeeds or fails.  Scripts can only be applied once and the intended use is to
manage schema changes over time in databases subject to row-level logical
replication.

Features:

=over

=item Recovery for partial application

A change file is not re-applied if it has been applied before unless the file
has changed.  This means if another system using PGObject::Util::DBChange 
applies a file to one db, you can still safely use it here.

=item Two phase commit

A change file either commits or rolls back on every database in a group

=item Reuse of libpq tooling

.pgpass etc files work with this tool

=item Logging of failures in separate transaction

=back

Use as a library:

    use App::PGMultiDeploy;

    my $foo = App::PGMultiDeploy->new( config_file => 'path/to/conf.ini',
                                       change_file => 'path/to/change.sql',
                                       dbgroup => 'defined_in_config');
    $foo->deploy;

use as a commandline:

    pg_multideploy --config=/path/to/conf.ini --sql=mychanges.sql --dbgroup=foo

=head1 PROPERTIES

=head2 config_file (--config)

The ini file defining the environment configuration

=cut

has config_file => (is => 'ro', 
                    isa => sub { die 'Config File not found' unless -f $_[0] }
);

=head2 config (lazily loaded from config file)

=cut

=head2 dbgroup (--dbgroup)

=cut

has dbgroup => (is => 'ro');

=head2 change_file (--sql)

Path to db change

=cut

has change_file => (is => 'ro', 
                   isa => sub { die 'Change File not found' unless -f $_[0] }
);

=head2 config

The configuration object loaded from the config file

=cut

has config => (is => 'lazy');

sub _build_config{
   my ($self) = @_;
   my $config = Config::IniFiles->new(-file => $self->config_file);
   return $config;
}
=head2 dbchange

The db change object, loaded from file

=cut

has dbchange => (is => 'lazy');

sub _build_dbchange{
    my ($self) = @_;
    my $dbchange = PGObject::Util::DBChange->new(
         path => $self->change_file, 
         commit_txn => "FAIL" # don't allow direct application
    );
}

has succeeded => (is => 'rwp', default => 1);

=head1 SUBROUTINES/METHODS

=head2 deploy

=cut

sub deploy {
    my ($self) = @_;
    local $PGObject::Util::DBChange::commit = 0;
    my @dbgroup = $self->config->val("dbgroups", $self->dbgroup)
                  or die 'Cannot find db group ' . $self->dbgroup;
    
    my @dbs = map { DBI->connect($self->_connstr($_), undef, undef, 
               {AutoCommit => 1, pg_server_prepare => 0}) }
                  @dbgroup;
    for (@dbs) {
        PGObject::Util::DBChange::init($_) 
           if PGObject::Util::DBChange::needs_init($_);
    }
    $_->commit for @dbs;
    my @logs = map { $self->_apply_if_needed($_) } @dbs;
    if ($self->succeeded){
        $_->{dbh}->do("COMMIT PREPARED '$_->{txn_id}'")
            for grep {defined $_} @logs
    } else {
        $_->{dbh}->do("ROLLBACK PREPARED '$_->{txn_id}'")
            for grep {defined $_} @logs
    }
    $self->dbchange->log(%$_) for grep {defined $_} @logs;
    $_->commit for @dbs;
}

sub _connstr{
    my ($self, $dbname) = @_;
    my $cnx = $self->config->val('databases', $dbname);
    die 'No connection configured for ' . $dbname unless defined $cnx;
    warn $cnx;
    return 'dbi:Pg:' . $self->config->val('databases', $dbname);
}

my $counter = 0;
sub _apply_if_needed {
    my ($self, $dbh) = @_;
    ++$counter;
    my $txn_id = "multideploy $counter";
    my $dbchange = PGObject::Util::DBChange->new(
            %{$self->dbchange}, 
            commit_txn => "PREPARE TRANSACTION '$txn_id';",
    );
    if ($dbchange->is_applied($dbh)){
        warn 'Change already applied';
        return;
    } else {
       try {
           $dbchange->apply($dbh);
       } catch {
           warn "Could not apply change";
           $self->_set_succeeded(0);
       };
       return {state => $DBI::state, errstr => $DBI::errstr, dbh => $dbh,
               txn_id => $txn_id };
    }
}

=head1 AUTHOR

Chris Travers, C<< <chris at efficito.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-pgmultideploy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-PGMultiDeploy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::PGMultiDeploy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-PGMultiDeploy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-PGMultiDeploy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-PGMultiDeploy>

=item * Search CPAN

L<http://search.cpan.org/dist/App-PGMultiDeploy/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Sedex Global for funding the initial version of this tool.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Chris Travers.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Chris Travers's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::PGMultiDeploy
