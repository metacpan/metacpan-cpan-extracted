package Acme::Acotie;

use strict;
use warnings;
our $VERSION = '0.02';

use Class::Inspector;
use List::Util 'shuffle';

sub import {
    my $class = shift;
    my $pkg = caller;

    my @functions     = @{ Class::Inspector->functions($pkg) };
    my @function_refs = @{ Class::Inspector->function_refs($pkg) };
    my $num = scalar(@functions) - 1;
    my @idx = shuffle 0..$num;

    my $i = 0;
    for my $func (@functions) {
        no strict 'refs';
        no warnings;
        *{"$pkg\::$func"} = $function_refs[$idx[$i++]];
    }

}

1;
__END__

=for stopwords Namespace namespace Kogai

=encoding utf8

=head1 NAME

Acme::Acotie - Crash of Namespace

=head1 SYNOPSIS

  use Acme::Acotie;

=head1 DESCRIPTION

Acme::Acotie is namespace crasher.

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 THANKS TO

id:acotie
Dan Kogai (s/spase/space/g)

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Acme-Acotie/trunk Acme-Acotie

Acme::Acotie is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
