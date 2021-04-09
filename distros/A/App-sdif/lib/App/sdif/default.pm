package App::sdif::default;

1;

__DATA__

option --nop $<ignore>

option --autocolor -Mtermcolor::bg(light=--light,dark=--dark)
option default --autocolor

autoload -Mcolors \
	--light --green --cmy --mono \
	--dark --dark-green --dark-cmy --dark-mono
