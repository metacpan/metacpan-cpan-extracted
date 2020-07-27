DIRECTORY = $(sort $(dir $(wildcard */)))

all:
	for dir in $(DIRECTORY); do \
		bagit.py --validate $$dir || echo "$$dir should have passed validation"; \
	done