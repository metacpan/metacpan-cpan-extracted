package Acme::NabeAtzz;

use strict;
use warnings;
our $VERSION = '0.01';

use XSLoader;
XSLoader::load 'Acme::NabeAtzz', $VERSION;

sub import {
    _setup();
}


1;
__END__

=encoding utf8

=head1 NAME

Acme::NabeAtzz - One, Two, さーん

=head1 SYNOPSIS

  use Acme::NabeAtzz;

  write your perl code


=head1 DESCRIPTION

Acme::NabeAtzz is so crazy Japanese comedian

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

C<opnames.h>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Acme-NabeAtzz/trunk Acme-NabeAtzz

Acme::NabeAtzz is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
