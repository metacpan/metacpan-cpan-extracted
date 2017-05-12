# $Id: CPANXR.pm,v 1.3 2003/09/28 08:09:30 clajac Exp $

package Bot::BasicBot::Pluggable::Module::CPANXR;
use CPANXR::Database;
use Bot::BasicBot::Pluggable::Module::Base;
use base qw(Bot::BasicBot::Pluggable::Module::Base);
use strict;

sub said {
  my ($self, $mess, $pri) = @_;

  return unless $mess->{address} && $pri == 2;

  my $body = $mess->{body};
  my $who = $mess->{who};
  my $channel = $mess->{channel};

  if($body =~ /^find\s+subroutine\s+(.*?)$/) {
    my $symbol_name = $1;
    my $symbol_id = CPANXR::Database->select_symbol_by_name($symbol_name)->[0]->[0];
    if($symbol_id >= 0) {
      my $result = CPANXR::Database->select_declarations(symbol_id => $symbol_id);
      if(@$result) {
	my $result_str = "I found '$symbol_name' in ";
	foreach my $ent(@$result) {
	  $result_str .= "$ent->[4] at line $ent->[2], "
	}
	chop $result_str;
	chop $result_str;
	return $result_str;
      } else {
	return "Can't find subroutine '$symbol_name'";
      }
    } 
    return "Sorry, can't find symbol '$symbol_name'";
  }
  
  return "questa?";
}

1;
