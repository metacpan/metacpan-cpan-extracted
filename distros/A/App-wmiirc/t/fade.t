use Test::More;
use Moo;

with 'App::wmiirc::Role::Fade';

# Mocks
sub core { return __PACKAGE__ }
sub main_config { +{
    normcolors => '#000000 #ffffff #aaaaaa',
    alertcolors => '#ff0000 #ccccff #ffffaa',
  }
}

my $fader = __PACKAGE__->new;
is $fader->fade_current_color, main_config->{alertcolors};
my $i = 0;
do {
  $i++;
} while($fader->fade_next);
is $fader->fade_current_color, main_config->{normcolors};
is $i, $fader->fade_count;

done_testing;
