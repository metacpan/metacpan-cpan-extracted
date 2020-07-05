CC=wacc
CFLAGS=-Wl,--allow-undefined
CDLFLAGS=-Wl,--no-entry -Wl,--export-dynamic
RM=rm -f
PERL=perl
PLASM=../../bin/plasm

run: foo.wasm lib/Bar/Baz.wasm
	$(PERL) -Ilib $(PLASM) foo.wasm

foo.wasm: foo.c
	$(CC) $(CFLAGS) -o foo.wasm foo.c

lib/Bar/Baz.wasm: lib/Bar/Baz.c
	$(CC) $(CFLAGS) $(CDLFLAGS) -o lib/Bar/Baz.wasm lib/Bar/Baz.c

clean:
	$(RM) *.wasm lib/Bar/*.wasm
