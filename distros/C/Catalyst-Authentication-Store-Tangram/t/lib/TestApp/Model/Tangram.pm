package TestApp::Model::Tangram;
use strict;
use warnings;
use base qw/Catalyst::Model/;
use DBI;
use Tangram::Relational;
use Tangram::Storage;
use Tangram::Type::String;
use Tangram::Type::Array::FromMany;
use Tangram;
use MRO::Compat;
use File::Temp qw/tempfile/;

BEGIN {
    __PACKAGE__->mk_accessors(qw/storage schema _sqlite_file/);
}

sub COMPONENT {
    my ($class, $app, @rest) = @_;
    my $self = $class->next::method($app, @rest);
    my ($fh, $fn) = tempfile;
    close($fh);
    $self->{_sqlite_file} = $fn;
    my @dsn = ("DBI:SQLite:dbname=$fn", '', '');
    my $dbh = DBI->connect(@dsn);   
    $self->{schema} = Tangram::Relational->schema( {
        classes => [
            Users => {
                fields => {
                    string => [qw/username password otherfield/],
                    array  => { groups => 'Roles' },
                },
            },
            Roles => {
                fields => {
                    string => [qw/name/],
                },
            },
        ],
    });
    Tangram::Relational->deploy($self->schema, $dbh);
    $dbh->disconnect;
    $self->{storage} = Tangram::Relational->connect(
        $self->schema, @dsn
    );
    my @groups = map { Roles->new(name => $_) } qw/role1 role2 role3/;
    my $test_user = Users->new(username => 'testuser', password => 'testpass', groups => \@groups, otherfield => 'baaa');
    $self->storage->insert($test_user); # Cascade inserts all the groups too.
    return $self;
}

sub DESTROY {
    my ($self) = @_;
    $self->storage->disconnect if $self->storage;
    unlink $self->{_sqlite_file};
}

1;

