PERL = perl
.SUFFIXES: .png .pl
.SILENT:
OPTIONS = -Tw -I../lib
#OPTIONS = -Tw -I../lib -I/home/mgjv/perl/GD1.19

PNGS =  sample11.png sample12.png sample13.png sample14.png \
		sample15.png sample16.png \
		sample21.png \
		sample31.png \
		sample41.png sample42.png\
		sample51.png sample52.png sample53.png sample54.png \
		sample61.png sample62.png \
		sample91.png sample92.png sample93.png

all: $(PNGS)

.pl.png:
	$(PERL) $(OPTIONS) $<

clean:
	rm -f $(PNGS)

# Dependencies

sample14.png: logo.png
sample42.png: sample42.dat
sample54.png: sample54.dat
