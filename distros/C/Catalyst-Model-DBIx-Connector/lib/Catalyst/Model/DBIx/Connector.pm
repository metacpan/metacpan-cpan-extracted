package Catalyst::Model::DBIx::Connector;

use namespace::autoclean;
use DBIx::Connector;
use Moose;

extends qw( Catalyst::Model );

our $VERSION = '0.01';


has dsn       => ( is => 'ro', isa => 'Str', required => 1 );
has username  => ( is => 'ro', isa => 'Str' );
has password  => ( is => 'ro', isa => 'Str' );
has options   => ( is => 'ro', isa => 'HashRef' );
has connector => ( is => 'ro', isa => 'DBIx::Connector', lazy_build => 1, handles => [qw( dbh )] );


sub _build_connector {
  my ( $self ) = @_;

  DBIx::Connector->new(
    map { $self->$_ } qw( dsn username password options ) );
}


__PACKAGE__->meta->make_immutable;

1
__END__

=pod

=head1 NAME

Catalyst::Model::DBIx::Connector - Catalyst model base class for DBI connections using DBIx::Connector

=head1 SYNOPSIS

  # in MyApp.pm

  __PACKAGE__->config(
    'Model::MyModel' => {
      dsn      => 'dbi:Oracle:ORCL',
      username => 'scott',             # optional
      password => 'tiger',             # optional
      options  => { AutoCommit => 0 }, # optional
    },
  );


  # in MyApp/Model/MyModel.pm

  package MyApp::Model::MyModel;

  use namespace::autoclean;
  use Moose;
  extends qw( Catalyst::Model::DBIx::Connector );

  sub model_method {
    my ( $self ) = @_;

    my $dbh = $self->dbh;

    my $sth = $dbh->prepare( '...' );
    $sth->execute;

    # ...

    $dbh->disconnect;
  }

=head1 DESCRIPTION

Catalyst::Model::DBIx::Connector is a simple base class that
can be used to easily add DBI connections to your Catalyst apps.  It
uses C<DBIx::Connector> to add disconnect detection and automatic
reconnection to the database once a connection has dropped.

=head1 SEE ALSO

=over 4

=item L<Catalyst>

=item L<Catalyst::Model>

=item L<DBIx::Connector>

=back

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2012-2014, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
