use strict;
use warnings;
package Dancer::Session::KiokuDB;
BEGIN {
  $Dancer::Session::KiokuDB::VERSION = '0.05';
}
# ABSTRACT: KiokuDB Dancer session backend

use Carp;
use base 'Dancer::Session::Abstract';

use KiokuDB;

# to have access to configuration data and a helper for paths
use Dancer::Logger;
use Dancer::Config    'setting';
use Dancer::FileUtils 'path';
use Dancer::ModuleLoader;

my ( $db, $warned );

sub init {
    my $self    = shift;
    my $backend = setting('kiokudb_backend') || 'Hash';
    my $class   = "KiokuDB::Backend::$backend";
    my %opts    = ();

    $self->SUPER::init(@_);

    # making sure that if we get backend opts, they're a hashref
    if ( my $opts = setting('kiokudb_backend_opts') ) {
        if ( ref $opts and ref $opts eq 'HASH' ) {
            %opts = %{$opts};
        } else {
            croak 'kiokudb_backend_opts must be a hash reference';
        }
    }

    # default is to create
    defined $opts{'create'} or $opts{'create'} = 1;

    if ( not $warned ) {
        Dancer::Logger::warning("No session KiokuDB backend, using 'Hash'");
        $warned++;
    }

    Dancer::ModuleLoader->load($class)
        or croak "Cannot load $class: perhaps you need to install it?";

    $db = KiokuDB->new(
        backend       => $class->new(%opts),
        allow_classes => ['Dancer::Session::KiokuDB'],
    );
}

sub create {
    my $class = shift;
    my $self  = $class->new;

    $self->flush;

    return $self;
}

sub retrieve {
    my $self  = shift;
    my ($id)  = @_;
    my $scope = $db->new_scope;

    # return object
    return $db->lookup($id);
}

sub destroy {
    my $self  = shift;
    my $scope = $db->new_scope;

    $db->delete($self);
}

sub flush {
    my $self  = shift;
    my $id    = $self->{'id'};
    my $scope = $db->new_scope;

    $db->insert( $id => $self );
}

1;



=pod

=head1 NAME

Dancer::Session::KiokuDB - KiokuDB Dancer session backend

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    # in your Dancer app:
    setting session              => 'KiokuDB';
    setting kiokudb_backend      => 'DBI';
    setting kiokudb_backend_opts => {
        dsn => 'dbi:SQLite:dbname=mydb.sqlite',
    };

    # or in your Dancer config file:
    session:         'KiokuDB'
    kiokudb_backend: 'DBI'
    kiokudb_backend_opts:
        dsn: 'dbi:SQLite:dbname=mydb.sqlite'

=head1 DESCRIPTION

When you want to save session information, you can pick from various session
backends, and they each determine how the session information will be saved. You
can use L<Dancer::Session::Cookie>, L<Dancer::Session::MongoDB> or...
you use L<Dancer::Session::KiokuDB>.

This backend uses L<KiokuDB> to save and access session data.

=head1 OPTIONS

=head2 kiokudb_backend

A string which specifies what backend to use, under C<KiokuDB::Backend>, that
means that backend I<DBI> will be C<KiokuDB::Backend::DBI>. If you'll get smart
and provide I<KiokuDB::Backend::Cool>, you'll get
C<KiokuDB::Backend::KiokuDB::Backend::Cool>, which is, evidently, not cool! :)

Not mandatory.

The default backend is L<KiokuDB::Backend::Hash>.

=head2 kiokudb_backend_opts

A hash reference which indicates options you want to send to the backend's
C<new()> method.

Not mandatory.

The default opts are C<<create => 1>>. If you do not want it to automatically
create, set:

    # in your app
    set kiokudb_backend_opts => {
        create => 0,
        ...
    };

    # or in your configuration
    kiokudb_backend_opts:
        create: 0

=head1 SUBROUTINES/METHODS

=head2 init

Initializes the object by loading the proper KiokuDB backend and creating the
initial connection.

=head2 create

Creates a new object, runs C<flush> and returns the object.

=head2 flush

Writes the session information to the KiokuDB session database.

=head2 retrieve

Retrieves session information from the KiokuDB session database.

=head2 destroy

Deletes session information from the KiokuDB session database.

=head1 SEE ALSO

The Dancer Advent Calendar 2010.

=head1 AUTHOR

  Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

