# $Id: /local/CPAN/AxKit-XSP-L10N/lib/AxKit/XSP/L10N/Demo/fr.pm 1397 2005-03-26T23:02:06.504192Z claco  $
package AxKit::XSP::L10N::Demo::fr;
use strict;
use warnings;
use vars qw(%Lexicon);

BEGIN {
    use base 'AxKit::XSP::L10N::Demo';
};

%Lexicon = (
    Language => 'French',
    'From [_1] To [_2]' => 'French [_1] To [_2]'
);

1;
__END__

=head1 NAME

AxKit::XSP::L10N::Demo::fr - Demo French Lexicon

=head1 SYNOPSIS

    use base 'AxKit::XSP::L10N::Demo';

    my $lh = __PACKAGE->get_handle('fr');
    $lh->maketext('Submit');

=head1 DESCRIPTION

Simple demo French lexicon.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
