package Bot::BasicBot::Pluggable::Module::Nickometer;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);


use Math::Trig;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);
    return unless  $body =~ /^\s*(?:lame|nick)-?o-?meter(?: for)? (\S+)/i;

    my $term = $1; $term = $who if (lc($term) eq 'me');

    
    my $percentage = percentage($term);
    

    if ($percentage =~ /NaN/) {
           $percentage = "off the scale";
    } else {
        #    $percentage = sprintf("%0.4f", $percentage);
        $percentage =~ s/\.0+$//;
        $percentage .= '%';
    }
    
    return "'$term' is $percentage lame, $who";
}

sub help {
    return "Commands: 'nickometer <nick>'";
}


sub percentage {
    local $_ = shift;

    my $score = 0;
    
    # Deal with special cases (precede with \ to prevent de-k3wlt0k)
    my %special_cost = (
                      '69'                      => 500,
                      'dea?th'                  => 500,
                      'dark'                    => 400,
                      'n[i1]ght'                => 300,
                      'n[i1]te'                 => 500,
                      'fuck'                    => 500,
                      'sh[i1]t'                 => 500,
                      'coo[l1]'                 => 500,
                      'kew[l1]'                 => 500,
                      'lame'                    => 500,
                      'dood'                    => 500,
                      'dude'                    => 500,
                      '[l1](oo?|u)[sz]er'       => 500,
                      '[l1]eet'                 => 500,
                      'e[l1]ite'                => 500,
                      '[l1]ord'                 => 500,
                      'pron'                    => 1000,
                      'warez'                   => 1000,
                      'xx'                      => 100,
                      '\[rkx]0'                 => 1000,
                      '\0[rkx]'                 => 1000,
                     );



    foreach my $special (keys %special_cost) {
        my $special_pattern = $special;
        my $raw = ($special_pattern =~ s/^\\//);
        my $nick = $_;
          $nick =~ tr/023457+8/ozeasttb/ unless $raw;
        $score += $special_cost{$special} if $nick =~ /$special_pattern/i;
      }
  
      # Allow Perl referencing
      s/^\\([A-Za-z])/$1/;
  
      # Keep me safe from Pudge ;-)
      s/\^(pudge)/$1/i;

      # C-- ain't so bad either
      s/^C--$/C/;
  
      # Punish consecutive non-alphas
      s/([^A-Za-z0-9]{2,})
        /my $consecutive = length($1);
         $score += slow_pow(10, $consecutive) if $consecutive;
      $1
     /egx;

      # Remove balanced brackets and punish for unmatched
      while (s/^([^()]*)   (\() (.*) (\)) ([^()]*)   $/$1$3$5/x ||
           s/^([^{}]*)   (\{) (.*) (\}) ([^{}]*)   $/$1$3$5/x ||
           s/^([^\[\]]*) (\[) (.*) (\]) ([^\[\]]*) $/$1$3$5/x) 
      {}
      my $parentheses = tr/(){}[]/(){}[]/;
      $score += slow_pow(10, $parentheses) if $parentheses;

      # Punish k3wlt0k
      my @k3wlt0k_weights = (5, 5, 2, 5, 2, 3, 1, 2, 2, 2);
      for my $digit (0 .. 9) {
        my $occurrences = s/$digit/$digit/g || 0;
        $score += ($k3wlt0k_weights[$digit] * $occurrences * 30) if $occurrences;
      }

      # An alpha caps is not lame in middle or at end, provided the first
      # alpha is caps.
      my $orig_case = $_;
      s/^([^A-Za-z]*[A-Z].*[a-z].*?)[_-]?([A-Z])/$1\l$2/;
  
      # A caps first alpha is sometimes not lame
      s/^([^A-Za-z]*)([A-Z])([a-z])/$1\l$2$3/;


      # Punish uppercase to lowercase shifts and vice-versa, modulo 
      # exceptions above
      my $case_shifts = case_shifts($orig_case);
      $score += slow_pow(9, $case_shifts) if ($case_shifts > 1 && /[A-Z]/);

      # Punish lame endings (TorgoX, WraithX et al. might kill me for this :-)
      $score += 50 if $orig_case =~ /[XZ][^a-zA-Z]*$/;

      # Punish letter to numeric shifts and vice-versa
      my $number_shifts = number_shifts($_);
      $score += slow_pow(9, $number_shifts) if $number_shifts > 1;

      # Punish extraneous caps
      my $caps = tr/A-Z/A-Z/;
      $score += slow_pow(7, $caps) if $caps;

      # Now punish anything that's left
      my $remains = $_;
      $remains =~ tr/a-zA-Z0-9//d;
      my $remains_length = length($remains);

      $score += (50 * $remains_length + slow_pow(9, $remains_length)) if $remains;

      # Use an appropriate function to map [0, +inf) to [0, 100)
      my $percentage = 100 * 
                     (1 + tanh(($score-400)/400)) * 
                     (1 - 1/(1+$score/5)) / 2;

      my $digits = 2 * (2 - &round_up(log(100 - $percentage) / log(10)));

      return sprintf "%.${digits}f", $percentage;

}

sub case_shifts ($) {
  # This is a neat trick suggested by freeside.  Thanks freeside!

  my $shifts = shift;

  $shifts =~ tr/A-Za-z//cd;
  $shifts =~ tr/A-Z/U/s;
  $shifts =~ tr/a-z/l/s;

  return length($shifts) - 1;
}

sub number_shifts ($) {
  my $shifts = shift;

  $shifts =~ tr/A-Za-z0-9//cd;
  $shifts =~ tr/A-Za-z/l/s;
  $shifts =~ tr/0-9/n/s;

  return length($shifts) - 1;
}

sub slow_pow ($$) {
  my ($x, $y) = @_;

  return $x ** slow_exponent($y);
}


sub slow_exponent ($) {
  my $x = shift;

  return 1.3 * $x * (1 - atan($x/6) *2/pi);
}

sub round_up ($) {
  my $float = shift;

  return int($float) + ((int($float) == $float) ? 0 : 1);
}




1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Nickometer - check how lame a nick is 

=head1 IRC USAGE

    nickometer <nick>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

based on code by Adam Spiers <adam.spiers@new.ox.ac.uk>


=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

