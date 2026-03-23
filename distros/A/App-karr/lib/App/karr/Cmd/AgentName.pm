# ABSTRACT: Generate a random two-word agent name

package App::karr::Cmd::AgentName;
our $VERSION = '0.101';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr agentname',
);


sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  my @words = $self->_load_words;
  my $name = $words[rand @words] . '-' . $words[rand @words];
  print "$name\n";
}

sub _load_words {
  my ($self) = @_;
  my @words;

  # Try system dictionary first
  if (-r '/usr/share/dict/words') {
    open my $fh, '<', '/usr/share/dict/words' or last;
    while (<$fh>) {
      chomp;
      push @words, lc $_ if /^[a-z]{4,8}$/i;
    }
    close $fh;
  }

  # Fallback word list
  unless (@words) {
    @words = qw(
      able acid aged also area army away baby back ball band bank base bath
      bear beat been bell best bill bird bite blow blue boat body bomb bond
      bone book born boss bulk burn busy cake call calm came camp card care
      cash cast cell chat chip city claim clan clay clip club coal coat code
      coin cold come cook cool cope copy core cost crew crop dark data date
      dawn dead deal dear debt deep deny desk diet dirt disc disk dock does
      done door dose down draw drew drop drug dual duke dull dust duty each
      earn ease east easy edge else even ever evil exam exec face fact fail
      fair fall fame farm fast fate fear feed feel fell file fill film find
      fine fire firm fish five flat fled flew flip flow fold folk fond font
      food foot ford form fort four free from fuel full fund gain game gang
      gate gave gear gift girl give glad goal goes gold golf gone good grab
      gray grew grid grip grow gulf guru hack half hall hand hang harm hate
      have head hear heat held help herb here hero high hill hint hire hold
      hole holy home hope host hour huge hung hunt hurt idea inch into iron
      item jack jean jobs join joke jump jury just keen keep kept kick kill
      kind king knew knit know lack laid lake lamp land lane last late lawn
      lead lean left lend less life lift like limb line link lion list live
      load loan lock logo long look lord lose loss lost lots love luck made
      mail main make male many mark mass mate meal mean meat meet menu mere
      mild mile milk mind mine miss mode mood moon more most move much must
      myth name navy near neat neck need nest next nice nine none norm nose
      note odds once only onto open oral ours pace pack page paid pain pair
      pale palm park part pass past path peak pick pile pine pink pipe plan
      play plot plug plus poem poet poll pond pool poor port post pour pray
      pull pump pure push quit race rain rank rare rate read real rear rely
      rent rest rice rich ride ring rise risk road rock rode role roll roof
      room root rope rose ruin rule rush safe said sake sale salt same sand
      sang save seal seat seed seek seem seen self send sept ship shop shot
      show shut sick side sign silk site size skin slim slip slow snap snow
      soft soil sold sole some song soon sort soul spin spot star stay stem
      step stop such suit sure swim tail take tale talk tall tank tape task
      taxi team teen tell tend term test text than that them then they thin
      this thus tide tied till time tiny told toll tone took tool tops toss
      tour town trap tree trim trio trip true tube tuck tune turn twin type
      ugly unit upon urge used user vale vast very vice view vote wage wait
      wake walk wall want ward warm wash vast wave weak wear week went were
      west what whom wide wife wild will wind wine wing wire wise wish with
      wood word wore work worn wrap yard yeah year zero zone
    );
  }

  return @words;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::AgentName - Generate a random two-word agent name

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    karr agentname
    karr pick --claim "$(karr agentname)" --move in-progress

=head1 DESCRIPTION

Generates a random two-word, lowercase agent name joined by a hyphen. The
command prefers the system dictionary when available and falls back to the
built-in word list otherwise.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Handoff>,
L<App::karr::Cmd::Log>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
