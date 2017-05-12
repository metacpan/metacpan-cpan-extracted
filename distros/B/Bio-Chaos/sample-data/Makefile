
%.is-valid: %
	xmllint --dropdtd --valid --noout --dtdvalid ../dtd/chaos.dtd $* > $@.tmp && mv $@.tmp $@
