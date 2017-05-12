package Data::RuledValidator::Filter;

use strict;
use warnings qw/all/;
use Data::RuledValidator::Util;

our $VERSION = 0.02;

sub trim{
  my($self, $v) = @_;
  if(defined $$v){
    $$v =~ s/^\s*//o;
    $$v =~ s/\s*$//o;
  }
}

sub no_dash{
  my($self, $v) = @_;
  $$v =~ s/\-//go;
}

sub lc{
  my($self, $v) = @_;
  $$v = lc($$v);
}

sub uc{
  my($self, $v) = @_;
  $$v = uc($$v);
}

sub no_filter{
  my($self, $v) = @_;
  return $$v;
}

1;

=head1 Name

Data::RuledValidator::Filter - filters

=head2 lc

It makes values lower character.

    'Character'
 -> 'character'

=head2 uc

It makes values upper character.

    'Character'
 -> 'CHARACTER'

=head2 trim

It remove white space in front and back.

    '  hoge  '
 -> 'hoge'

=head2 no_dash

It remove dash included in values.

    '000-000-000'
 -> '000000000'

=head2 no_filter

It does nothing.
return given value as is.

    '000-000-000'
 -> '000-000-000'

=head1 How to create Filter?

 package Data::RuledValidator::Filter::XXX;
 
 sub filter_xxx{
   my($self, $v, $drv, $values) = @_;
   # do something
   return $$v;
 }
 
 1;

$drv is Data::RuledValidator object.
So, you can write like as following filter.

 package Data::RuledValidator::Filter;
 
 sub birth_year_check{
   my($self, $v, $drv, $values) = @_;
   my($q, $method) = ($drv->obj, $drv->method);
   my($year) = $q->$method('birth_year');
   my $r = $q->$method(birth_year_is_1777 => $year == 1777);
   return $$v = $r;
 }

And write the following rule.

 birth_year_is_1777 eq 1 with birth_year_check

=head1 Author

Ktat, E<lt>ktat@cpan.orgE<gt>

=head1 Copyright

Copyright 2006-2007 by Ktat

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
