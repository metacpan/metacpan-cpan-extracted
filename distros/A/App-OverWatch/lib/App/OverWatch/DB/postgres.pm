package App::OverWatch::DB::postgres;
# ABSTRACT: PostgreSQL subclass for OverWatch DB

use strict;
use warnings;
use utf8;

use App::OverWatch::DB;
use App::OverWatch::Config;

use DBIx::Connector;

use base 'App::OverWatch::DB';

sub required_dbopts {
    return qw( dsn user password );
}

sub connect {
    my $self = shift;

    my $Config = $self->{Config};
    my $dsn      = $Config->dsn();
    my $user     = $Config->user();
    my $password = $Config->password();

    my $conn = DBIx::Connector->new($dsn, $user, $password, {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
        pg_enable_utf8 => 1,
    });

    return $conn;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::DB::postgres - PostgreSQL subclass for OverWatch DB

=head1 VERSION

version 0.1

=head1 NAME

App::OverWatch::DB::postgres - PostgreSQL Backend for App::OverWatch::DB

=head1 METHODS

=head2 required_dbopts

List of required attributes for our DBIx::Connector.

=head2 connect

Connect to the database.

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
