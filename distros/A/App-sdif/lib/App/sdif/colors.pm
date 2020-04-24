=head1 NAME

App::sdif::colors

=head1 SYNOPSIS

  sdif -Mcolors --light
  sdif -Mcolors --green
  sdif -Mcolors --cmy
  sdif -Mcolors --mono

  sdif -Mcolors --dark
  sdif -Mcolors --dark-green
  sdif -Mcolors --dark-cmy
  sdif -Mcolors --dark-mono

=head1 DESCRIPTION

Read `perldoc -m App::sdif::colors` to see the actual definition.

Option B<--light> or B<--dark> is set by B<--autocolor> option which
calls B<-Mtermcolor> module to determine the brightness of the
terminal screen.  You can override them in your F<~/.sdifrc> like:

    option --light --cmy
    option --dark  --dark-cmy

=head1 SEE ALSO

L<Getopt::EX::termcolor>

=cut

package App::sdif::colors;

1;

__DATA__

option --light $<move(0,0)>
option --dark  --dark-green

option	--green \
	--cm ?COMMAND=555/010;		\
	--cm    ?FILE=551/010;D		\
	--cm    ?MARK=010/444		\
	--cm    UMARK=			\
	--cm    ?LINE=220		\
	--cm    ?TEXT=K/454		\
	--cm    UTEXT=

define <C> 033
define <M> 303
define <Y> 330
option	--cmy \
	--cm OCOMMAND=555/<C>	\
	--cm NCOMMAND=555/<M>	\
	--cm MCOMMAND=555/<Y>	\
	--cm    OFILE=550/<C>;D	\
	--cm    NFILE=550/<M>;D	\
	--cm    MFILE=550/<Y>;D	\
	--cm    OMARK=<C>/444	\
	--cm    NMARK=<M>/444	\
	--cm    MMARK=<Y>/444	\
	--cm    UMARK=/444	\
	--cm    ?LINE=220	\
	--cm    ?TEXT=K/554	\
	--cm    UTEXT=

option	--mono \
	--cm ?COMMAND=L24/111;	\
	--cm    ?FILE=L25/111;D	\
	--cm    ?MARK=L00/333	\
	--cm    UMARK=		\
	--cm    ?LINE=222	\
	--cm    ?TEXT=000/L24	\
	--cm    UTEXT=111	\
	--cdifopts='--mono'

define {DARK_BG1} L11
define {DARK_BG2} L05

expand	--dark-screen \
	--cm    ?MARK=000/{DARK_BG1}	\
	--cm    UMARK=			\
	--cm    ?TEXT=L24/{DARK_BG2}	\
	--cm    UTEXT=L23

option	--dark-green \
	--dark-screen 			\
	--cm OTEXT=NTEXT=MTEXT=+353	\
	--cm ?COMMAND=000/232;		\
	--cm    ?FILE=000/232;D		\
	--cm    ?LINE=220		\
	--cdifopts='--dark-green --cm APPEND=DELETE=?CHANGE=+353'

option	--dark-cmy \
	--dark-screen			\
	--cm OCOMMAND=000/122		\
	--cm    OFILE=000/122;D		\
	--cm NCOMMAND=000/313		\
	--cm    NFILE=000/313;D		\
	--cm MCOMMAND=000/332		\
	--cm    MFILE=000/332;D		\
	--cm    ?LINE=220		\
	--cdifopts='--dark-cmy'

option	--dark-mono \
	--dark-screen			\
	--cm ?COMMAND=555/{DARK_BG1}	\
	--cm    ?FILE=D/{DARK_BG1}	\
	--cm    ?LINE=111		\
	--cdifopts='--dark-mono'

##
## for backward compatibility
##
option --dark_green --dark-green
option --dark_cmy   --dark-cmy
option --dark_mono  --dark-mono
