package t::Test;

use strict;
use warnings;

use Test::More;
use HTML::Declare qw/LINK SCRIPT STYLE/;
use base qw/Exporter/;
use vars qw/@EXPORT/;
@EXPORT = qw/compare sanitize/;

sub sanitize ($) {
    my $css = shift;
    $css =~ s/;}/}/g;
    return $css;
}

sub compare ($;@) {
    my $expect = shift;              
    my @content;
    while (@_) {
        if (! ref $_[0]) {           
            my $href = shift;
            my ($kind) = $href =~ m/\.([^.]+)$/;
            if ($kind eq "js") {
                push @content, SCRIPT({ type => "text/javascript", src => $href, _ => "" });
            }
            elsif ($kind =~ m/^css\b/) {
                my ($type, $media) = split m/-/, $kind;
                push @content, LINK({ rel => "stylesheet", type => "text/css", href => $href });
            }
        } 
        elsif (ref $_[0] eq "ARRAY") {
            my ($kind, $content) = @{ shift() };
            if ($kind eq "js") {     
                push @content, SCRIPT({ type => "text/javascript", _ => "\n$content" });
            }
            elsif ($kind =~ m/^css\b/) {
                my ($type, $media) = split m/-/, $kind;
                push @content, STYLE({ type => "text/css", _ => "\n$content" });
            }
        }
        else {
            die "Don't understand: @_";
        }
    }
    return is($expect, join "\n", @content);
}

1;
