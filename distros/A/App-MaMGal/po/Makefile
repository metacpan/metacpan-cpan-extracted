LINGUAS = pl
MOS     = pl.mo

.PHONY: all
all: $(MOS)

.PHONY: install
install: $(MOS)
	for locale in $(LINGUAS) ; do \
	 install -m 0644 -o root -g root $$locale.mo $(DEST)/usr/share/locale/$$locale/LC_MESSAGES/mamgal.mo ; \
	done

.PHONY: refresh-pot
refresh-pot:
	rm -f mamgal.pot.new mamgal.pot.old
	cd .. && (echo mamgal; grep 'pm$$' MANIFEST) | xgettext \
	  --add-comments=TRANSLATORS: \
	  --from-code=UTF-8 \
	  --msgid-bugs-address="Marcin Owsiany <marcin@owsiany.pl>" \
	  --package-name=mamgal --package-version=0.1 \
	  --copyright-holder="Marcin Owsiany <marcin@owsiany.pl>" \
	  -L Perl -d mamgal -o po/mamgal.pot.new -f -
	mv mamgal.pot mamgal.pot.old
	msgmerge mamgal.pot.old mamgal.pot.new > mamgal.pot

.PHONY: refresh-pos
refresh-pos:
	set -e ; \
	for locale in $(LINGUAS) ; do \
	 mv $$locale.po $$locale.po.old ; \
	 msgmerge $$locale.po.old mamgal.pot > $$locale.po ; \
	done

%.mo: %.po
	msgfmt -o $@ $<

