package Bot::BasicBot::Pluggable::WithConfig;

use strict;
use warnings;
our $VERSION = '0.03';

use base qw(Bot::BasicBot::Pluggable);
use YAML;
use Carp;

sub new_with_config {
    my $class = shift;
    my %args  = @_;
    croak 'config param must be set!!' unless $args{config};
    my $conf = YAML::LoadFile( $args{config} )
        or croak "Can't load a config file:" . $args{config};

    my @modules = @{ delete $conf->{modules} || [] };
    my $bot = $class->new( %{ $conf || {} } );

    foreach my $module (@modules) {
        $bot->load( $module->{module}, $module->{config} );
    }

    $bot;
}

sub load {
    my $self          = shift;
    my $module        = shift;
    my $module_config = shift;

    # it's safe to die here, mostly this call is evaled
    die "Need name" unless $module;
    die "Already loaded" if $self->handler($module);

    # This is possible a leeeetle bit evil.
    print STDERR "Loading module '$module'.. ";
    my $file = "Bot/BasicBot/Pluggable/Module/$module.pm";
    $file = "./modules/$module.pm" if ( -e "./modules/$module.pm" );
    print STDERR "from file $file\n";

    # force a reload of the file (in the event that we've already loaded it)
    no warnings 'redefine';
    delete $INC{$file};
    require $file;

    # Ok, it's very evil. Don't bother me, I'm working.

    my $m = "Bot::BasicBot::Pluggable::Module::$module"->new(
        Bot   => $self,
        Param => $module_config
    );

    die "->new didn't return an object" unless ( $m and ref($m) );
    die ref($m) . " isn't a $module" unless ref($m) =~ /\Q$module/;

    $self->add_handler( $m, $module );

    return $m;
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::WithConfig - initialize bot instance with YAML config

=head1 SYNOPSIS

Create a new Bot with YAML file.

  use Bot::BasicBot::Pluggable::WithConfig;

  my $bot = Bot::BasicBot::Pluggable->new_with_config(
    config => '/etc/pluggablebot.yaml'
  );

  ex) YAML configuration
  server:   irc.example.net
  port:     6667
  nick:     pluggablebot
  username: pluggablebot
  charset:  utf-8
  store:
    type:  Bot::BasicBot::Pluggable::Store::DBI
    dsn:   dbi:SQLite:dann.db
    table: pluggablebot
  modules:
    - module: Karma
    - module: Seen
    - module: Infobot
    - module: Title
  channels:
    - #pluggablebot

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::WithConfig is instance creator with config file

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
