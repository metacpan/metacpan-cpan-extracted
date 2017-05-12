package App::Charon::Web;
$App::Charon::Web::VERSION = '0.001003';
# ABSTRACT: Internal (for now) Plack app behind charon

use utf8;
use Web::Simple;
use warnings NONFATAL => 'all';

use Plack::App::Directory;
use Plack::App::File;

has _quit => (
   is => 'ro',
   required => 1,
   init_arg => 'quit',
);

has _root => (
   is => 'ro',
   default => '.',
   init_arg => 'root',
);

has _query_param_auth => (
   is => 'ro',
   default => sub {
      require App::Genpass;
      [auth => scalar App::Genpass->new->generate]
   },
   init_arg => 'query_param_auth',
);

has _show_index => (
   is => 'ro',
   default => 1,
   init_arg => 'show_index',
);

sub BUILDARGS {
   my ($self, %params) = @_;

   $params{query_param_auth} = [split m/=/, $params{query_param_auth}, 2]
      if exists $params{query_param_auth};

   \%params
}

has _root_server => (
   is => 'ro',
   lazy => 1,
   builder => sub {
      my $self = shift;

      if ($self->_show_index) {
         my $ret = Plack::App::Directory->new( root => $self->_root );
         $ret = Plack::Middleware::FixLinks->new(
            suffix => '?' . join('=', @{$self->_query_param_auth}),
         )->wrap($ret) if @{$self->_query_param_auth};
         return $ret
      } else {
         return Plack::App::File->new( root => $self->_root )
      }
   },
);

sub dispatch_request {
   my $self = shift;

   my @qpa = @{$self->_query_param_auth};
   (@qpa ? ( "?$qpa[0]~" => sub {
      my ($self, $value) = @_;

      return [403, ['Content-Type' => 'text/plain'], ['nice try']]
         if !$value || $value ne $qpa[1];
      return;
   }) : ()),
   '/quit' => sub { shift->_quit->done(1); [200, [], ''] },
   '/_/...' => sub { $self->_root_server },
}

1;

BEGIN {
   package Plack::Middleware::FixLinks;
$Plack::Middleware::FixLinks::VERSION = '0.001003';
   use parent qw(Plack::Middleware);

   use Plack::Util;
   use HTML::Zoom;
   use Plack::Util::Accessor qw(suffix);
   use Plack::Response;

   sub call {
      my($self, $env) = @_;

      my $res = $self->app->($env);

      my $response = Plack::Response->new(@$res);
      return $res unless $response->content_type eq 'text/html';
      return $self->response_cb($res, sub {
         my $res = shift;

         my $hz;

         if (ref $res->[2] eq 'ARRAY') {
            $hz = HTML::Zoom->from_html($res->[2][0])
         } else {
            local $/ = undef;
            my $fh = $res->[2];
            $hz = HTML::Zoom->from_html(<$fh>)
         }

         $res->[2] = $hz
           ->select('a')
           ->transform_attribute(href => sub { $_[0] . $self->suffix })
           ->to_fh;

         return;
      });
   }

   1
}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Charon::Web - Internal (for now) Plack app behind charon

=head1 VERSION

version 0.001003

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
