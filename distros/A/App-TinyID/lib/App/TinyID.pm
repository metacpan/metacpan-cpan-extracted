use strict;
use warnings;
package App::TinyID;
#ABSTRACT: Command line tool to encrypt and encrypt integer using Integer::Tiny
our $VERSION = '0.1.1'; # VERSION

=pod

=encoding UTF-8

=head1 NAME

App::TinyID - Command line tool to encrypt and encrypt integer using Integer::Tiny

=head1 VERSION

version 0.1.1

=head1 DESCRIPTION

Encrypts and decrypts numeric using Integer::Tiny.

By default, the encryption key is: WEl0v3you

=head1 SYNOPIS

	# Encrypt number (default key)
	tinyid -e -t 82323723		# => EuEuE0ul0

	# Decrypt encrypted value (default key)
	tinyid -d -t EuEuE0ul0		# => 82323723
	
	# Encrypt with non-default key
	tinyid -k uywn -e -t 90012		# => yyynnwynu

	# Decrypt with non-default key
	tinyid -k uywn -d -t yyynnwynu		# => 90012

=head1 OPTIONS

=head2 
[-t|--text]

Despite the name, you can only use numerals/numerical when -e or --encrypt option is defined. When decrypting, you can also include numbers.

=head2 
[-e|--encrypt]

This encrypts numerical value. Note that, [-t|--text] <TEXT/NUMERIC> must be defined too.

=head2 
[-d|--encrypt]

This decrypts string and numerical value. Note that, [-t|--text] <TEXT/NUMERIC/ must be defined too.

=head2 
[-k|--key]

Overrides default key value: WEl0v3you".

Note, that you cannot have more than one same character in the key.

	# Wrong
	tinyid -k aw99 -e -t 0823

	# Right
	tinyid -k tango29 -e -t 0823

=head1 SEE MORE

L<Integer::Tiny>

=head1 AUTHOR

faraco <skelic3@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by faraco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1;
