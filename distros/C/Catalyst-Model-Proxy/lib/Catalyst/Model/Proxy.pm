package Catalyst::Model::Proxy;

use strict;
use base 'Catalyst::Model';
use NEXT;

our $VERSION = '0.04';
our %CLASS_CACHE;

=head1 NAME

Catalyst::Model::Proxy - Proxy Model Class

=head1 SYNOPSIS

  # a sample use with C<Catalyst::Model::DBI::SQL::Library>

  # lib/MyApp/Model/DBI/SQL/Library/MyDB.pm
  package MyApp::Model::DBI::SQL::Library::MyDB;

  use base 'Catalyst::Model::DBI::SQL::Library';

  __PACKAGE__->config(
    dsn           => 'dbi:Pg:dbname=myapp',
    password      => '',
    user          => 'postgres',
    options       => { AutoCommit => 1 },
  );

  1;

  # lib/MyApp/Model/Other.pm	
  package MyApp::Model::Other;

  use base 'Catalyst::Model::Proxy';

  __PACKAGE__->config(
    target_class => 'DBI::SQL::Library::MyDB',
    subroutines => [ qw ( dbh load ) ] 
  );

  # get access to shared resources via proxy mechanism
  sub something {
    my $self = shift;
    my $sql = $self->load('something.sql'); #located under root/sql
    my $query = $sql->retr ( 'query' );	
    my $dbh = $self->dbh;
    # ... do some stuff with $dbh
    $dbh->do ( $query );
  }

  # back in the controller

  # lib/MyApp/Controller/Other.pm
  package MyApp::Controller::Other;

  use base 'Catalyst::Controller';	

  my $model = $c->model('Other');
  $model->something;
	
=head1 DESCRIPTION

This is the Catalyst Model Class called C<Catalyst::Model::Proxy> that
implements Proxy Design Pattern. It enables you to make calls to target
classes/subroutines via proxy mechanism. This means reduced memory footprint
because any operations performed on the proxies are forwarded to the 
original complex ( target_class ) object. The target class model is also cached
for increased performance. For more information on the proxy design pattern 
please refer yourself to: http://en.wikipedia.org/wiki/Proxy_design_pattern

=head1 METHODS

=over 4

=item new

Initializes DBI connection

=cut

sub new {
  my ( $self, $c ) = @_;
  
  $self = $self->NEXT::new($c);
  $self->{namespace} ||= ref $self;
  $self->{additional_base_classes} ||= ();
  $self->{log} = $c->log;
  $self->{debug} = $c->debug;
  
  for my $sub ( @{$self->{subroutines}} ) {
    my $target_class = $self->{target_class};
    unless ( $CLASS_CACHE{$target_class}{$sub} ) {
      $self->{log}->debug( "Installing sub:$sub from target_class:$target_class into proxy" ) if $self->{debug};
      $CLASS_CACHE{$target_class}{$sub} = 1;
      no strict 'refs';
      *{__PACKAGE__ . "::$sub"} = sub {
        shift;
        return $c->model($target_class)->$sub(@_);
      }
    }
  }
  return $self;
}

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHOR

Alex Pavlovic, C<alex.pavlovic@taskforce-1.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
