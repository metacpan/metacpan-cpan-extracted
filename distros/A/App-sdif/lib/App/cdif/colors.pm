=head1 NAME

App::cdif::colors

=head1 SYNOPSIS

  cdif -Mcolors --light
  cdif -Mcolors --green
  cdif -Mcolors --cmy
  cdif -Mcolors --mono

  cdif -Mcolors --dark
  cdif -Mcolors --dark-green
  cdif -Mcolors --dark-cmy
  cdif -Mcolors --dark-mono

=head1 SEE ALSO

L<App::cdif::colors>

=cut

package App::cdif::colors;

1;

__DATA__

define {NOP} $<move(0,0)>
option --light {NOP}
option --green --light
option --cmy   --light

option --dark	--cm APPEND=DELETE=w/311,*CHANGE=w/112 \
		--cm OTEXT=244,NTEXT=313 \
		--cm OMARK=244S,NMARK=424S \
		--cm COMMAND=K/WE

option --dark-cmy   --dark
option --dark-green --dark

option --mono	--cm APPEND=DELETE=555/333,*CHANGE=000/444 \
		--cm OTEXT=K/444,NTEXT=w/222 \
		--cm OMARK=K/333,NMARK=w/111

option --dark-mono \
		--cm APPEND=DELETE=w/L10,*CHANGE=K/222 \
		--cm OTEXT=K/444,NTEXT=w/111 \
		--cm OMARK=K/333,NMARK=w/222
