use strict;
use warnings;
package Acme::Lingua::EN::Inflect::Modern 0.008;

use parent qw(Exporter);
# ABSTRACT: modernize Lingua::EN::Inflect rule's

use Lingua::EN::Inflect 1.86 ();
use Sub::Override 0.07;

BEGIN { our %EXPORT_TAGS = %Lingua::EN::Inflect::EXPORT_TAGS };

Exporter::export_ok_tags(qw( ALL ));

#pod =head1 SYNOPSIS
#pod
#pod Lingua::EN::Inflect is great for converting singular word's to plural's, but
#pod does not always match modern usage.  This module corrects the most common
#pod case's.
#pod
#pod See L<Lingua::EN::Inflect> for information on using this module, which has an
#pod identical interface.
#pod
#pod =cut

my %todo = map { map { $_ => 1 } @$_ }
           values %Lingua::EN::Inflect::EXPORT_TAGS;

for my $routine (keys %todo) {
  no strict 'refs';
  *{__PACKAGE__ . '::' . $routine} = sub {
     my $override = Sub::Override->new(
       'Lingua::EN::Inflect::_PL_noun' => \&_PL_noun
     );

    Lingua::EN::Inflect->can($routine)->(@_);
  };
}

my $original_PL_noun;
BEGIN { $original_PL_noun = \&Lingua::EN::Inflect::_PL_noun; }

sub _PL_noun {
  my ($word, $number) = @_;

  my $plural = $original_PL_noun->($word, $number);

  return $plural if $plural eq 'his';
  return $plural if $plural eq 'us';

  if ($word =~ /es$/) {
    $plural =~ s/e(s$|s\|)/'$1/;
  } elsif ($word =~ /y$/) {
    $plural =~ s/(?:ie|y)?(s$|s\|)/y'$1/;
  } else {
    $plural =~ s/(s$|s\|)/'$1/;
  }

  return $plural;
}

#pod =head1 BUG'S
#pod
#pod Please report any bug's or feature request's via the GitHub issue tracker at
#pod L<https://github.com/rjbs/Acme-Lingua-EN-Inflect-Modern/issues>.  I will be
#pod notified, and then you'll automatically be notified of progress on
#pod your bug as I make change's.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Lingua::EN::Inflect::Modern - modernize Lingua::EN::Inflect rule's

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Lingua::EN::Inflect is great for converting singular word's to plural's, but
does not always match modern usage.  This module corrects the most common
case's.

See L<Lingua::EN::Inflect> for information on using this module, which has an
identical interface.

=head1 PERL VERSION

This module is shipped with no promise about what version of perl it will
require in the future.  In practice, this tends to mean "you need a perl from
the last three years," but you can't rely on that.  If a new version of perl
ship, this software B<may> begin to require it for any reason, and there is no
promise that patches will be accepted to lower the minimum required perl.

=head1 BUG'S

Please report any bug's or feature request's via the GitHub issue tracker at
L<https://github.com/rjbs/Acme-Lingua-EN-Inflect-Modern/issues>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make change's.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
