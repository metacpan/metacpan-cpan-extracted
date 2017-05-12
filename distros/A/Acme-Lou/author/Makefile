.PHONY: help csv share

INDEXER:=/usr/local/libexec/mecab/mecab-dict-index
DICDIR:=/usr/local/lib/mecab/dic/ipadic

help:
	make -C author share

csv:
	cat mecab-ipadic-2.7.0-20060707/*.csv | perl loucsv.pl > lou.csv

share:
	$(INDEXER) -d $(DICDIR) -t euc-jp -u ../share/euc-jp.dic -f utf8 lou.csv
	$(INDEXER) -d $(DICDIR) -t utf8   -u ../share/utf8.dic   -f utf8 lou.csv
