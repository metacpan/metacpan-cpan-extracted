CC=wacc
CFLAGS=-Wl,--allow-undefined
RM=rm -f
PERL=perl
PLASM=../../bin/plasm

run: foo.wasm
	$(PERL) -Ilib $(PLASM) foo.wasm

foo.wasm: foo.c
	$(CC) $(CFLAGS) -o foo.wasm foo.c

clean:
	$(RM) *.wasm *.o
