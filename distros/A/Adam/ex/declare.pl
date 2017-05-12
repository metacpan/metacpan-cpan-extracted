use lib qw(lib);
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
