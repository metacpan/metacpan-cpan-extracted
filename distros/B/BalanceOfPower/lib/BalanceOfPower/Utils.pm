package BalanceOfPower::Utils;
$BalanceOfPower::Utils::VERSION = '0.400115';
use BalanceOfPower::Constants ':all';
use Term::ANSIColor;

use strict;
use warnings;

use base 'Exporter';

sub prev_turn
{
    my $year = shift;
    my ($y, $i) = split '/', $year;
    $i ||= 1;
    if($i == 1)
    {
        return ($y -1) . '/' . TURNS_FOR_YEAR;
    }
    else
    {
        return $y . '/' . ($i - 1);
    }
}
sub next_turn
{
    my $year = shift;
    my ($y, $i) = split '/', $year;
    if($i == TURNS_FOR_YEAR)
    {
        return ($y +1) . '/' . '1';
    }
    else
    {
        return $y . '/' . ($i + 1);
    }
}
sub get_year_turns
{
    my $year = shift;
    return ($year) if($year =~ /\d+\/\d+/);
    my @turns = ();
    for(my $i = 1; $i<= TURNS_FOR_YEAR; $i++)
    {
        push @turns, $year . '/' . $i;
    }
    return @turns;
}
sub split_turn
{
    my $turn = shift;
    if($turn =~ /(\d+)(\/(\d+))?/)
    {
        my $turn_y = $1;
        my $turn_t = $3 ? $3 : 1;
        return ($turn_y, $turn_t);
    }
    else
    {
        (undef, undef);
    }
}
sub from_to_turns
{
    my $from = shift;
    my $to = shift;
    my ($from_y, $from_t) = split_turn($from);
    return () if(! $from_y);
    my ($to_y, $to_t) = split_turn($to);
    return () if(! $from_y);
    return ()
        if($to_y < $from_y || ($to_y == $from_y && $to_t < $from_t)); 
    my $goon = 1;
    my $to_add_y = $from_y;
    my $to_add_t = $from_t;
    my @turns = ();
    while(1)
    {
        my $to_add = $to_add_y . '/' . $to_add_t;
        push @turns, $to_add;
        last if($to_add eq $to);
        if($to_add_t < TURNS_FOR_YEAR)
        {
            $to_add_t++;
        }
        else
        {
            $to_add_y++;
            $to_add_t = 1;
        }
    }
    return @turns;
}




# first < second  -> -1
# first = second  -> 0
# first > second  -> 1
#
sub compare_turns
{
    my $first = shift;
    my $second = shift;
    return 0 if ($first eq $second);
    my ($first_y, $first_t) = split_turn($first);
    return undef if(! $first_y);
    my ($second_y, $second_t) = split_turn($second);
    return undef if(! $second_y);
    return 0 if($first_y == $second_y && $first_t == $second_t);
    return undef
        if($first_t < 0 ||
           $second_t < 0 ||
           $first_t > TURNS_FOR_YEAR ||
           $second_t > TURNS_FOR_YEAR);
    if($first_y > $second_y ||
      (($first_y == $second_y && $first_t > $second_t)))
    {
        return 1;
    }
    else
    {
        return -1;
    }
}
sub evidence_text
{
    my $text = shift;
    my $key = shift;
  	$text =~ s/($key)/as_evidenced($1)/eg;
    return $text;
}

sub as_main_title
{
    my $text = shift;
    my $mode = shift;
    if($mode eq 'print')
    {
        return as_title("$text\n===\n");
    }
    elsif($mode eq 'html')
    {
        return as_html_title($text);
    }
}
sub as_main_subtitle
{
    my $text = shift;
    my $mode = shift;
    if($mode eq 'print')
    {
        return "### $text\n";
    }
    elsif($mode eq 'html')
    {
        return "<h4>$text</h4>";
    }
}

sub as_title
{
    my $text = shift;
    return color("yellow bold") . $text . color("reset");
}
sub as_html_title
{
    my $text = shift;
    return "<h3>$text</h3>";
}
sub as_html_dangerous
{
    my $text = shift;
    return '<span class="dangerous">' . $text . '</span>';
}
sub as_html_evidenced
{
    my $text = shift;
    return '<span class="evidenced">' . $text . '</span>';
}
sub as_html_box
{
    my $text = shift;
    return "<p>$text</p>";
}
sub as_subtitle
{
    my $text = shift;
    return color("yellow") . $text . color("reset");
}
sub as_evidenced
{
    my $text = shift;
    return color("bold green") . $text . color("reset");
}
sub as_active
{
    my $text = shift;
    return color("bold white") . $text . color("reset");
}
sub br
{
    my $mode = shift;
    if($mode eq 'print')
    {
        return "\n";
    }
    elsif($mode eq 'html')
    {
        return "<br />";
    }
}

our @EXPORT_OK = ('prev_turn', 'next_turn', 'random', 'random10', 'get_year_turns', 'as_title', 'from_to_turns', 'compare_turns', 'as_subtitle', 'evidence_text', 'as_evidenced', 'as_active', 'as_html_title', 'as_html_box', 'as_html_dangerous', 'as_html_evidenced', 'as_main_title', 'as_main_subtitle', 'br');

1;
