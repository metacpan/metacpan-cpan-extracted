package TestApp::DBI::Controller;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( Apache2::Controller Apache2::Request );

sub allowed_methods {qw( 
    working 
    handle_available 
    select_1
    exception_works
    create_table
    insert_ok
    txn_goodquery
    txn_dont_commit
    txn_dont_commit_didnt_insert
)}

use Apache2::Const -compile => qw( HTTP_OK );

sub new {
    my $self = Apache2::Controller::new(@_);
    $self->content_type('text/plain');
    return $self;
}

sub working {
    my ($self, @args) = @_;
    $self->print(__PACKAGE__." is working.\n");
    return Apache2::Const::HTTP_OK;
}

sub handle_available {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    my $ref = ref $dbh || '[none]';
    $self->print("$ref is dbh class");
    return Apache2::Const::HTTP_OK;
}

sub select_1 {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    my ($result) = $dbh->selectrow_array('select 1');
    $self->print( 
        $result == 1 ? "Query (select 1) works.\n" : "Query (select 1) broken.\n"
    );
    return Apache2::Const::HTTP_OK;
}

sub exception_works {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    eval { $dbh->do('bogus query') };
    $self->print(
        $EVAL_ERROR && $EVAL_ERROR =~ m{ syntax \s+ error }mxs
        ? "Bogus query threw correct exception.\n"
        : "Bogus query threw unexpected exception: '$EVAL_ERROR'\n"
    );
    return Apache2::Const::HTTP_OK;
}

sub create_table {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    $dbh->do(q{ 
        CREATE TABLE test (  
            id          VARCHAR(10), 
            val         VARCHAR(10),
            PRIMARY KEY (id) 
        ) 
    });
    $self->print("Created test table.\n");
    return Apache2::Const::HTTP_OK;
}

sub insert_ok {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    $dbh->do(q{ INSERT INTO test (id, val) VALUES ('biz', 'baz') });
    my ($val) = $dbh->selectrow_array("SELECT val FROM test WHERE id = 'biz'");
    $val ||= '[insert did not work!]';
    $self->print("Inserted biz = '$val'.\n");
    return Apache2::Const::HTTP_OK;
}

sub txn_goodquery {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    $dbh->begin_work;
    $dbh->do(q{ INSERT INTO test (id, val) VALUES ('boz', 'noz') });
    $dbh->commit;
    my ($val) = $dbh->selectrow_array("SELECT val FROM test WHERE id = 'boz'");
    $val ||= '[insert did not work!]';
    $self->print("Inserted boz = '$val'.\n");
    return Apache2::Const::HTTP_OK;
}

sub txn_dont_commit {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    $dbh->begin_work;
    $dbh->do(q{ UPDATE test SET val = 'bogus' WHERE id = 'biz' });
    $self->print("Updated biz without commit.\n");
    return Apache2::Const::HTTP_OK;
}

sub txn_dont_commit_didnt_insert {
    my ($self, @args) = @_;
    my $dbh = $self->pnotes->{a2c}{dbh};
    my ($val) = $dbh->selectrow_array("SELECT val FROM test WHERE id = 'biz'");
    $val ||= '[no value]';
    $self->print("Verify no commit: biz = '$val'.");
    return Apache2::Const::HTTP_OK;
}

1;
