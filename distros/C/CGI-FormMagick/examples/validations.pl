#!/usr/bin/perl -wT

# Copyright (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

use strict;
use lib "../lib/";
use CGI::FormMagick;

my $fm = new CGI::FormMagick(
    TYPE => 'STRING',
    SOURCE => get_validations_xml(),
);

$fm->debug(1);

$fm->display();

# TODO: Figure out why this ends with "Errors"

sub done {
    print qq(
        <p>That's it!</p>
    );
}

sub get_validations_xml {
    my $xml = qq(<FORM TITLE="Validations" HEADER="head.tmpl" FOOTER="foot.tmpl"
        POST-EVENT="done">\n);

    # This list is manually maintained.
    # I started out extracting the names and values from the *.pm's, but
    # it doesn't look like it's going to pay off.  (Correct me if I'm
    # wrong.)
    my %pages = (
        Basic => {
            integer => '42',
            nonblank => 'Charlie',
            number => '-42',
            word => 'chocolate',
            date => '12/31/2001',
        },

       Business => {
           credit_card_expiry => '11/02',
           credit_card_number => '4111 1111 1111 1111',
       },

        Geography => {
            US_state => 'or',
            US_zipcode => '79412',
            iso_country_code => 'gb',
        },

        Length => {
             'exactlength(5)' => 'Willy',
             'lengthrange(2,10)' => 'Wonka',
             'maxlength(6)' => 'Oompa',
             'minlength(5)' => 'Loompa',
        },

        Network => {
            domain_name => 'wonka.com',
            email => 'willy@wonka.com',
            ip_number => '12.34.56.78',
            password => 'Oom4l00mp4!!',
            url => 'http://www.wonka.com',
            username => 'wwonka',
        },
    );

    foreach my $page_name (sort keys %pages) {
        my $validations = $pages{$page_name};

        $xml .= qq(    <PAGE NAME="$page_name">
            <TITLE>$page_name</TITLE>\n);
        
        foreach my $sub (sort keys %{$validations}) {
            my $default = $validations->{$sub};
            my $field_name = $sub . '_field';
            $field_name =~ s/\W/_/g;
            $xml .=
                qq(
                <FIELD ID="$field_name" TYPE="TEXT"
                    VALIDATION="$sub" VALUE="$default">
                    <LABEL>$sub</LABEL>
                </FIELD>\n);
        }

        $xml .= qq(    </PAGE>\n);
    }

    $xml .= q(</FORM>);

    return $xml;
}
