
package AMQP;
our $VERSION = '0.01';

use Mojo::Base -base;

sub server {
	my ($self,$url) = @_;
	$url ||= '';			# incase we don't pass a url
	$url =~ /amqp:\/\/
		(?<username>[^:]+):
		(?<password>[^@]+)@
		(?<hostname>[^:\/]+):
		(?<port>\d+)\/
		(?<vhost>[^\/]*)
	/x;
	$self->host($+{'hostname'} || 'localhost');
	$self->port($+{'port'} || 5672);
	$self->vhost($+{'vhost'} || '/');
	$self->username($+{'username'} || 'guest');
	$self->password($+{'password'} || 'guest');
	say "amqp://" . $self->host . ":" . $self->port . $self->vhost if $self->debug;
	$self;
}

1;

__DATA__

=pod

=head1 NAME

AMQP -- Base class for AMQP utilities

=head1 SYNOPSIS

  package AMQP::MyUtility;
  use Mojo::Base 'AMQP';
 
  my $util = AMQP::MyUtility->new;
  $util->server('amqp://amqp.perl.org:5672/test');

=head1 DESCRIPTION

The AMQP class provides the basic functionality common to all AMQP utility classes.

=head1 METHODS

B<server($url)>

Configures all of the connection settings based on an AMQP url.  The format of which is:
  
 amqp://username:password@host:port/vhost

All of the elements of the url are required if you are not using the defaults.  The default settings are:

 amqp://guest:guest@localhost:5672/

=head1 TODO

=head1 BUGS

=head1 COPYRIGHT

Same as Perl.

=head1 AUTHORS

Dave Goehrig <dave@dloh.org>

=cut
