package Data::Dumper::AutoEncode::AsDumper;

our $VERSION = '1.0002';

use strict; use warnings; use utf8;
use Import::Into;
use Data::Dumper::AutoEncode ();

$Data::Dumper::Indent        = 1;
$Data::Dumper::Quotekeys     = 0;
$Data::Dumper::Sortkeys      = 1;
$Data::Dumper::Terse         = 1;
$Data::Dumper::Trailingcomma = 1;

use parent 'Exporter';
our @EXPORT = 'Dumper';

sub Dumper { goto &Data::Dumper::AutoEncode::eDumper }

__PACKAGE__->import::into('main')
    unless $Data::Dumper::AutoEncode::AsDumper::NoImportInto;

1; # return true

__END__

=pod

=head1 VERSION

version 1.0002

=encoding utf8

=head1 NAME

Data::Dumper::AutoEncode::AsDumper - Concise, encoded data dumping with Dumper(), everywhere

=head1 SYNOPSIS

  use utf8;
  use Data::Dumper::AutoEncode::AsDumper;

  $data = {
      русский  => 'доверяй, но проверяй',
      i中文    => '也許你的生活很有趣',
      Ελληνικά => 'ἓν οἶδα ὅτι οὐδὲν οἶδα',
  };

  say 'proverbs', Dumper $data; # output encode to utf8

=head1 DESCRIPTION

  L<Data::Dumper> decodes data before dumping it, making it unreadable
  for humans. This module exports the C<Dumper> function, but the
  dumped output is encoded.

=head1 EXPORTED FUNCTION

=over

=item B<Dumper(LIST)>

This module exports one function, C<Dumper>. It works just like the
original, except that output is encoded, by default to C<utf8>.

If you want to change the encoding, set the global:

  $Data::Dumper::AutoEncode::ENCODING = 'CP932';

=back

=head1 WHY USE THIS MODULE?

This package implements a thin wrapper around the excellent module
L<Data::Dumper::AutoEncode>. Reasons to use this instead include:

=over

=item B<Convenience>

If you use this module you can just call C<Dumper> as you normally
would if you used L<Data::Dumper>, rather than having to call
L<Data::Dumper::AutoEncode::eDumper|Data::Dumper::AutoEncode/METHOD>.
Any existing code will continue to work, with better output.

I<(Note: You can now obtain the same behaviour by using an import
option with L<Data::Dumper::AutoEncode>, but that was not implemented
when this module was first released.)>

=item B<Concision>

The following C<Data::Dumper> options are set:

  $Data::Dumper::Indent        = 1;
  $Data::Dumper::Quotekeys     = 0;
  $Data::Dumper::Sortkeys      = 1;
  $Data::Dumper::Terse         = 1;
  $Data::Dumper::Trailingcomma = 1;

=item B<Exports to main package by default>

This module uses the excellent L<Import::Into> so that the C<Dumper>
function will be imported into the caller's C<main> package, no matter
where the module is loaded.

To turn off this behaviour, set the global in a C<BEGIN> block before
loading the module:

  $Data::Dumper::AutoEncode::AsDumper::NoImportInto = 1;

=back

=head1 ACKNOWLEDGEMENTS

Dai Okabayashi (L<BAYASHI|https://metacpan.org/author/BAYASHI>)

Graham Knop (L<HAARG|https://metacpan.org/author/HAARG>)

Gurusamy Sarathy (L<GSAR|https://metacpan.org/author/GSAR>) ( and Sawyer X (L<XSAWYERX|https://metacpan.org/author/XSAWYERX>) )

Slaven Rezić (L<SREZIC|https://metacpan.org/author/SREZIC>)

L<CPAN Testers|http://cpantesters.org/>

L<All the dzil contributors|http://dzil.org/>

L<Athanasius|https://perlmonks.org/?node=Athanasius>

I stand on the shoulders of giants ...

=head1 SEE ALSO

L<Data::Dumper::AutoEncode>, L<Data::Dumper>

=head1 AUTHOR

Nick Tonkin <tonkin@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Nick Tonkin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
