package App::CPANIDX::HTTP::Server;
{
  $App::CPANIDX::HTTP::Server::VERSION = '0.08';
}
 
#ABSTRACT: HTTP::Server::Simple based server for CPANIDX

use strict;
use warnings;
use DBI;
use App::CPANIDX::Renderer;
use App::CPANIDX::Queries;
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
 
sub dsn {
  my ($self,$dsn,$user,$pass) = @_;
  if ( $dsn and $self->{_dbh} ) {
    warn "Already have a database connection, thanks\n";
    return;
  }
  if ( $dsn ) {
    $self->{_dbh} = DBI->connect($dsn,$user,$pass) or die $DBI::errstr, "\n";
    $self->{_dsn} = $dsn;
    return;
  }
  return $self->{_dsn};
}

sub handle_request {
   my $self = shift;
   my $cgi  = shift;
   
   my $path = $cgi->path_info();
   $path =~ s!/+!/!g;
   warn $path, "\n";
   my ($root,$enc,$type,$search) = grep { $_ } split m#/#, $path;

   if ( $root eq 'cpanidx' and $enc and $type ) {
      $search = '0' if $type =~ /^next/ and !$search;
      my @results = $self->_search_db( $type, $search );
      $enc = 'yaml' unless $enc and grep { lc($enc) eq $_ } App::CPANIDX::Renderer->renderers();
      my $ren = App::CPANIDX::Renderer->new( \@results, $enc );
      my ($ctype, $string) = $ren->render( $type );
      print "HTTP/1.0 200 OK\r\n";
      print "Content-type: $ctype\r\n\r\n";
      print $string;
   } 
   else {
      print "HTTP/1.0 404 Not found\r\n";
      print $cgi->header,
      $cgi->start_html('Not found'),
      $cgi->h1('Not found'),
      $cgi->end_html;
   }
}

sub _search_db {
  my ($self,$type,$search) = @_;
  my @results;
  if ( my $sql = App::CPANIDX::Queries->query( $type ) ) {
    if ( ( $type eq 'mod' or $type eq 'corelist' or $type eq 'perms' ) 
        and !( $search =~ m#\A[a-zA-Z_][0-9a-zA-Z_]*(?:(::|')[0-9a-zA-Z_]+)*\z# ) ) {
      return @results;
    } 
    # send query to dbi
    if ( my $sth = $self->{_dbh}->prepare_cached( $sql->[0] ) ) {
      $sth->execute( ( $sql->[1] ? $search : () ) );
      while ( my $row = $sth->fetchrow_hashref() ) {
        push @results, { %{ $row } };
      }
      if ( $type eq 'mod' ) { # sanity check
        @results = grep { $_->{mod_name} eq $search } @results;
      }
    }
    else {
      warn $DBI::errstr, "\n";
      return @results;
    }
  }
  return @results;
}

1;


__END__
=pod

=head1 NAME

App::CPANIDX::HTTP::Server - HTTP::Server::Simple based server for CPANIDX

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  use strict;
  use warnings;
  use App::CPANIDX::HTTP::Server;

  my $dsn = 'dbi:SQLite:dbname=cpanidx.db';
  my $user = '';
  my $pass = '';
  my $port = 8082; # the port to listen for requests on

  my $server = App::CPANIDX::HTTP::Server->new( $port );
  $server->dsn( $dsn, $user, $pass );
  $server->run();

  # Requests can now be directed to http://nameofyourserver:8082/cpanidx/

=head1 DESCRIPTION

App::CPANIDX::HTTP::Server is a L<HTTP::Server::Simple> based server for CPANIDX.
Use the C<cpanidx-gendb> script provided by L<App::CPANIDX> to generate a CPANIDX
database and then use this module to serve the associated data.

=head1 METHODS

=over

=item C<new>

Start a new instance of App::CPANIDX::HTTP::Server. Takes one option, the port number to
start listening on for requests. If it is not provided will default to C<8080>.

=item C<dsn>

After running C<new>, but before calling C<run>, call this to assign the database details to 
the server. Takes three arguments: a L<DBI> C<DSN> string, a username (if applicable) and a 
password (if applicable).

=item C<run>

Runs the server and starts handling requests.

=item C<handle_request>

Deals with requests. No user serviceable parts.

=back

=head1 SEE ALSO

L<App::CPANIDX>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

