.PHONY: share

INDEXER:=/usr/local/libexec/mecab/mecab-dict-index
DICDIR:=/usr/local/lib/mecab/dic/ipadic

share:
	$(INDEXER) -d $(DICDIR) -t euc-jp -u ../share/euc-jp.dic -f utf8 ika.csv
	$(INDEXER) -d $(DICDIR) -t utf8   -u ../share/utf8.dic   -f utf8 ika.csv
