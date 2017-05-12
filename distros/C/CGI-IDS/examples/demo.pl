#!/usr/bin/perl

# Copyright (C) 2008-2014 Hinnerk Altenburg
#
# This file is part of PerlIDS.
#
# PerlIDS is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PerlIDS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with PerlIDS.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

PerlIDS (CGI::IDS) - example application

=head1 DESCRIPTION

This example application provides a textarea that will be parsed by the IDS and the scan
result will be shown if any attack has been detected.

Two log files are created by the application:

=over 4

=item 1 I<filtered_keys.log>

Logging all filtered key/value pairs to finetune the whitelist.

=item 2 I<attacks.log>

Logging all attacks with detailed information.

=back

A sample whitelist file is provided in I<param_whitelist.xml>. Please have a look into L<CGI::IDS> for details.

=head1 AUTHOR

Hinnerk Altenburg, C<< <hinnerk at cpan.org> >>

=head1 SEE ALSO

L<https://phpids.org/>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008-2011 Hinnerk Altenburg

This file is part of PerlIDS.

PerlIDS is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

PerlIDS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with PerlIDS.  If not, see <http://www.gnu.org/licenses/>.

=cut

#------------------------- Pragmata --------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use CGI;
use CGI::IDS;
use CGI::Pretty;
use Data::Dumper;
# use CGI::Carp qw(fatalsToBrowser);

#------------------------- Globals ---------------------------------------------
my $ids;
my $impact = 0;

#------------------------- Main ------------------------------------------------

my $query = new CGI;

# Start HTML output
print   $query->header,
        $query->start_html(
            -title=>'PerlIDS (CGI::IDS) demo application / smoke test',
            -style=>{'src'=>'style.css'},
        ),
        $query->h1('PerlIDS (CGI::IDS) demo application / smoke test');

eval {
    # Check request for possible attacks (for check_request() see sub below)
    $impact = check_request(
                request         => scalar $query->Vars,
                # filter_file       => './ids/default_filter.xml',
                whitelist_file  => './ids/param_whitelist.xml',
                filter_log      => './ids/filtered_keys.log',
                attack_log      => './ids/attacks.log'
    );

    # Generate input form
    print $query->h2('Put your vectors here:');
    print $query->start_form(
                            -method=>'post',
                            -action=>'demo.pl');
    print $query->textarea( -name => 'vector',
                            -rows => 10,
                            -columns => 50,
                            -default => $query->param('vector') );
    print $query->submit(   -name => 'submit',
                            -value => 'Test your vector');
                            print $query->endform;

    # Generate HTML scan result output showing details of the detected attack
    if ($impact > 0) {
        print $query->h2('Scan result:');

        if ($query->param()) {
            my $attacks = $ids->get_attacks();
            foreach my $attack (@$attacks) {
                print $query->start_table({-class => 'negative'});
                print '<tr><td class="title">' .
                    join ( "</td></tr>\n<tr><td class=\"title\">",
                    (
                        'IMPACT: </td><td>'.            $attack->{impact},
                        'TIME: </td><td>'.              $attack->{time_ms} . 'ms',
                        'FILTERS MATCHED: </td><td>'.   join("<br />", map {"#$_: " . $ids->get_rule_description(rule_id => $_)} @{$attack->{matched_filters}}),
                        'TAGS MATCHED: </td><td>'.      join(",", @{$attack->{matched_tags}}),
                        # 'KEY: </td><td>'.             $query->escapeHTML($query->escapeHTML($attack->{key})),
                        # 'KEY CONV: </td><td>'.        $query->escapeHTML($query->escapeHTML($attack->{key_converted})),
                        'VALUE: </td><td>'.             $query->pre($query->escapeHTML($attack->{value})),
                        'VALUE CONVERTED: </td><td>'.   $query->pre($query->escapeHTML($attack->{value_converted})),
                    ) ) .
                    "</td></tr>\n";
                print '<tr><td>REQUEST: </td><td>'.$query->pre($query->escapeHTML(Dumper({$query->Vars}))).'</td></tr>';
                print $query->end_table();
            }
        }
    }
    elsif ($query->param()){
        print $query->p({-class => 'positive'}, 'No attack found!');
        print $query->p('PerlIDS did not detect your vector? Please help us to improve the filter set an send your vector to ', $query->em('hinnerk at cpan.org'), '!');
    }
};
if ($@) {
    print $query->h2({-class => 'negative'}, 'An Error occurred:');
    print $query->p({-class => 'negative'}, $@);
}

