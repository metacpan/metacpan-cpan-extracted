# PODNAME: Moses::Declare
# ABSTRACT: MooseX::Declare syntax for Moses bots

use MooseX::Declare;

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

=pod

=encoding UTF-8

=head1 NAME

Moses::Declare - MooseX::Declare syntax for Moses bots

=head1 VERSION

version 1.002

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

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/perigrin/adam-bot-framework/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
