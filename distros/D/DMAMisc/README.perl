You can install this module with the usual CPAN commands:

	perl Makefile.PL
	make
	make test
	make install

I apologize for placing these Classes in a 'private' namespace under
my initials (DMA). The problem with open sourcing them is they have
been in use by me for any where from five to ten years in this form
and thus appear in virtually everything I have written for self or
hire. I have considered several possible renamings, none of which
is wholly satisfactory and off of which require both a 'fork', leaving
me to support two version of the same package in different name
spaces, and additionally will require more time to change even in
local code than I have available.

So, it has come down to either releasing these as-is or indefinitely
blocking the open source release of most of my code. I have to chosen
to release and be damned.

If any of these internal functions of mine are useful to you,
please let me know, as that might make it worth while integrating
those into Perl namespace in a more approved fashion.

Dale M. Amon (DMA)

