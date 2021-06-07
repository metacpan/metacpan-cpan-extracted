package App::Prove::Plugin::MySQLPool;
use strict;
use warnings;
use File::Temp;
use POSIX::AtFork;
use Test::mysqld::Pool;

our $VERSION = '0.10';

sub load {
    my ($class, $prove) = @_;
    my @args     = @{ $prove->{args} };
    my $preparer = $args[ 0 ];
    my $jobs     = $prove->{ app_prove }->jobs || 1;
    my $lib      = $prove->{ app_prove }->lib;
    my $blib     = $prove->{ app_prove }->blib;
    my $includes = $prove->{ app_prove }->includes;

    my $share_file = File::Temp->new(); # deleted when DESTROYed
    my $pool       = Test::mysqld::Pool->new(
        jobs       => $jobs,
        share_file => $share_file->filename,
        ($preparer ? do {
            my @libs;
            push( @libs, 'lib' ) if $lib;
            push( @libs, 'blib/lib', 'blib/arch' ) if $blib;
            push( @libs, @$includes ) if @$includes;
            @libs = map { File::Spec->rel2abs($_) } @libs;
            push( @INC, @libs );
            eval "require $preparer" ## no critic
                or die "$@";
            (
                preparer => sub {
                    my ($mysqld) = @_;
                    $preparer->prepare( $mysqld );
                },
                $preparer->can('my_cnf') ? ( my_cnf => $preparer->my_cnf ) : (),
            )
        } : ()),
    );
    $pool->prepare;

    $prove->{ app_prove }{ __PACKAGE__ } = [ $pool, $share_file ]; # ref++
    $prove->{ app_prove }->formatter('TAP::Formatter::MySQLPool');

    $ENV{ PERL_APP_PROVE_PLUGIN_MYSQLPOOL_SHARE_FILE } = $share_file->filename;

    POSIX::AtFork->add_to_child(create_child_hook($$));

    1;
}

sub create_child_hook {
    my ($ppid) = @_;
    return sub {
        my ($call) = @_;

        # we're in the test process

        # prove uses 'fork' to create child processes
        # our own 'ps -o pid ...' uses 'backtick'
        # only hook 'fork'
        ($call eq 'fork')
            or return;

        # restrict only direct child of prove
        (getppid() == $ppid)
            or return;

        my $share_file = $ENV{ PERL_APP_PROVE_PLUGIN_MYSQLPOOL_SHARE_FILE }
            or return;

        my $dsn = Test::mysqld::Pool->new( share_file => $share_file )->alloc;

        # use this in tests
        $ENV{ PERL_TEST_MYSQLPOOL_DSN } = $dsn;
    };
}

{
    package TAP::Formatter::MySQLPool::Session;
    use parent 'TAP::Formatter::Console::Session';

    sub close_test {
        my $self = shift;

        my $share_file = $ENV{ PERL_APP_PROVE_PLUGIN_MYSQLPOOL_SHARE_FILE }
            or return;
        Test::mysqld::Pool->new( share_file => $share_file )->dealloc_unused;

        $self->SUPER::close_test(@_);
    }
}

{
    package TAP::Formatter::MySQLPool;
    use parent 'TAP::Formatter::Console';

    sub open_test {
        my $self = shift;

        bless $self->SUPER::open_test(@_), 'TAP::Formatter::MySQLPool::Session';
    }
}

1;
__END__

=head1 NAME

App::Prove::Plugin::MySQLPool - pool of Test::mysqld-s reused while testing

=head1 SYNOPSIS

    prove -j4 -PMySQLPool t
      or
    prove -j4 -PMySQLPool=MyApp::Test::DB t

=head1 DESCRIPTION

App::Prove::Plugin::MySQLPool is a L<prove> plugin to speedup your tests using a pool of L<Test::mysqld>s.

If you're using Test::mysqld, and have a lot of tests using it, annoyed by the mysql startup time slowing your tests, this module is for you.

This module launches -j number of Test::mysqld instances first.

Next, each mysqld instance optionally calls

    MyApp::Test::DB->prepare( $mysqld );

You can CREATE TABLEs using L<GitDDL> or L<DBIx::Class::Schema::Loader> or others,
or bulk insert master data before start testing.

MyApp::Test::DB only needs to implement a C<prepare> sub.
C<prepare> is called only once per -j number of mysqld instances,
and is called before your first .t file get tested.

    # MyApp::Test::DB
    sub prepare {
        my ($package, $mysqld) = @_;
        my $gd = GitDDL->new( dsn => $mysqld->dsn, ... );
        $gd->deploy;
    }

Use $ENV{ PERL_TEST_MYSQLPOOL_DSN } like following in your test code.

    my $dbh = DBI->connect( $ENV{ PERL_TEST_MYSQLPOOL_DSN } );

Since this module reuses mysqlds,
you'd better erase all rows inserted at the top of your tests.

    $dbh->do( "TRUNCATE $_" ) for @tables;

If you need customize my.cnf, you may want to implement C<my_cnf> method in MyApp::Test::DB.

    # MyApp::Test::DB
    sub my_cnf {
        +{
            "skip-networking" => "",
            "character-set-server" => "utf8mb4",
        };
    }

This config is used before launching Test::mysqld instances.
So you can set non-dynamic system variables.

=head1 AUTHOR

Masakazu Ohtsuka E<lt>o.masakazu@gmail.comE<gt>

=head1 SEE ALSO

L<prove>, L<Test::mysqld>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
