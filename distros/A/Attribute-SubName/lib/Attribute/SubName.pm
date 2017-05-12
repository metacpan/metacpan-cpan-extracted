use 5.006;
use strict;
use warnings;

package Attribute::SubName;
BEGIN {
  $Attribute::SubName::VERSION = '1.101420';
}
# ABSTRACT: Naming anonymous subroutines via attributes

use Sub::Name;
use parent 'Attribute::Handlers';

sub UNIVERSAL::Name : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    $data = [$data] unless ref $data eq 'ARRAY';
    for my $item (@$data) {
        my $name = "${package}::${item}";
        subname $name => $referent;
        no strict 'refs';
        *{$name} = $referent;
    }
}
1;


__END__
=pod

=head1 NAME

Attribute::SubName - Naming anonymous subroutines via attributes

=head1 VERSION

version 1.101420

=head1 SYNOPSIS

    use Attribute::SubName;
    my $coderef = sub :Name(foo) { print "got: $_\n"; };
    print foo("hi");

=head1 DESCRIPTION

This module provides an attribute C<:Name> that you can use on anonymous
subroutines to give them a name. This is useful as they will then show up with
that name in stack traces (cf. L<Carp>). The naming is done with L<Sub::Name>.
Additionally, the attribute also installs the newly named subroutine in the
proper glob slot so you can refer to it by name.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Attribute-SubName>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Attribute-SubName/>.

The development version lives at
L<http://github.com/hanekomu/Attribute-SubName/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

