package Catalyst::Plugin::Text::Xatena;

use 5.008000;
use strict;
use warnings;

use base 'Class::Data::Inheritable';
use Text::Markdown;

our $VERSION = '0.02';
$VERSION = eval $VERSION;


use Text::Xatena;

__PACKAGE__->mk_classdata('text_xatena');
__PACKAGE__->text_xatena( Text::Xatena->new );

1;
__END__

=head1 NAME

Catalyst::Plugin::Text::Xatena - Catalyst extension for Text::Xatena (Hatena Format)

=head1 SYNOPSIS


  my ( $shift, $c ) = @_;
  
  $c->text_hatena->foramt(<<'__EOF__');
  * You can write Hatena Formated Text

  - ul
  + ol
  
  |*foo|*bar|*baz|
  |test|test|test|
  |test|test|test|
  __EOF__
  }

see L<http://hatenadiary.g.hatena.ne.jp/keyword/%E3%81%AF%E3%81%A6%E3%81%AA%E8%A8%98%E6%B3%95%E4%B8%80%E8%A6%A7|hatena syntax document by Hatena Inc.>.

=head1 DESCRIPTION

Persistent Text::Xatena object (Hatena syntax formatter) for Catalyst.

Before using this plugin, please consider your MVC strategy.
In some case, you shoud impliment such formatter in a model not in a controller. 

=head2 EXPORT

None by default.



=head1 SEE ALSO

Please see L<Text::Xatena>, L<http://perl-users.jp/articles/advent-calendar/2010/meta_adcal/5|about Text::Xatena>.

Very thanks for L<http://www.hatena.ne.jp/cho45/|id:cho45> who is writer of L<Text::Xatena>.

=head1 AUTHOR

Kazuki MATSUDA, E<lt>matsuda.kazuki@facebook.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kazuki MATSUDA

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
