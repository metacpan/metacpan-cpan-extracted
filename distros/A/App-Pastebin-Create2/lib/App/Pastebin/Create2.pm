use strict;
use warnings;
package App::Pastebin::Create2;
#ABSTRACT: Simple CLI App to create and upload to Pastebin.com
# FILE HOLDER/THIS IS COMMAND LINE APP, executable name is pastebin-create2
# The executable located in bin/
# type pastebin-create2 -h for usage
our $VERSION = '0.15'; # VERSION

=pod

=encoding UTF-8

=head1 NAME

App::Pastebin::Create2 - Simple CLI App to create and upload to Pastebin.com

=head1 VERSION

version 0.15

=head1 SYNOPSIS

	pastebin-create --text 'TEXT' --format 'none' --expiry 10m --private 0 --desc 'A TITLE'

=head1 Note

This is a continuation of abandoned App::Pastebin::Create. So, please use this distribution instead of the halted module.

=head1 Flags

=head2 --text, -t

REQUIRED

This flag required to run the program (at minimum).

Text to paste flag. 

=head2 --format, -f

OPTIONAL

Syntax highlighting choice, see here for list - L<WWW::Pastebin::PastebinCom::Create>

=head2 --expiry, -e

OPTIONAL

DEFAULT TO: 30 days/1 month

Your paste time to expired.

Example: Never, 10m (10 minutes) 

=head2 --private, -p

OPTIONAL

Defaults to 1: make your pastes unlisted

Change to any number other than 1 to make your paste, publicly available.

=head2 --desc, -d

OPTIONAL

Your paste title description.

=head1 Testing & Manual Installation

	perl Makefile.PL && make test
	
	# install
	make install

	# cpanm
	cpanm App-Pastebin-Create2-[VERSION].tar.gz

=head1 SEE ALSO

L<https://metacpan.org/pod/WWW::Pastebin::PastebinCom::Create>

L<https://metacpan.org/pod/App::Nopaste>

=head1 AUTHOR

faraco <skelic3@gmail.com>, mfzz <mfzz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by faraco <skelic3@gmail.com>, mfzz <mfzz@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1;