# end the HTML
print $query->end_html;

#------------------------- Subs ------------------------------------------------

#****f* IDS/check_request
# NAME
#   check_request
# DESCRIPTION
#   This sub runs IDS->detect_attacks() on the request.
#   If an impact is detected, a record is appended to the log file.
# INPUT
#   HASH
#   + request
#     filter_file
#     whitelist_file
#     attack_log
#     filter_log
# OUTPUT
#   INT impact or UNDEF if no request or filter_file present
# EXAMPLE
#   check_request(
#     request        => $query->Vars,
#     filter_file    => '../res/default_filter.xml',
#     whitelist_file => '../res/test_param_whitelist.xml',
#     attack_log     => '../res/attacks.log',
#     filter_log     => '../res/filtered_keys.log',
#   );
#****

sub check_request {
    my %args = @_;
    return undef unless ($args{request});
    my $request = $args{request};

    # create global ids object on first call
    if (!defined($ids)) {
        $ids = new CGI::IDS(
            filters_file    => $args{filter_file},
            whitelist_file  => $args{whitelist_file},
            scan_keys       => 0,
            disable_filters => [58,59,60],
        );
    }

    # check request
    my $impact = $ids->detect_attacks( request => $request );

    # log filtered keys for whitelist tuning
    # (add rules for keys to the whilelist if the filters are applied to the keys' standard values)
    if ($args{filter_log} && @{$ids->{filtered_keys}}) {

            # open logfile for appending
            umask(02);
            if (open(LOG, '>>' . $args{filter_log})) {

                flock(LOG, 2);
                    print LOG "--------------------------------\n";
                    print LOG "Filtered:\n";

                    # log all filtered keys
                    foreach my $key (@{$ids->{filtered_keys}}) {
                        print LOG "\t" . $key->{reason} . "\t" . $key->{key} . " -> " . $key->{value} . "\n";
                    }

                    # log all non-filtered keys as environment
                    if ($ids->{non_filtered_keys}) {
                        print LOG "Environment:\n";
                        foreach my $key (@{$ids->{non_filtered_keys}}) {
                            print LOG "\t" . $key->{reason} . "\t" . $key->{key} . " -> " . $key->{value} . "\n";
                        }
                    }

                close(LOG);
            }
            else {
                warn "Can't open ".$args{filter_log}.": $!";
            }
    }

    # log attack details if an impact was detected
    if ($impact && $args{attack_log}) {

        # open logfile for appending
        umask(02);
        if (open(LOG, ">>".$args{attack_log})) {
            my $attacks = $ids->get_attacks();

            flock(LOG, 2);
                print LOG "--------------------------------\n";
                print LOG scalar localtime() . "\n";
                print LOG "Attack details:\n\t";

                foreach my $attack (@$attacks) {
                    print LOG join ( "\n\t",
                        (   'TIME: '.               $attack->{time_ms} . 'ms',
                            'KEY: '.                $attack->{key},
                            'KEY CONV: '.           $attack->{key_converted},
                            'VALUE: '.              $attack->{value},
                            'VALUE CONV: '.         $attack->{value_converted},
                            'IMPACT: '.             $attack->{impact},
                            'FILTERS MATCHED: '.    join(",", @{$attack->{matched_filters}}),
                            'TAGS MATCHED: '.       join(",", @{$attack->{matched_tags}}),
                            'REQUEST: '.            Dumper({$query->Vars}),
                        )
                    );
                }

            close(LOG);
        }
        else {
            warn "Can't open ".$args{attack_log}.": $!";
        }
    }

    return $impact;
}
