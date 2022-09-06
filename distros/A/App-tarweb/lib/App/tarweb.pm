package App::tarweb;

use strict;
use warnings;
use 5.034;
use experimental qw( signatures postderef );
use Browser::Start qw( open_url );
use Plack::Runner;
use Plack::App::Libarchive 0.02;
use Plack::App::File;
use IO::Socket::INET;
use Path::Tiny qw( path );
use File::ShareDir::Dist qw( dist_share );
use URI;
use Encode qw( encode );
use Plack::Builder ();

# ABSTRACT: Open an archive file in your web browser!
our $VERSION = '0.01'; # VERSION


sub new ($class)
{
  bless {}, $class;
}

sub main ($self, @ARGV)
{
  my $runner = Plack::Runner->new;

  local $ENV{PLACK_ENV} = 'deployment';

  unshift @ARGV, '--port', $self->_random_port;

  @ARGV = $runner->parse_options(@ARGV)->@*;

  if(@ARGV == 0)
  {
    say STDERR "no archive file given!";
    return 2;
  }

  my @paths;
  $self->{paths} = \@paths;

  push $runner->{options}->@*, server_ready => sub ($args) {
    my $url = $self->{url} = URI->new("http://127.0.0.1/");
    $url->host($args->{host}) if $args->{host};
    $url->scheme($args->{proto}) if $args->{proto};
    $url->port($args->{port});

    foreach my $path (@paths)
    {
      $url->path($path);
      say $url;
      open_url $url;
    }
  };

  my $app;

  my @pa_la_args = (
    tt_include_path => [dist_share(__PACKAGE__)],
  );

  if(@ARGV == 1)
  {
    @paths = ('/');
    $app = Plack::App::Libarchive->new( archive => $ARGV[0], @pa_la_args );
  }
  else # @ARGV > 1
  {
    my %dedupe;

    $app = Plack::Builder->new;

    $app->mount("/favicon.ico" => sub ($env) {
      my $res = [ 200, [ 'Content-Type' => 'image/vnd.microsoft.icon' ], [ '' ] ];
      $res->[2]->[0] = path(dist_share(__PACKAGE__))->child('favicon.ico')->slurp_raw;
      push $res->[1]->@*, 'Content-Length' => length $res->[2]->[0];
      return $res;
    });
    $dedupe{"favicon.ico"} = 1;

    my $tt;

    foreach my $fspath (map { path($_) } @ARGV)
    {
      if(-r $fspath)
      {
        my $path = $fspath->basename;

        # make the URL path unique
        {
          my $suffix = '';
          my $i = 0;
          while($dedupe{"$path$suffix"})
          {
            $suffix = "-@{[ $i++ ]}";
          }

          $path .= $suffix;
          $dedupe{$path} = 1;
        }

        push @paths, "/$path/";

        my $subapp = Plack::App::Libarchive->new( archive => $fspath, @pa_la_args );

        $app->mount( "/$path/" => $subapp->to_app );

        $tt ||= $subapp->tt;
      }
      else
      {
        say STDERR "unable to read $fspath, skipping";
      }
    }

    unless($tt)
    {
      say STDERR "no archive file given!";
      return 2;
    }

    $app->mount("/" => sub ($env) {
      my $html;
      $tt->process('index.html.tt', {
        title    => 'archives',
        archives => [ sort grep { $_ ne 'favicon.ico' } keys %dedupe ],
      }, \$html);
      $html = encode('UTF-8', $html, Encode::FB_CROAK);
      return [ 200, [ 'Content-Type' => 'text/html; charset=utf-8', 'Content-Length' => length $html ], [ $html ] ];
    });

  }

  $runner->run($app->to_app);

  return 0;
}

sub _random_port ($)
{
  IO::Socket::INET->new(
    Listen => 5,
    LocalAddr => '127.0.0.1',
  )->sockport;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::tarweb - Open an archive file in your web browser!

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 $ tarweb foo.tar.gz

=head1 DESCRIPTION

This class just contains the machinery of the L<tarweb> application.

=head1 SEE ALSO

=over 4

=item L<tarweb>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
