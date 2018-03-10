package Bot::ChatBots::MojoPlugin;
use strict;
use warnings;
{ our $VERSION = '0.012'; }

use Bot::ChatBots::Utils qw< load_module >;

use Mojo::Base 'Mojolicious::Plugin';

has [qw< app instances >];

sub helper_name {
   my $self = shift;
   (my $name = lc(ref $self || $self)) =~ s{.*::}{}mxs;
   return "chatbots.$name";
}

sub add_instance {
   my $self     = shift;
   my $module   = load_module(shift, ref $self);
   my @args     = (@_ && ref($_[0])) ? %{$_[0]} : @_;
   my $instance = $module->new(@args, app => $self->app);
   push @{$self->instances}, $instance;
   return $instance;
} ## end sub add_instance

sub register {
   my ($self, $app, $conf) = @_;
   $conf //= {};
   my $helper_name = $conf->{helper_name} // $self->helper_name;

   # initialize object
   $self->app($app);
   $self->instances([]);

   # add helper to be usable
   $app->helper($helper_name => sub { return $self });

   # initialize with instances passed on the fly
   $self->add_instance(@$_) for @{$conf->{instances} // []};

   $app->log->debug("helper $helper_name registered");

   return $self;
} ## end sub register

1;
__END__
