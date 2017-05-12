package Catalyst::Helper::Doc;
use strict;
use warnings;
use File::Spec;
use Pod::ProjectDocs;

our $VERSION = '0.04';

sub mk_stuff {
  my ( $class, $helper, $desc, $lang, $charset ) = @_;
  my $doc_dir = File::Spec->catfile( $helper->{base}, 'doc' );
  my $lib_dir = File::Spec->catfile( $helper->{base}, 'lib' );
  $helper->mk_dir($doc_dir);
  Pod::ProjectDocs->new(
    title   => $helper->{app},
    outroot => $doc_dir,
    libroot => $lib_dir,
    desc    => $desc    || 'Catalyst based application',
    charset => $charset || 'UTF-8',
    lang    => $lang    || 'en',
  )->gen;
}

1;
__END__

=head1 NAME

Catalyst::Helper::Doc - documentation page generator.

=head1 SYNOPSIS

  # execute helper script.
  script/myapp_create.pl Doc

  # you can set description
  # default is "Catalyst based application"

  script/myapp_create.pl Doc "This is description!"

  # you can set language type used as xml:lang. defualt is "en"
  script/myapp_create.pl Doc "This is description!" ja

  # you also can set charset, default is UTF-8
  script/myapp_create.pl Doc "This is description!" ja EUC-JP

=head1 DESCRIPTION

This module allows you to parse your libraries POD, and generate documentation like pages in search.cpan.org,

Execute according to SYNOPSIS, and 'doc' directory will be created, and documentation will be put into it.

=head1 SEE ALSO

L<Pod::ProjectDocs>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Lyo Kato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
