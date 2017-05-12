package App::HTTPThis;
BEGIN {
  $App::HTTPThis::VERSION = '0.002';
}

# ABSTRACT: Export the current directory over HTTP

use strict;
use warnings;
use Plack::App::Directory;
use Plack::Runner;
use Getopt::Long;
use Pod::Usage;


sub new {
  my $class = shift;
  my $self = bless {port => 7007, root => '.'}, $class;

  GetOptions($self, "help", "man", "port=i", "name=s") || pod2usage(2);
  pod2usage(1) if $self->{help};
  pod2usage(-verbose => 2) if $self->{man};

  if (@ARGV > 1) {
    pod2usage("$0: Too many roots, only single root supported");
  }
  elsif (@ARGV) {
    $self->{root} = shift @ARGV;
  }

  return $self;
}


sub run {
  my ($self) = @_;

  my $runner = Plack::Runner->new;
  $runner->parse_options(
    '--port'         => $self->{port},
    '--env'          => 'production',
    '--server_ready' => sub { $self->_server_ready(@_) },
  );

  eval {
    $runner->run(Plack::App::Directory->new({root => $self->{root}})->to_app);
  };
  if (my $e = $@) {
    die "FATAL: port $self->{port} is already in use, try another one\n"
      if $e =~ /failed to listen to port/;
    die "FATAL: internal error - $e\n";
  }
}

sub _server_ready {
  my ($self, $args) = @_;

  my $host  = $args->{host}  || '127.0.0.1';
  my $proto = $args->{proto} || 'http';
  my $port  = $args->{port};

  print "Exporting '$self->{root}', available at:\n";
  print "   $proto://$host:$port/\n";

  return unless my $name = $self->{name};

  eval {
    require Net::Rendezvous::Publish;
    Net::Rendezvous::Publish->new->publish(
      name   => $name,
      type   => '_http._tcp',
      port   => $port,
      domain => 'local',
    );
  };
  if ($@) {
    print "\nWARNING: your server will not be published over Bonjour\n";
    print "    Install one of the Net::Rendezvous::Publish::Backend\n";
    print "    modules from CPAN\n"
  }
}

1;


__END__
=pod

=head1 NAME

App::HTTPThis - Export the current directory over HTTP

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # Not to be used directly, see http_this command

=head1 DESCRIPTION

This class implements all the logic of the L<http_this> command.

Actually, this is just a very thin wrapper around
L<Plack::App::Directory>, that is where the magic really is.

=head1 METHODS

=head2 new

Creates a new App::HTTPThis object, parsing the command line arguments
into object attribute values.

=head2 run

Start the HTTP server.

=head1 SEE ALSO

L<http_this>, L<Plack>, L<Plack::App::Directory>, and L<Net::Rendezvous::Publish>.

=head1 THANKS

And the Oscar goes to: Tatsuhiko Miyagawa.

For L<Plack>, L<Plack::App::Directory> and many many others.

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0

=cut

