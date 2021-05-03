package CXC::Number::Grid::Failure;

# ABSTRACT: CXC::Number::Sequence Exceptions
use strict;
use warnings;

use parent 'Exporter::Tiny';
use custom::failures ();

our $VERSION = '0.05';

our @EXPORT_OK;
BEGIN {
    my @failures = qw/ parameter::constraint
                       parameter::unknown
                       parameter::interface
                       parameter::IllegalCombination
                       internal
 /;
    custom::failures->import( __PACKAGE__, @failures );
    @EXPORT_OK = map { s/::/_/r } @failures;
}

sub _exporter_expand_sub {
    my $class = shift;
    my ( $name, $args, $globals ) = @_;
    my $failure = __PACKAGE__ . '::' . ( $name =~ s/_/::/gr);
    $name => eval "sub () { '$failure' }"; ## no critic (BuiltinFunctions::ProhibitStringyEval)
}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::Number::Grid::Failure - CXC::Number::Sequence Exceptions

=head1 VERSION

version 0.05

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number> or by email
to L<bug-cxc-number@rt.cpan.org|mailto:bug-cxc-number@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Number|CXC::Number>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
