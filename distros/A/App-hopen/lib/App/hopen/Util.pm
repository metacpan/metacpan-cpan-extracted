package App::hopen::Util;
our $VERSION = '0.000015'; # TRIAL

# Docs {{{1

=head1 NAME

App::hopen::Util - general utilities for App::hopen

=cut

use strict; use warnings;
use parent 'Exporter';
use vars::i {
    '@EXPORT' => [qw(isMYH)],
    '@EXPORT_OK' => [qw(MYH)]
};
use vars::i '%EXPORT_TAGS' => {
    default => [@EXPORT],
    all => [@EXPORT, @EXPORT_OK],
};

=head1 CONSTANTS

=head2 MYH

The name C<MY.hopen.pl>, centralized here.  Not exported by default.

=cut

use constant MYH => 'MY.hopen.pl';

=head1 FUNCTIONS

=head2 isMYH

Returns truthy if the given argument is the name of a C<MY.hopen.pl> file.
See also L</MYH>.

=cut

sub isMYH {
    my $name = @_ ? $_[0] : $_;
    return ($name =~ /\b\Q@{[MYH]}\E$/)
} #isMYH()

1;
