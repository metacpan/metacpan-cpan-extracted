use MooseX::Declare;
# Dist::Zilla: -PodWeaver

class Moses::Declare extends MooseX::Declare {
    use aliased 'Moses::Declare::Syntax::BotKeyword';
    use aliased 'Moses::Declare::Syntax::PluginKeyword';
    around keywords( ClassName $self: ) {
        $self->$orig,
        BotKeyword->new( identifier => 'bot' ),
        PluginKeyword->new( identifier => 'plugin' ),
    };
}

__END__

=head1 SYNOPSIS

  use Moses::Declare;

  bot MasterMold {
    server 'irc.perl.org';
    channels '#moses';

    has message => (
      isa     => 'Str',
      is      => 'ro',
      default => 'Mutant Detected!',
    );

    on irc_bot_addressed( Str $nickstr, ArrayRef $channels, Str $message) {
      my ($nick) = split /!/, $nickstr;
      $self->privmsg( $channels => "$nick: ${ \$self->message }" );
    };
  }

  my @bots = map { MasterMold->new( nickname => "Sentinel_${_}" ) } ( 1 .. 2 );

  POE::Kernel->run;
