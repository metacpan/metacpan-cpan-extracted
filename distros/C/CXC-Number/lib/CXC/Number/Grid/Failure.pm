package CXC::Number::Grid::Failure;

# ABSTRACT: CXC::Number::Sequence Exceptions
use v5.28;
use strict;
use warnings;
use experimental 'signatures';

use parent 'Exporter::Tiny';
use custom::failures ();

our $VERSION = '0.13';

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

sub _exporter_expand_sub ( $, $name, $, $, $ ) {
    my $failure = __PACKAGE__ . q{::} . ( $name =~ s/_/::/gr );
    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    $name => eval "sub () { '$failure' }";
}

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::Number::Grid::Failure - CXC::Number::Sequence Exceptions

=head1 VERSION

version 0.13

=head1 INTERNALS

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-number@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-number

and may be cloned from

  https://gitlab.com/djerius/cxc-number.git

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
