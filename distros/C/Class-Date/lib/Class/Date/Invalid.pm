package Class::Date::Invalid;
our $AUTHORITY = 'cpan:YANICK';
$Class::Date::Invalid::VERSION = '1.1.17';
use strict;
use warnings;

use Class::Date::Const;

use overload 
  '0+'     => "zero",
  '""'     => "empty",
  '<=>'    => "compare",
  'cmp'    => "compare",
  '+'      => "zero",
  '!'      => "true",
  fallback => 1;
                
sub empty { "" }
sub zero { 0 }
sub true { 1 }

sub compare { return ($_[1] ? 1 : 0) * ($_[2] ? -1 : 1) }

sub error { shift->[ci_error]; }

sub errmsg { my ($s) = @_;
    no warnings; # sometimes we need the errmsg, sometimes we don't
    # should be 'no warnings 'redundant'', but older perls don't
    # understand that warning
    sprintf $ERROR_MESSAGES[ $s->[ci_error] ]."\n", $s->[ci_errmsg] 
}
*errstr = *errmsg;

sub AUTOLOAD { undef }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Date::Invalid

=head1 VERSION

version 1.1.17

=head1 AUTHORS

=over 4

=item *

dLux (Szabó, Balázs) <dlux@dlux.hu>

=item *

Gabor Szabo <szabgab@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2014, 2010, 2003 by Balázs Szabó.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
