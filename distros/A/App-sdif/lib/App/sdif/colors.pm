=head1 NAME

App::sdif::colors

=head1 SYNOPSIS

  sdif -Mcolors --green
  sdif -Mcolors --dark_green
  sdif -Mcolors --cmy
  sdif -Mcolors --dark_cmy
  sdif -Mcolors --mono
  sdif -Mcolors --dark_mono

=head1 SEE ALSO

L<App::sdif::osx_autocolor>

=cut

package App::sdif::colors;

1;

__DATA__

define :CDIF      APPEND=DELETE=K/545,*CHANGE=K/455
define :DARK_CDIF APPEND=DELETE=555/311,*CHANGE=555/113

option	--green \
	--cm ?COMMAND=010/555;S		\
	--cm    ?FILE=010/555;SD	\
	--cm    ?MARK=010/444		\
	--cm    UMARK=			\
	--cm    ?LINE=220		\
	--cm    ?TEXT=K/454		\
	--cm    UTEXT=			\
	--cdifopts '--cm :CDIF'

option	--dark_green \
	--cm ?COMMAND=555/121;		\
	--cm    ?FILE=555/121;D		\
	--cm    ?MARK=333/L05		\
	--cm    UMARK=			\
	--cm    ?LINE=220		\
	--cm    ?TEXT=555/L03		\
	--cm    UTEXT=444		\
	--cdifopts '--cm :DARK_CDIF'

option	--cmy \
	--cm OCOMMAND=C/555;S		\
	--cm NCOMMAND=M/555;S		\
	--cm MCOMMAND=Y/555;S		\
	--cm    OFILE=C/555;SD		\
	--cm    NFILE=M/555;SD		\
	--cm    MFILE=Y/555;SD		\
	--cm    OMARK=C/444		\
	--cm    NMARK=M/444		\
	--cm    MMARK=Y/444		\
	--cm    UMARK=/444		\
	--cm    ?LINE=Y			\
	--cm    ?TEXT=K/554		\
	--cm    UTEXT=			\
	--cdifopts '--cm :CDIF'

option	--dark_cmy \
	--cm OCOMMAND=555/011		\
	--cm NCOMMAND=555/202		\
	--cm MCOMMAND=555/110		\
	--cm    OFILE=555/011;D		\
	--cm    NFILE=555/202;D		\
	--cm    MFILE=555/K;D		\
	--cm    ?MARK=333/L05		\
	--cm    UMARK=			\
	--cm    ?LINE=110		\
	--cm    ?TEXT=555/L03		\
	--cm    UTEXT=			\
	--cdifopts '--cm :DARK_CDIF'

option	--mono \
	--cm ?COMMAND=111;S	\
	--cm    ?FILE=111;DS	\
	--cm    ?MARK=000/333	\
	--cm    UMARK=		\
	--cm    ?LINE=222	\
	--cm    ?TEXT=000/L23	\
	--cm    UTEXT=111	\
	--cdifopts '--cm APPEND=DELETE=555/333,*CHANGE=000/444'

option	--dark_mono \
	--cm ?COMMAND=333;S	\
	--cm    ?FILE=333;DS	\
	--cm    ?MARK=000/333	\
	--cm    UMARK=		\
	--cm    ?LINE=333	\
	--cm    ?TEXT=555/L03	\
	--cm    UTEXT=444	\
	--cdifopts '--cm APPEND=DELETE=555/111,*CHANGE=000/222'
