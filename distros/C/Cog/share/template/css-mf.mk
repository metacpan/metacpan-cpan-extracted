ALL_CSS=[% list %]

all: clean all_file

all_file: all.css
	(FILENAME=`cat $< | perl -MDigest::MD5 -e 'my $$d = Digest::MD5->new; $$d->addfile(*STDIN); print $$d->hexdigest'`;mv $< all-$$FILENAME.css)

all.css:
	cat $(ALL_CSS) > $@

clean:
	rm -f all.css all-*.css
