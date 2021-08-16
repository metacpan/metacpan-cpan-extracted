package App::week::default;
use utf8;
1;
__DATA__

autoload -Mcolors --mono --green --lavender --pastel

autoload -Mnpb \
	--giants --giants-rev \
	--tigers --tigers-rev \
	--lions --lions-rev --lions2 --lions2-rev --lions3 --lions3-rev

autoload -Molympic \
	--olympic-dow    --olympic-dow-rev \
	--tokyo2020      --tokyo2020-rev \
	--tokyo2020-gold --tokyo2020-gold-rev \
	--gold-frame

option --themecolor::bg \
	-Mtermcolor::bg(default=100,light=--$<shift>,dark=--$<shift>-rev)

option --theme --themecolor::bg $<copy(0,1)>

option --i18n   -Mi18n::setopt(dash=0,long=0,listopt=-l)
option --i18n-v -Mi18n::setopt(dash=0,long=0,listopt=-l,verbose)

autoload --i18n -l
