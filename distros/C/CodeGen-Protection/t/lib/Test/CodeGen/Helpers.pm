package Test::CodeGen::Helpers;

use strict;
use warnings;
use Carp 'croak';
use base 'Exporter';
use Test::Most;
our @EXPORT = qw(
  is_multiline_text
  update_version
);

sub is_multiline_text ($$$) {
    my ( $text, $expected, $message ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @text     = split /\n/ => $text;
    my @expected = split /\n/ => $expected;
    eq_or_diff \@text, \@expected, $message;
}

sub update_version ($) {
    my $text = shift;
    if ( $text =~ /\b(?<module>CodeGen::Protection::Format::\w+).*Checksum:/ ) {
        my $module     = $+{module};
        my $version_re = $module->_version_re;
        my $version    = $module->VERSION;
        $text =~ s/\b$module(\s+)$version_re\b/$module$1$version/g;
        return $text;
    }
    else {
        croak("Cannot find version in text:\n\n$text");
    }
}

1;
