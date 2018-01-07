package App::sdif::default;

1;

__DATA__

option --nop $<move(0,0)>

option --autocolor -Mautocolor
option default --autocolor

autoload -Mcolors \
	--light --green --cmy --mono \
	--dark --dark-green --dark-cmy --dark-mono
