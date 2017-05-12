use strict;
use warnings;
use 5.010;
use URI;
use AnyEvent::FTP::Client;
use Term::Prompt qw( prompt );
use Getopt::Long qw( GetOptions );

my $debug = 0;
my $method = 'nlst';

GetOptions(
  'd' => \$debug,
  'l' => sub { $method = 'list' },
);

my $ftp = AnyEvent::FTP::Client->new;

if($debug)
{
  $ftp->on_send(sub {
    my($cmd, $arguments) = @_;
    $arguments //= '';
    $arguments = 'XXXX' if $cmd eq 'PASS';
    say "CLIENT: $cmd $arguments";
  });

  $ftp->on_each_response(sub {
    my $res = shift;
    say sprintf "SERVER: [ %d ] %s", $res->code, $_ for @{ $res->message };
  });

}

my $uri = shift;

unless(defined $uri)
{
  say STDERR "usage: perl fls.pl URL\n";
  exit 2;
}

$uri = URI->new($uri);

unless($uri->scheme eq 'ftp')
{
  say STDERR "only FTP URL accpeted";
  exit 2;
}

unless(defined $uri->password)
{
  $uri->password(prompt('p', 'Password: ', '', ''));
  say '';
}

my $path = $uri->path;
$uri->path('');

$ftp->connect($uri);

say $_ for @{ $ftp->$method($path)->recv };
