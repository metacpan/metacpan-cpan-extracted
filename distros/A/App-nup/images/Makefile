# Generate screenshot images for documentation.
# Requires: iTerm2, capture.sh, nup
#
# Note: On Retina displays, captured images will be at 2x resolution.

.PHONY: all clean

all: nup.png

nup.png:
	./capture.sh -o $@ -- 'nup man nup'

clean:
	rm -f nup.png
