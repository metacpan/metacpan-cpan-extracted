#####################################################################################
#
# Copyright (c) 2012, Alexander Todorov <atodorov()otb.bg>. See POD section.
#
#####################################################################################

package App::Difio::dotCloud::Parser;

use Pod::Simple;
@ISA = qw(Pod::Simple);
use strict;

my $parser_state = "";

sub _handle_element_start {
    my($self, $element_name, $attr_hash_r) = @_;
    $parser_state = $element_name;
}

sub _handle_element_end {
    my($self, $element_name, $attr_hash_r) = @_;

    # NOTE: $attr_hash_r is only present when $element_name is "over" or "begin"
    # The remaining code excerpts will mostly ignore this $attr_hash_r, as it is
    # mostly useless. It is documented where "over-*" and "begin" events are
    # documented.

    $parser_state = "";
}

sub _handle_text {
    my($self, $text) = @_;
    my $FH = $_[0]{'output_fh'};

    if ($parser_state eq "L") {
        print $FH $text;
    } elsif ($parser_state eq "C") {
        if ($text =~ m/^VERSION: (.*)/) {
            print $FH " $1\n";
        }
    }
}
1;
