package Bot::Cobalt::Plugin::Games::Dice;
$Bot::Cobalt::Plugin::Games::Dice::VERSION = '0.021003';
use v5.10;
use strictures 2;

use Bot::Cobalt::Utils 'color';

sub new { bless [], shift }

sub execute {
  my ($self, $msg, $str) = @_;
  return "Syntax: roll XdY  [ +/- <modifier> ]" unless $str;

  my ($dice, $modifier, $modify_by) = split ' ', $str;

  if ($dice =~ /^(\d+)?d(\d+)?$/i) {  ## Xd / dY / XdY syntax
    my $n_dice = $1 || 1;
    my $sides  = $2 || 6;

    my @rolls;
    $n_dice = 10    if $n_dice > 10;
    $sides  = 10000 if $sides > 10000;

    until (@rolls == $n_dice) {
      push @rolls, (int rand $sides) + 1;
    }
    my $total;
    $total += $_ for @rolls;

    $modifier = undef unless $modify_by and $modify_by =~ /^\d+$/;
    if ($modifier) {
        $modifier eq '+' ? $total += $modify_by
      : $modifier eq '-' ? $total -= $modify_by
      : ()
    }


    my $resp = "Rolled "
               .color('bold', $n_dice)
               .($sides > 1 ? ' dice of ' : ' die of ')
               .color('bold', $sides)
               ." sides: " . join ' ', @rolls;
    my $potential = $n_dice * $sides;
    $resp .= " [total: ".color('bold', $total)." / $potential]";
    return $resp
  }

  if ($dice =~ /^\d+$/) {
    my $total = (int rand $dice) + 1;
    $modifier = undef unless $modify_by and $modify_by =~ /^\d+$/;
    if ($modifier) {
        $modifier eq '+' ? $total += $modify_by
      : $modifier eq '-' ? $total -= $modify_by
      : ()
    }
    my $resp =  "Rolled single die of "
                .color('bold', $dice)
                ." sides: "
                .color('bold', $total) ;
    return $resp
  }

  "Syntax: roll XdY  [ +/- <modifier> ]"
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Games::Dice - IRC dice roller

=head1 SYNOPSIS

  !roll 6     # Roll a six-sided die
  !roll 2d6   # Roll a pair of them
  !roll 6d10  # Roll weird dice

=head1 DESCRIPTION

Simple dice bot; accepts either the number of sides as a simple integer 
or XdY syntax.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
