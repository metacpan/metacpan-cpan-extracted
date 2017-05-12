# 81UNMBE - Makefile for ximp (audio mixer utility) by PipStuart<Pip@CPAN.Org>
#$VERSION = '1.0.81UNPNp'
#CFLAGS  = -s -O2 -DLINUX
#CFLAGS  = -s -O6 -DLINUX -march=pentium
CFLAGS  = -s -O6 -DLINUX -march=athlon64 -pipe -msse3
NAME    = ximp
LNAME   = $(NAME)
INSTALL = install

$(NAME): $(NAME).o
	cc $(CFLAGS) -o $(NAME) $(NAME).o $(LIBS)
	@echo "### Compiling of $(NAME) complete! ###"

$(NAME).o: $(NAME).c
	@echo "####### Now compiling $(NAME)! #######"
	cc $(CFLAGS) -c $(NAME).c

clean:
	rm *.o $(NAME)

install: $(NAME)
	$(INSTALL) -m 775 $(NAME) /usr/local/bin/

tar:
	cd .. && tar cf - $(LNAME)/ | gzip -9 > $(LNAME)/$(LNAME).tgz
