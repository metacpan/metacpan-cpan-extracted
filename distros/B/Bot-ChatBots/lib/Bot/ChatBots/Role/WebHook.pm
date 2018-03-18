package Bot::ChatBots::Role::WebHook;
use strict;
use warnings;
{ our $VERSION = '0.014'; }

use Ouch;
use Mojo::URL;
use Log::Any qw< $log >;
use Scalar::Util qw< blessed weaken refaddr >;
use Bot::ChatBots::Weak;
use Try::Tiny;

use Moo::Role;

with 'Bot::ChatBots::Role::Source';
requires 'process_updates';

has app => (
   is       => 'ro',
   lazy     => 1,
   weak_ref => 1,
);

has code => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_code',
);

has method => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_method',
);

has path => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_path',
);

has _flags_tracker => (
   is => 'ro',
   lazy => 1,
   builder => '_BUILD_flags_tracker',
);

has url => (is => 'ro');

sub BUILD_code { return 204 }

sub BUILD_method { return 'post' }

sub BUILD_path {
   my $self = shift;
   defined(my $url = $self->url)
     or ouch 500, 'undefined path and url for WebHook';
   return Mojo::URL->new($url)->path->to_string;
} ## end sub BUILD_path

sub _BUILD_flags_tracker {
   my $self = shift;
   $self->app->hook(after_dispatch => sub {
      $self->_set_flags_rendered(@_);
   });
   return {};
}

sub _track_flags {
   my ($self, $c, $flags) = @_;
   $self->_flags_tracker->{refaddr($c)} = $flags;
   return $self;
}

sub _set_flags_rendered {
   my ($self, $c) = @_;
   $self->_flags_tracker->{refaddr($c)}{rendered} = 1;
   return $self;
}

sub _forget_flags {
   my ($self, $c) = @_;
   my $rt = $self->_flags_tracker;
   delete $rt->{refaddr($c)};
   return $self;
}

sub handler {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};

   return sub {
      my $c = shift;
      my $c_address = refaddr $c;

      # whatever happens, the bot "cannot" fail or the platform will hammer
      # us with the same update over and over
      my @updates;
      try {
         @updates = $self->parse_request($c->req);
      }
      catch {
         $log->error(bleep $_);
         die $_ if $self->should_rethrow($args);
      };

      my %flags = (rendered => 0);
      $self->_track_flags($c => \%flags);
      my @retval = $self->process_updates(
         refs => {
            app        => $self->app,
            controller => $c,
            stash      => $c->stash,
         },
         source_pairs => {
            flags => \%flags,
         },
         updates => \@updates,
         %$args,    # may override it all!
      );
      $self->_forget_flags($c);

      # did anyone set the flag? Otherwise stick to the safe side
      return $flags{rendered} || $c->rendered($self->code);
   };
} ## end sub handler

sub install_route {
   my $self   = shift;
   my $args   = (@_ && ref($_[0])) ? $_[0] : {@_};
   my $method = lc($args->{method} // $self->method // 'post');
   my $r      = $args->{routes} // $self->app->routes;
   my $p      = $args->{path} // $self->path;
   my $h      = $args->{handler} // $self->handler($args);
   return $r->$method($p => $h);
} ## end sub install_route

sub parse_request { # most APIs rely on JSON... let's leverage this
   my ($self, $req) = @_;
   return $req->json;
}

1;
