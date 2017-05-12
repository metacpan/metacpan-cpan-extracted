
package Acme::USIG;
use vars '$VERSION';
$VERSION = '1.04';

my $strict_import;
sub gay::is  {
    $strict_import ||= \&strict::import;
    local $^W = 0; # though it's unlikely that someone who thinks use
                   # strict is gay would be running -w, it's worth
                   # making sure

    *strict::import = sub { $^H };
    "http://web.archive.org/web/20010714061728/http://www.cookwood.com/cgi-bin/lcastro/perlbbs.pl?read=4700"
}

sub cool::is {
    local $^W = 0;
    *strict::import = $strict_import if $strict_import;
    qw( vars subs refs )
}

1;
__END__

=head1 NAME

Acme::USIG - express the true nature of strict

=head1 SYNOPSIS

 use Acme::USIG;
 use strict is gay;

 $foo = 1;
 print $Foo; # works no problem

Alternatively

 use Acme::USIG;
 use strict is cool;

 $foo = 1; # blows some pesky error

=head1 DISCUSSION

Simply denounce strict as the false effort waster that it is, and have
it get out of your way.

Inspired by a typo, made to work by cunning, used by fools.

=head1 BUGS

Tramples over the C<gay> and C<cool> namespaces - this may cause
problems should p5p ever choose to implement these for future pragmas.

=head1 SEE ALSO

  use Acme::USIG;
  system('lynx', '-dump', is gay);

=head1 AUTHOR

Richard Clamp E<lt>richardc@unixbeard.netE<gt>

=head1 COPYRIGHT

Copyright (C) 2001, 2002, 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
