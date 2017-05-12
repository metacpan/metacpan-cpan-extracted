SAYIT	= echo Making $@ from $^
MAKEIT	= perl -e "open(OUT,qq(>$@)); print OUT qq($@\n)"
DOITALL = $(SAYIT) && $(MAKEIT)

%.o: %.c
	@$(SAYIT)
	@$(MAKEIT)
