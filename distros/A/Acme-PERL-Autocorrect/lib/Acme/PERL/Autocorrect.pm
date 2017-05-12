package Acme::PERL::Autocorrect;
BEGIN {
  $Acme::PERL::Autocorrect::VERSION = '1.20110629';
}
# ABSTRACT: corrects PERL to Perl in strings automatically

use strict;
use warnings;

use optimizer 'extend-c' => sub
{
    return unless $_[0]->name eq 'const';
    my $op = shift;
    return unless $op->sv;
    my $sv = $op->sv;
    return unless $op->sv->isa( 'B::PV' );
    my $pv = $op->sv->PV;
    $pv =~ s{\bPERL(?!::|/)}{Perl};
    $op->sv( $pv );
};

1;

__END__

=head1 NAME

Acme::PERL::Autocorrect - corrects PERL to Perl

=head1 SYNOPSIS

To use this module, simply:

  use Acme::PERL::Autocorrect;

What could be easier?

=head1 DESCRIPTION

It's not PERL. It's Perl, but why should you have to fix that when Perl can fix
itself?

=head1 AUTHOR

chromatic, C<< <chromatic@wgz.org> >>

=head1 BUGS

You can still craft strings that don't resolve to constant strings during the
parsing and optimization stages which this module cannot correct. See also the
incompleteness theorem.

=head1 ACKNOWLEDGEMENTS

Chip made me do it.

=head1 COPYRIGHT & LICENSE

Copyright (c) chromatic, 2011, and distributed under the same license as Perl
5.

=cut
