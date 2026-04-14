DICTS=jtca-katakana-guide-3.dict \
      jtf-style-guide-3.dict \
      ms-style-guide.dict

all: $(DICTS)

.SUFFIXES: .pl .dict

.pl.dict:
	perl -I. $< > $@

clean:
	rm -f $(DICTS)
