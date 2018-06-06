.PHONY: test
#: Run full file decompile tests
test:
	mkdir -p tmp/base || true
	mkdir -p tmp/opbasic || true
	perl ./runtests.pl

# Whatever it is you want to do, it should be forwarded to the
# to top-level directories
%:
	$(MAKE) -C ../.. $@
