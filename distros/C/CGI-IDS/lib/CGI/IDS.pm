package CGI::IDS;

#------------------------- Notes -----------------------------------------------
# This source code is documented in both POD and ROBODoc format.
# Please find additional POD documentation at the end of this file
# (search for "__END__").
#-------------------------------------------------------------------------------

#****c* IDS
# NAME
#   PerlIDS (CGI::IDS)
# DESCRIPTION
#   Website Intrusion Detection System based on PHPIDS https://phpids.org rev. 1409
# AUTHOR
#   Hinnerk Altenburg <hinnerk@cpan.org>
# CREATION DATE
#   2008-06-03
# COPYRIGHT
#   Copyright (C) 2008-2014 Hinnerk Altenburg
#
#   This file is part of PerlIDS.
#
#   PerlIDS is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   PerlIDS is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public License
#   along with PerlIDS.  If not, see <http://www.gnu.org/licenses/>.

#****

=head1 NAME

CGI::IDS - PerlIDS - Perl Website Intrusion Detection System (XSS, CSRF, SQLI, LFI etc.)

=head1 VERSION

Version 1.0217 - based on and tested against the filter tests of PHPIDS https://phpids.org rev. 1409

=cut

our $VERSION = '1.0217';

=head1 DESCRIPTION

PerlIDS (CGI::IDS) is a website intrusion detection system based on PHPIDS L<https://phpids.org/> to detect possible attacks in website requests, e.g. Cross-Site Scripting (XSS), Cross-Site Request Forgery (CSRF), SQL Injections (SQLI) etc.

It parses any hashref for possible attacks, so it does not depend on CGI.pm.

The intrusion detection is based on a set of converters that convert the request according to common techniques that are used to hide attacks. These converted strings are checked for attacks by running a filter set of currently 68 regular expressions and a generic attack detector to find obfuscated attacks. For easily keeping the filter set up-to-date, PerlIDS is compatible to the original XML filter set of PHPIDS, which is frequently updated.

Each matching regular expression has it's own impact value that increases the tested string's total attack impact. Using these total impacts, a threshold can be defined by the calling application to log the suspicious requests to database and send out warnings via e-mail or even SMS on high impacts that indicate critical attack activity. These impacts can be summed per IP address, session or user to identify attackers who are testing the website with small impact attacks over a time.

You can improve the speed and the accurancy (reduce false positives) of the IDS by specifying an L<XML whitelist file|CGI::IDS/Whitelist>. This whitelist check can also be processed separately by using L<CGI::IDS::Whitelist|CGI::IDS::Whitelist> if you want to pre-check the parameters on your application servers before you send only the suspicious requests over to worker servers that do the complete CGI::IDS check.

Download and install via CPAN: L<http://search.cpan.org/dist/CGI-IDS/lib/CGI/IDS.pm>

Report issues and contribute to PerlIDS on GitHub: L<https://github.com/hinnerk-a/perlids>

=head1 SYNOPSIS

 use CGI;
 use CGI::IDS;

 $cgi = new CGI;

 # instantiate the IDS object;
 # do not scan keys, values only; don't scan PHP code injection filters (IDs 58,59,60);
 # whitelist the parameters as per given XML whitelist file;
 # All arguments are optional, 'my $ids = new CGI::IDS();' is also working correctly,
 # loading the entire shipped filter set and not scanning the keys.
 # See new() for all possible arguments.
 my $ids = new CGI::IDS(
     whitelist_file  => '/home/hinnerk/ids/param_whitelist.xml',
     disable_filters => [58,59,60],
 );

 # start detection
 my %params = $cgi->Vars;
 my $impact = $ids->detect_attacks( request => \%params );

 if ($impact > 0) {
     my_log( $ids->get_attacks() );
 }
 if ($impact > 30) {
     my_warn_user();
     my_email( $ids->get_attacks() );
 }
 if ($impact > 50) {
     my_deactivate_user();
     my_sms( $ids->get_attacks() );
 }

 # now with scanning the hash keys
 $ids->set_scan_keys(scan_keys => 1);
 $impact = $ids->detect_attacks( request => \%params );

See F<examples/demo.pl> in CGI::IDS module package for a running demo.

You might want to build your own 'session impact counter' that increases during multiple suspicious requests by one single user, session or IP address.

=head1 METHODS

=cut

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use XML::Simple qw(:strict);
use HTML::Entities;
use MIME::Base64;
use Encode qw(decode);
use Carp;
use Time::HiRes;
use FindBin qw($Bin);
use CGI::IDS::Whitelist;

#------------------------- Settings --------------------------------------------
$XML::Simple::PREFERRED_PARSER  = "XML::Parser";

#------------------------- Debugging -------------------------------------------
# debug modes (binary):
use constant DEBUG_KEY_VALUES       => (1 << 0); # print each key value pair
use constant DEBUG_IMPACTS          => (1 << 1); # print impact per key value pair
use constant DEBUG_ARRAY_INFO       => (1 << 2); # print attack info arrays
use constant DEBUG_CONVERTERS       => (1 << 3); # print output of each converter
use constant DEBUG_SORT_KEYS_NUM    => (1 << 4); # sort request by keys numerically
use constant DEBUG_SORT_KEYS_ALPHA  => (1 << 5); # sort request by keys alphabetically
use constant DEBUG_WHITELIST        => (1 << 6); # dumps loaded whitelist hash
use constant DEBUG_MATCHED_FILTERS  => (1 << 7); # print IDs of matched filters

#use constant DEBUG_MODE                =>  DEBUG_KEY_VALUES |
#                                       DEBUG_IMPACTS |
#                                       DEBUG_WHITELIST |
#                                       DEBUG_ARRAY_INFO |
#                                       DEBUG_CONVERTERS |
#                                       DEBUG_MATCHED_FILTERS |
#                                       DEBUG_SORT_KEYS_NUM;

# simply comment this line out to switch debugging mode on (also uncomment above declaration)
use constant DEBUG_MODE             => 0;

#------------------------- Constants -------------------------------------------

# converter functions, processed in this order
my @CONVERTERS = qw/
    stripslashes
    _convert_from_repetition
    _convert_from_commented
    _convert_from_whitespace
    _convert_from_js_charcode
    _convert_js_regex_modifiers
    _convert_entities
    _convert_quotes
    _convert_from_sql_hex
    _convert_from_sql_keywords
    _convert_from_control_chars
    _convert_from_nested_base64
    _convert_from_out_of_range_chars
    _convert_from_xml
    _convert_from_js_unicode
    _convert_from_utf7
    _convert_from_concatenated
    _convert_from_proprietary_encodings
    _run_centrifuge
/;

#------------------------- Subs ------------------------------------------------

#****m* IDS/new
# NAME
#   Constructor
# DESCRIPTION
#   Creates an IDS object.
#   The filter set and whitelist will stay loaded during the lifetime of the object.
#   You may call detect_attacks() multiple times, the attack array ( get_attacks() )
#   will be emptied at the start of each run of detect_attacks().
# INPUT
#   HASH
#     filters_file    STRING  The path to the filters XML file (defaults to shipped IDS.xml)
#     whitelist_file  STRING  The path to the whitelist XML file
#     scan_keys       INT     1 to scan also the keys, 0 if not (default: 0)
#     disable_filters ARRAYREF[INT,INT,...] if given, these filter ids will be disabled
# OUTPUT
#   IDS object, dies (croaks) if no filter rule could be loaded
# EXAMPLE
#   # instantiate object; do not scan keys, values only
#   my $ids = new CGI::IDS(
#       filters_file    => '/home/hinnerk/sandbox/ids/cgi-bin/default_filter.xml',
#       whitelist_file  => '/home/hinnerk/sandbox/ids/cgi-bin/param_whitelist.xml',
#       scan_keys       => 0,
#       disable_filters => [58,59,60],
#   );
#****

=head2 new()

Constructor. Can optionally take a hash of settings. If I<filters_file> is not given,
the shipped filter set will be loaded, I<scan_keys> defaults to 0.

The filter set and whitelist will stay loaded during the lifetime of the object.
You may call C<detect_attacks()> multiple times, the attack array (C<get_attacks()>)
will be emptied at the start of each run of C<detect_attacks()>.

For example, the following is a valid constructor:

 my $ids = new CGI::IDS(
     filters_file    => '/home/hinnerk/ids/default_filter.xml',
     whitelist_file  => '/home/hinnerk/ids/param_whitelist.xml',
     scan_keys       => 0,
     disable_filters => [58,59,60],
 );

The Constructor dies (croaks) if no filter rule could be loaded.

=cut

sub new {
    my ($package, %args) = @_;

    # defaults
    $args{scan_keys}            = $args{scan_keys} ? 1 : 0;
    my $filters_file_default    = __FILE__;
    $filters_file_default       =~ s/IDS.pm/IDS.xml/;

    # self member variables
    my $self = {
        filters_file        => $args{filters_file} || $filters_file_default,
        whitelist           => CGI::IDS::Whitelist->new(whitelist_file => $args{whitelist_file}),
        scan_keys           => $args{scan_keys},
        impact              => 0,
        attacks             => undef, # []
        filters             => [],
        filter_disabled     => { map { $_ => 1} @{$args{disable_filters} || []} },
    };

    if (DEBUG_MODE & DEBUG_WHITELIST) {
        use Data::Dumper; print Dumper($self->{whitelist}->{whitelist});
    }

    # create object
    bless $self, $package;

    # read & parse filter XML
    if (!$self->_load_filters_from_xml($self->{filters_file})) {
        croak "No IDS filter rules loaded!";
    }

    return $self;
}

#****m* IDS/detect_attacks
# NAME
#   detect_attacks
# DESCRIPTION
#   Parses a hashref (e.g. $query->Vars) for detection of possible attacks.
#   The attack array is emptied at the start of each run.
# INPUT
#   +request    hashref to be parsed
# OUTPUT
#   Impact if filter matched, 0 otherwise
# SYNOPSIS
#   $ids->detect_attacks(request => $query->Vars);
#****

=head2 detect_attacks()

 DESCRIPTION
   Parses a hashref (e.g. $query->Vars) for detection of possible attacks.
   The attack array is emptied at the start of each run.
 INPUT
   +request   hashref to be parsed
 OUTPUT
   Impact if filter matched, 0 otherwise
 SYNOPSIS
   $ids->detect_attacks(request => $query->Vars);

=cut

sub detect_attacks {
    my ($self, %args) = @_;

    return 0 unless ($args{request});
    my $request = $args{request};

    # reset last detection data
    $self->{impact}             = 0;
    $self->{attacks}            = [];
    $self->{filtered_keys}      = [];
    $self->{non_filtered_keys}  = [];

    my @request_keys =  keys %$request;
    # sorting for filter debugging only
    if (DEBUG_MODE & DEBUG_SORT_KEYS_ALPHA) {
        @request_keys = sort {$a cmp $b} @request_keys;
    }
    elsif (DEBUG_MODE & DEBUG_SORT_KEYS_NUM) {
        @request_keys = sort {$a <=> $b} @request_keys;
    }

    foreach my $key (@request_keys) {
        my $filter_impact   = 0;
        my $key_converted   = '';
        my $value_converted = '';
        my $time_ms         = 0;
        my @matched_filters = ();
        my @matched_tags    = ();

        my $request_value = defined $request->{$key} ? $request->{$key} : '';

        if (DEBUG_MODE & DEBUG_KEY_VALUES) {
            print "\n\n\n******************************************\n".
                "Key    : $key\nValue  : $request_value\n";
        }

        if ($self->{whitelist}->is_suspicious(key => $key, request => $request)) {
            $request_value = $self->{whitelist}->convert_if_marked_encoded(key => $key, value => $request_value);
            my $attacks = $self->_apply_filters($request_value);
            if ($attacks->{impact}) {
                $filter_impact          += $attacks->{impact};
                $time_ms                += $attacks->{time_ms};
                $value_converted        = $attacks->{string_converted};
                push (@matched_filters, @{$attacks->{filters}});
                push (@matched_tags,    @{$attacks->{tags}});
            }
        }

        # scan key only if desired
        if ($self->{scan_keys}) {
            # scan only if value is not harmless
            if ( !$self->{whitelist}->is_harmless_string($key) ) {
                # apply filters to key
                my $attacks             = $self->_apply_filters($key);
                $filter_impact          += $attacks->{impact};
                $time_ms                += $attacks->{time_ms};
                $key_converted          = $attacks->{string_converted};
                push (@matched_filters, @{$attacks->{filters}});
                push (@matched_tags,    @{$attacks->{tags}});
            }
            else {
                # skipped, alphanumeric key only
            }
        }

        # add attack to log
        my %attack = ();
        if ($filter_impact) {
            # make arrays unique and sorted
            my %seen = ();
            @matched_filters = sort grep { ! $seen{$_} ++ } @matched_filters;
            %seen = ();
            @matched_tags = sort grep { ! $seen{$_} ++ } @matched_tags;

            %attack = (
                key             => $key,
                key_converted   => $key_converted,
                value           => $request_value,
                value_converted => $value_converted,
                time_ms         => $time_ms,
                impact          => $filter_impact,
                matched_filters => \@matched_filters,
                matched_tags    => \@matched_tags,
            );
            push (@{$self->{attacks}}, \%attack);
        }
        $self->{impact} += $filter_impact;

        if (DEBUG_MODE & DEBUG_ARRAY_INFO && %attack) {
            use Data::Dumper;
            print "------------------------------------------\n".
                Dumper(\%attack) .
                "\n\n";
        }

        if (DEBUG_MODE & DEBUG_MATCHED_FILTERS && @matched_filters) {
            my $filters_concat = join ", ", @matched_filters;
            print "Filters: $filters_concat\n";
        }

        if (DEBUG_MODE & DEBUG_IMPACTS) {
            print "Impact : $filter_impact\n";
        }

    } # end of foreach key
    push (@{$self->{filtered_keys}},     @{$self->{whitelist}->suspicious_keys()});
    push (@{$self->{non_filtered_keys}}, @{$self->{whitelist}->non_suspicious_keys()});
    # reset filtered_keys and non_filtered_keys
    $self->{whitelist}->reset();

    if ($self->{impact} > 0) {
        return $self->{impact};
    }
    else {
        return 0;
    }
}

#****m* IDS/set_scan_keys
# NAME
#   set_scan_keys
# DESCRIPTION
#   Sets key scanning option
# INPUT
#   +scan_keys  1 to scan keys, 0 to switch off scanning keys, defaults to 0
# OUTPUT
#   none
# SYNOPSIS
#   $ids->set_scan_keys(scan_keys => 1);
#****

=head2 set_scan_keys()

 DESCRIPTION
   Sets key scanning option
 INPUT
   +scan_keys   1 to scan keys, 0 to switch off scanning keys, defaults to 0
 OUTPUT
   none
 SYNOPSIS
   $ids->set_scan_keys(scan_keys => 1);

=cut

sub set_scan_keys {
    my ($self, %args) = @_;

    $self->{scan_keys}  = $args{scan_keys} ? 1 : 0;
}

#****m* IDS/get_attacks
# NAME
#   get_attacks
# DESCRIPTION
#   Get an key/value/impact array of all detected attacks.
#   The array is emptied at the start of each run of detect_attacks().
# INPUT
#   none
# OUTPUT
#   HASHREF (
#     key     => '',
#     value   => '',
#     impact  => n,
#     filters => (n, n, n, n, ...),
#     tags    => ('', '', '', '', ...),
#   )
# SYNOPSIS
#   $ids->get_attacks();
#****

=head2 get_attacks()

 DESCRIPTION
   Get an key/value/impact array of all detected attacks.
   The array is emptied at the start of each run of C<detect_attacks()>.
 INPUT
   none
 OUTPUT
   ARRAY (
     key     => '',
     value   => '',
     impact  => n,
     filters => (n, n, n, n, ...),
     tags    => ('', '', '', '', ...),
   )
 SYNOPSIS
   $ids->get_attacks();

=cut

sub get_attacks {
    my ($self) = @_;

    return $self->{attacks};
}

#****m* IDS/get_rule_description
# NAME
#   get_rule_description
# DESCRIPTION
#   This sub returns the rule description for a given rule id. This can be used for logging purposes.
# INPUT
#   HASH
#   + rule_id      id of rule
# OUTPUT
#   SCALAR description
# EXAMPLE
#   $ids->get_rule_description( rule_id => $rule_id );
#****

=head2 get_rule_description()

 DESCRIPTION
   Returns the rule description for a given rule id. This can be used for logging purposes.
 INPUT
   HASH
   + rule_id      id of rule
 OUTPUT
   SCALAR description
 EXAMPLE
   $ids->get_rule_description( rule_id => $rule_id );

=cut

sub get_rule_description {
    my ($self, %args) = @_;
    return $self->{rule_descriptions}{$args{rule_id}};
}

#****im* IDS/_apply_filters
# NAME
#   _apply_filters
# DESCRIPTION
#   Applies filter rules to a string to detect attacks
# INPUT
#   + $string   string to be checked for possible attacks
# OUTPUT
#   attack hashref:
#     (
#       impact          => n,
#       filters         => (n, n, n, ...),
#       tags            => ('', '', '', ...),
#       string_converted => string
#     )
# SYNOPSIS
#   IDS::_apply_filters($string);
#****

sub _apply_filters {
    my ($self, $string) = @_;
    my %attack = (
        filters         => [],
        tags            => [],
        impact          => 0,
        string_converted => '',
    );

    # benchmark
    my $start_time = Time::HiRes::time();

    # make UTF-8 and sanitize from malformated UTF-8, if necessary
    $string = $self->{whitelist}->make_utf_8($string);

    # run all string converters
    $attack{string_converted} = _run_all_converters($string);

    # apply filters
    foreach my $filter (@{$self->{filters}}) {

        # skip disabled filters
        next if ($self->{filter_disabled}{$filter->{id}});
        my $string_converted_lc = lc($attack{string_converted});
        if ($string_converted_lc =~ $filter->{rule}) {
            $attack{impact} += $filter->{impact};
            push (@{$attack{filters}}, $filter->{id});
            push (@{$attack{tags}}, @{$filter->{tags}});
        }
    }

    # benchmark
    my $end_time = Time::HiRes::time();
    $attack{time_ms} = int(($end_time-$start_time)*1000);

    return \%attack;
}

#****im* IDS/_load_filters_from_xml
# NAME
#   _load_filters_from_xml
# DESCRIPTION
#   loads the filters from PHPIDS filter XML file
# INPUT
#   filterfile    path + name of the XML filter file
# OUTPUT
#   filtercount   number of loaded filters
# SYNOPSIS
#   IDS::_load_filters_from_xml('/home/xyz/default_filter.xml');
#****

sub _load_filters_from_xml {
    my ($self, $filterfile) = @_;
    my $filtercnt = 0;

    if ($filterfile) {
        # read & parse filter XML
        my $filterxml;
        eval {
            $filterxml = XML::Simple::XMLin($filterfile,
                forcearray  => [ qw(rule description tags tag impact filter filters)],
                keyattr     => [],
            );
        };
        if ($@) {
            croak "Error in _load_filters_from_xml while parsing $filterfile: $@";
        }

        # convert XML structure into handy data structure
        foreach my $filterobj (@{$filterxml->{filter}}) {
            my @taglist = ();
            foreach my $tag (@{$filterobj->{tags}[0]->{tag}}) {
                push(@taglist, $tag);
            }

            my $rule = '';
            eval {
                $rule = qr/$filterobj->{rule}[0]/ms;
            };
            if ($@) {
                croak 'Error in filter rule #' . $filterobj->{id} . ': ' . $filterobj->{rule}[0] . ' Message: ' . $@;
            }
            my %filterhash = (
                rule        => $rule,
                impact      => $filterobj->{impact}[0],
                id          => $filterobj->{id},
                tags        => \@taglist,
            );
            push (@{$self->{filters}}, \%filterhash);
            $self->{rule_descriptions}{$filterobj->{id}} = $filterobj->{description}[0];
            $filtercnt++
        }
    }
    return $filtercnt;
}

#****if* IDS/_run_all_converters
# NAME
#   _run_all_converters
# DESCRIPTION
#   Runs all converter functions
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_run_all_converters($value);
#****

sub _run_all_converters {
    my ($value) = @_;
    if (DEBUG_MODE & DEBUG_CONVERTERS) {
        print "------------------------------------------\n\n";
    }

    foreach my $converter (@CONVERTERS) {
        no strict 'refs';
        $value = $converter->($value);
        if (DEBUG_MODE & DEBUG_CONVERTERS) {
            print "$converter output:\n$value\n\n";
        }
    }
    return $value;
}

#****if* IDS/_convert_from_repetition
# NAME
#   _convert_from_repetition
# DESCRIPTION
#   Make sure the value to normalize and monitor doesn't contain
#   possibilities for a regex DoS.
# INPUT
#   value   the value to pre-sanitize
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_repetition($value);
#****

sub _convert_from_repetition {
    my ($value) = @_;

    # remove obvios repetition patterns
    $value = preg_replace(
        qr/(?:(.{2,})\1{32,})|(?:[+=|\-@\s]{128,})/,
        'x',
        $value
    );
    return $value;
}

#****if* IDS/_convert_from_commented
# NAME
#   _convert_from_commented
# DESCRIPTION
#   Check for comments and erases them if available
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_commented($value);
#****

sub _convert_from_commented {
    my ($value) = @_;

    # check for existing comments
    if (preg_match(qr/(?:\<!-|-->|\/\*|\*\/|\/\/\W*\w+\s*$)|(?:--[^-]*-)/ms, $value)) { #/

        my @pattern = (
            qr/(?:(?:<!)(?:(?:--(?:[^-]*(?:-[^-]+)*)--\s*)*)(?:>))/ms,
            qr/(?:(?:\/\*\/*[^\/\*]*)+\*\/)/ms,
            qr/(?:--[^-]*-)/ms,
        );

        my $converted = preg_replace(\@pattern, ';', $value);
        $value    .= "\n" . $converted;
    }

    # make sure inline comments are detected and converted correctly
    $value = preg_replace(qr/(<\w+)\/+(\w+=?)/m, '$1/$2', $value);
    $value = preg_replace(qr/[^\\:]\/\/(.*)$/m, '/**/$1', $value);

    return $value;
}

#****if* IDS/_convert_from_whitespace
# NAME
#   _convert_from_whitespace
# DESCRIPTION
#   Strip newlines
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_whitespace($value);
#****

sub _convert_from_whitespace {
    my ($value) = @_;

    # check for inline linebreaks
    my @search = ('\r', '\n', '\f', '\t', '\v');
    $value  = str_replace(\@search, ';', $value);

    # replace replacement characters regular spaces
    $value = str_replace('�', ' ', $value);

    # convert real linebreaks (\013 in Perl instead of \v in PHP et al.)
    return preg_replace(qr/(?:\n|\r|\013)/m, '  ', $value);
}

#****if* IDS/_convert_from_js_charcode
# NAME
#   _convert_from_js_charcode
# DESCRIPTION
#   Checks for common charcode pattern and decodes them
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_js_charcode($value);
#****

sub _convert_from_js_charcode {
    my ($value) = @_;

    my @matches = ();

    # check if value matches typical charCode pattern
    # PHP to Perl note: additional parenthesis around RegEx for getting PHP's $matches[0]
    if (preg_match_all(qr/(?:[\d+-=\/\* ]+(?:\s?,\s?[\d+-=\/\* ]+)){4,}/ms,
        $value, \@matches)) {
        my $converted   = '';
        my $string      = implode(',', $matches[0]);
        $string         = preg_replace(qr/\s/, '', $string);
        $string         = preg_replace(qr/\w+=/, '', $string);
        my @charcode    = explode(',', $string);

        foreach my $char (@charcode) {
            $char = preg_replace(qr/\W0/s, '', $char);

            my @matches = ();
            # PHP to Perl note: additional parenthesis around RegEx for getting PHP's $matches[0]
            if (preg_match_all(qr/(\d*[+-\/\* ]\d+)/, $char, \@matches)) {
                my @match = split(qr/(\W?\d+)/,
                                    (implode('', $matches[0])),
                                    # null,
                                    # PREG_SPLIT_DELIM_CAPTURE
                                    );
                                    # 3rd argument null, 4th argument PREG_SPLIT_DELIM_CAPTURE is default in Perl and not there
                my $test = implode('', $matches[0]);

                if (array_sum(@match) >= 20 && array_sum(@match) <= 127) {
                    $converted .= chr(array_sum(@match));
                }

            }
            elsif ($char && $char >= 20 && $char <= 127) {
                $converted .= chr($char);
            }
        }

        $value .= "\n" . $converted;
    }

    # check for octal charcode pattern
    # PHP to Perl note: \\ in Perl instead of \\\ in PHP
    # PHP to Perl note: additional parenthesis around RegEx for getting PHP's $matches[0]
    if (preg_match_all(qr/((?:(?:[\\]+\d+\s*){8,}))/ms, $value, \@matches)) {
        my $converted = '';
        my @charcode  = explode('\\', preg_replace(qr/\s/, '', implode(',',
            $matches[0])));

        foreach my $char (@charcode) {
            if ($char) {
                if (oct($char) >= 20 && oct($char) <= 127) {
                    $converted .= chr(oct($char));
                }
            }
        }
        $value .= "\n" . $converted;
    }

    # check for hexadecimal charcode pattern
    # PHP to Perl note: \\ in Perl instead of \\\ in PHP
    # PHP to Perl note: additional parenthesis around RegEx for getting PHP's $matches[0]
    if (preg_match_all(qr/((?:(?:[\\]+\w+[ \t]*){8,}))/ms, $value, \@matches)) {
        my $converted = '';
        my @charcode  = explode('\\', preg_replace(qr/[ux]/, '', implode(',',
            $matches[0])));

        foreach my $char (@charcode) {
            if ($char) {
                if (hex($char) >= 20 && hex($char) <= 127) {
                    $converted .= chr(hex($char));
                }
            }
        }
        $value .= "\n" . $converted;
    }

    return $value;

}

#****if* IDS/_convert_js_regex_modifiers
# NAME
#   _convert_js_regex_modifiers
# DESCRIPTION
#   Eliminate JS regex modifiers
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_js_regex_modifiers($value);
#****

sub _convert_js_regex_modifiers {
    my ($value) = @_;

    $value = preg_replace(qr/\/[gim]+/, '/', $value);
    return $value;
}

#****if* IDS/_convert_quotes
# NAME
#   _convert_quotes
# DESCRIPTION
#   Normalize quotes
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_quotes($value);
#****

sub _convert_quotes {
    my ($value) = @_;

    # normalize different quotes to "
    my @pattern = ('\'', '`', '´', '’', '‘');
    $value      = str_replace(\@pattern, '"', $value);

    # make sure harmless quoted strings don't generate false alerts
    $value = preg_replace(qr/^"([^"=\\!><~]+)"$/, '$1', $value);
    return $value;
}

#****if* IDS/_convert_from_sql_hex
# NAME
#   _convert_from_sql_hex
# DESCRIPTION
#   Converts SQLHEX to plain text
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_sql_hex($value);
#****

sub _convert_from_sql_hex {
    my ($value) = @_;

    my @matches = ();
    # PHP to Perl note: additional parenthesis around RegEx for getting PHP's $matches[0]
    if(preg_match_all(qr/((?:0x[a-f\d]{2,}[a-f\d]*)+)/im, $value, \@matches)) {
        foreach my $match ($matches[0]) {
            my $converted = '';
            foreach my $hex_index (str_split($match, 2)) {
                if(preg_match(qr/[a-f\d]{2,3}/i, $hex_index)) {
                    $converted .= chr(hex($hex_index));
                }
            }
            $value = str_replace($match, $converted, $value);
        }
    }
    # take care of hex encoded ctrl chars
    $value = preg_replace('/0x\d+/m', 1, $value);

    return $value;
}

#****if* IDS/_convert_from_sql_keywords
# NAME
#   _convert_from_sql_keywords
# DESCRIPTION
#   Converts basic SQL keywords and obfuscations
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_sql_keywords($value);
#****

sub _convert_from_sql_keywords {
    my ($value) = @_;

    my $pattern = qr/(?:IS\s+null)|(LIKE\s+null)|(?:(?:^|\W)IN[+\s]*\([\s\d"]+[^()]*\))/ims;
    $value   = preg_replace($pattern, '"=0', $value);
    $value   = preg_replace(qr/\W+\s*like\s*\W+/ims, '1" OR "1"', $value);
    $value   = preg_replace(qr/null[,"\s]/ims, ',0', $value);
    $value   = preg_replace(qr/\d+\./ims, ' 1', $value);
    $value   = preg_replace(qr/,null/ims, ',0', $value);
    $value   = preg_replace(qr/(?:between|mod)/ims, 'or', $value);
    $value   = preg_replace(qr/(?:and\s+\d+\.?\d*)/ims, '', $value);
    $value   = preg_replace(qr/(?:\s+and\s+)/ims, ' or ', $value);
    # \\N instead of PHP's \\\N
    $pattern    = qr/[^\w,\(]NULL|\\N|TRUE|FALSE|UTC_TIME|LOCALTIME(?:STAMP)?|CURRENT_\w+|BINARY|(?:(?:ASCII|SOUNDEX|FIND_IN_SET|MD5|R?LIKE)[+\s]*\([^()]+\))|(?:-+\d)/ims;
    $value      = preg_replace($pattern, 0, $value);
    $pattern    = qr/(?:NOT\s+BETWEEN)|(?:IS\s+NOT)|(?:NOT\s+IN)|(?:XOR|\WDIV\W|\WNOT\W|<>|RLIKE(?:\s+BINARY)?)|(?:REGEXP\s+BINARY)|(?:SOUNDS\s+LIKE)/ims;
    $value      = preg_replace($pattern, '!', $value);
    $value      = preg_replace(qr/"\s+\d/, '"', $value);
    $value      = preg_replace(qr/\/(?:\d+|null)/, '', $value);

    return $value;
}

#****if* IDS/_convert_entities
# NAME
#   _convert_entities
# DESCRIPTION
#   Converts from hex/dec entities (use HTML::Entities;)
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_entities($value);
#****

sub _convert_entities {
    my ($value) = @_;
    my $converted = '';

    # deal with double encoded payload
    $value = preg_replace(qr/&amp;/, '&', $value);

    if (preg_match(qr/&#x?[\w]+/ms, $value)) {
        $converted  = preg_replace(qr/(&#x?[\w]{2}\d?);?/ms, '$1;', $value);
        $converted  = HTML::Entities::decode_entities($converted);
        $value      .= "\n" . str_replace(';;', ';', $converted);
    }

    # normalize obfuscated protocol handlers
    $value = preg_replace(
        '/(?:j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*)|(d\s*a\s*t\s*a\s*)/ms',
        'javascript', $value
    );

    return $value;
}

#****if* IDS/_convert_from_control_chars
# NAME
#   _convert_from_control_chars
# DESCRIPTION
#   Detects nullbytes and controls chars via ord()
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_control_chars($value);
#****

sub _convert_from_control_chars {
    my ($value) = @_;

    # critical ctrl values
    my @search  = (
        chr(0), chr(1), chr(2), chr(3), chr(4), chr(5),
        chr(6), chr(7), chr(8), chr(11), chr(12), chr(14),
        chr(15), chr(16), chr(17), chr(18), chr(19), chr(24),
        chr(25), chr(192), chr(193), chr(238), chr(255)
    );
    $value  = str_replace(\@search, '%00', $value);

    # take care for malicious unicode characters
    $value = urldecode(preg_replace(qr/(?:%E(?:2|3)%8(?:0|1)%(?:A|8|9)\w|%EF%BB%BF|%EF%BF%BD)|(?:&#(?:65|8)\d{3};?)/i, '',
            urlencode($value)));

    $value = urldecode(
        preg_replace(qr/(?:%F0%80%BE)/i, '>', urlencode($value)));
    $value = urldecode(
        preg_replace(qr/(?:%F0%80%BC)/i, '<', urlencode($value)));
    $value = urldecode(
        preg_replace(qr/(?:%F0%80%A2)/i, '"', urlencode($value)));
    $value = urldecode(
        preg_replace(qr/(?:%F0%80%A7)/i, '\'', urlencode($value)));

    $value = preg_replace(qr/(?:%ff1c)/, '<', $value);
    $value = preg_replace(
        qr/(?:&[#x]*(200|820|200|820|zwn?j|lrm|rlm)\w?;?)/i, '', $value
    );

    $value = preg_replace(qr/(?:&#(?:65|8)\d{3};?)|(?:&#(?:56|7)3\d{2};?)|(?:&#x(?:fe|20)\w{2};?)|(?:&#x(?:d[c-f])\w{2};?)/i, '',
            $value);

    $value = str_replace(
        ["\x{ab}", "\x{3008}", "\x{ff1c}", "\x{2039}", "\x{2329}", "\x{27e8}"], '<', $value
    );
    $value = str_replace(
        ["\x{bb}", "\x{3009}", "\x{ff1e}", "\x{203a}", "\x{232a}", "\x{27e9}"], '>', $value
    );

    return $value;
}

#****if* IDS/_convert_from_nested_base64
# NAME
#   _convert_from_nested_base64
# DESCRIPTION
#   Matches and translates base64 strings and fragments used in data URIs (use MIME::Base64;)
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_nested_base64($value);
#****

sub _convert_from_nested_base64 {
    my ($value) = @_;

    my @matches = ();
    preg_match_all(qr/(?:^|[,&?])\s*([a-z0-9]{30,}=*)(?:\W|$)/im, #)/
        $value,
        \@matches,
    );
    # PHP to Perl note: PHP's $matches[1] is Perl's default ($matches[0] is the entire RegEx match)
    foreach my $item (@matches) {
        if ($item && !preg_match(qr/[a-f0-9]{32}/i, $item)) {

            # fill up the string with zero bytes if too short for base64 blocks
            my $item_original = $item;
            if (my $missing_bytes = length($item) % 4) {
                for (1..$missing_bytes) {
                    $item .= "=";
                }
            }

            my $base64_item = MIME::Base64::decode_base64($item);
            $value = str_replace($item_original, $base64_item, $value);
        }
    }

    return $value;
}

#****if* IDS/_convert_from_out_of_range_chars
# NAME
#   _convert_from_out_of_range_chars
# DESCRIPTION
#   Detects nullbytes and controls chars via ord()
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_out_of_range_chars($value);
#****

sub _convert_from_out_of_range_chars {
    my ($value) = @_;

    my @values = str_split($value);
    foreach my $item (@values) {
        if (ord($item) >= 127) {
            $value = str_replace($item, ' ', $value);
        }
    }

    return $value;
}

#****if* IDS/_convert_from_xml
# NAME
#   _convert_from_xml
# DESCRIPTION
#   Strip XML patterns
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_xml($value);
#****

sub _convert_from_xml {
    my ($value) = @_;

    my $converted = strip_tags($value);

    if ($converted && ($converted ne $value)) {
        return $value . "\n" . $converted;
    }
    return $value;
}

#****if* IDS/_convert_from_js_unicode
# NAME
#   _convert_from_js_unicode
# DESCRIPTION
#   Converts JS unicode code points to regular characters
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_js_unicode($value);
#****

sub _convert_from_js_unicode {
    my ($value) = @_;
    my @matches = ();

    # \\u instead of PHP's \\\u
    # PHP to Perl note: additional parenthesis around RegEx for getting PHP's $matches[0]
    preg_match_all(qr/(\\u[0-9a-f]{4})/ims, $value, \@matches);

    if ($matches[0]) {
        foreach my $match ($matches[0]) {
            my $chr = chr(hex(substr($match, 2, 4)));
            $value = str_replace($match, $chr, $value);
        }
        $value .= "\n".'\u0001';
    }
    return $value;
}

#****if* IDS/_convert_from_utf7
# NAME
#   _convert_from_utf7
# DESCRIPTION
#   Converts relevant UTF-7 tags to UTF-8 (use Encode qw/decode/;)
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_utf7($value);
#****

sub _convert_from_utf7 {
    my ($value) = @_;

    if (preg_match(qr/\+A\w+-/m, $value)) {
        $value .= "\n" . decode("UTF-7", $value);
    }

    return $value;
}

#****if* IDS/_convert_from_concatenated
# NAME
#   _convert_from_concatenated
# DESCRIPTION
#   Converts basic concatenations
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_concatenated($value);
#****

sub _convert_from_concatenated {
    my ($value) = @_;

    # normalize remaining backslashes
    # Perl's \\ should be equivalent to PHP's \\\
    if ($value ne preg_replace(qr/(?:(\w)\\)/, '$1', $value)) {
        $value .= preg_replace(qr/(?:(\w)\\)/, '$1', $value);
    }

    my $compare = stripslashes($value);

    my @pattern = (
        qr/(?:<\/\w+>\+<\w+>)/s,
        qr/(?:":\d+[^"[]+")/s,
        qr/(?:"?"\+\w+\+")/s,
        qr/(?:"\s*;[^"]+")|(?:";[^"]+:\s*")/s,
        qr/(?:"\s*(?:;|\+).{8,18}:\s*")/s,
        qr/(?:";\w+=)|(?:!""&&")|(?:~)/s,
        qr/(?:"?"\+""?\+?"?)|(?:;\w+=")|(?:"[|&]{2,})/s,
        qr/(?:"\s*\W+")/s,
        qr/(?:";\w\s*\+=\s*\w?\s*")/s,
        qr/(?:"[|&;]+\s*[^|&\n]*[|&]+\s*"?)/s,
        qr/(?:";\s*\w+\W+\w*\s*[|&]*")/s,
        qr/(?:"\s*"\s*\.)/s,
        qr/(?:\s*new\s+\w+\s*[+",])/,
        qr/(?:(?:^|\s+)(?:do|else)\s+)/,
        qr/(?:[{(]\s*new\s+\w+\s*[)}])/,
        qr/(?:(this|self)\.)/,
        qr/(?:undefined)/,
        qr/(?:in\s+)/,
    );

    # strip out concatenations
    my $converted = preg_replace(\@pattern, '', $compare);

    # strip object traversal
    $converted = preg_replace(qr/\w(\.\w\()/, '$1', $converted);

    # normalize obfuscated method calls
    $converted = preg_replace(qr/\)\s*\+/, ')', $converted);

    # convert JS special numbers
    $converted = preg_replace(qr/(?:\(*[.\d]e[+-]*[^a-z\W]+\)*)|(?:NaN|Infinity)\W/ims, 1, $converted);

    if ($converted && ($compare ne $converted)) {
        $value .= "\n" . $converted;
    }

    return $value;
}

#****if* IDS/_convert_from_proprietary_encodings
# NAME
#   _convert_from_proprietary_encodings
# DESCRIPTION
#   Collects and decodes proprietary encoding types
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_convert_from_proprietary_encodings($value);
#****

sub _convert_from_proprietary_encodings {
    my ($value) = @_;

    # Xajax error reportings
    $value = preg_replace(qr/<!\[CDATA\[(\W+)\]\]>/im, '$1', $value);

    # strip false alert triggering apostrophes
    $value = preg_replace(qr/(\w)\"(s)/m, '$1$2', $value);

    # strip quotes within typical search patterns
    $value = preg_replace(qr/^"([^"=\\!><~]+)"$/, '$1', $value);

    # OpenID login tokens
    $value = preg_replace(qr/{[\w-]{8,9}\}(?:\{[\w=]{8}\}){2}/, '', $value);

    # convert Content to null to avoid false alerts
    $value = preg_replace(qr/Content|\Wdo\s/, '', $value);

    # strip emoticons
    $value = preg_replace(qr/(?:\s[:;]-[)\/PD]+)|(?:\s;[)PD]+)|(?:\s:[)PD]+)|-\.-|\^\^/m, '', $value);

    # normalize separation char repetition
    $value = preg_replace(qr/([.+~=*_\-;])\1{2,}/m, '$1', $value);

    # normalize multiple single quotes
    $value = preg_replace(qr/"{2,}/m, '"', $value);

    # normalize quoted numerical values and asterisks
    $value = preg_replace(qr/"(\d+)"/m, '$1', $value);

    # normalize pipe separated request parameters
    $value = preg_replace(qr/\|(\w+=\w+)/m, '&$1', $value);

    # normalize ampersand listings
    $value = preg_replace(qr/(\w\s)&\s(\w)/, '$1$2', $value);

    return $value;
}

#****if* IDS/_run_centrifuge
# NAME
#   _run_centrifuge
# DESCRIPTION
#   The centrifuge prototype
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string
# SYNOPSIS
#   IDS::_run_centrifuge($value);
#****

sub _run_centrifuge {
    my ($value) = @_;

    my $threshold = 3.49;

    if (strlen($value) > 25) {
        # strip padding
        my $tmp_value = preg_replace(qr/\s{4}|==$/m, '', $value);
        $tmp_value = preg_replace(
            qr/\s{4}|[\p{L}\d\+\-=,.%()]{8,}/m,
            'aaa',
            $tmp_value
        );

        # Check for the attack char ratio
        $tmp_value = preg_replace(qr/([*.!?+-])\1{1,}/m, '$1', $tmp_value);
        $tmp_value = preg_replace(qr/"[\p{L}\d\s]+"/m, '', $tmp_value);

        my $stripped_length = strlen(
            preg_replace(qr/[\d\s\p{L}\.:,%&\/><\-)!]+/m,
            '',
            $tmp_value)
        );
        my $overall_length  = strlen(
            preg_replace(
                qr/([\d\s\p{L}:,\.]{3,})+/m,
                'aaa',
                preg_replace(
                    qr/\s{2,}/ms,
                    '',
                    $tmp_value
                )
            )
        );

        if ($stripped_length != 0 &&
            $overall_length/$stripped_length <= $threshold
        ) {
            $value .= "\n".'$[!!!]';
        }
    }

    if (strlen($value) > 40) {
        # Replace all non-special chars
        my $converted =  preg_replace(qr/[\w\s\p{L},.:!]/, '', $value);

        # Split string into an array, unify and sort
        my @array = str_split($converted);
        my %seen = ();
        my @unique = grep { ! $seen{$_} ++ } @array;
        @unique = sort @unique;

        # Normalize certain tokens
        my %schemes = (
            '~' => '+',
            '^' => '+',
            '|' => '+',
            '*' => '+',
            '%' => '+',
            '&' => '+',
            '/' => '+',
        );

        $converted  = implode('', @unique);
        $converted  = str_replace([keys %schemes], [values %schemes], $converted);
        $converted  = preg_replace(qr/[+-]\s*\d+/, '+', $converted);
        $converted  = preg_replace(qr/[()[\]{}]/, '(', $converted);
        $converted  = preg_replace(qr/[!?:=]/, ':', $converted);
        $converted  = preg_replace(qr/[^:(+]/, '', stripslashes($converted)); #/

        # Sort again and implode
        @array      = str_split($converted);
        @array      = sort @array;
        $converted  = implode('', @array);

        if (preg_match(qr/(?:\({2,}\+{2,}:{2,})|(?:\({2,}\+{2,}:+)|(?:\({3,}\++:{2,})/, $converted)) {
            return $value . "\n" . $converted;
        }
    }

    return $value;
}

#------------------------- PHP functions ---------------------------------------

#****if* IDS/array_sum
# NAME
#   array_sum
# DESCRIPTION
#   Equivalent to PHP's array_sum, sums all array values
# INPUT
#   array   the string to convert
# OUTPUT
#   sum     sum of all array values
# SYNOPSIS
#   IDS::array_sum(@array);
#****

sub array_sum {
    (my @array) = @_;

    my $sum = 0;
    foreach my $value (@array) {
        if ($value) {
            $sum += $value;
        }
    }
    return $sum;
}

#****if* IDS/preg_match
# NAME
#   preg_match
# DESCRIPTION
#   Equivalent to PHP's preg_match, but with two arguments only
# INPUT
#   pattern   the pattern to match
#   string    the string
# OUTPUT
#   boolean   1 if pattern matches string, 0 otherwise
# SYNOPSIS
#   IDS::preg_match($pattern, $string);
#****

sub preg_match {
    (my $pattern, my $string) = @_;
    return ($string =~ $pattern);
}

#****if* IDS/preg_match_all
# NAME
#   preg_match_all
# DESCRIPTION
#   Equivalent to PHP's preg_match_all, but with three arguments only.
#   Does not return nested arrays like PHP.
#   Does not automatically match entire RegEx in $matches[0] like PHP does -
#   Use brackets around your entire RegEx instead: preg_match_all(qr/(your(\d)(R|r)egex)/.
# INPUT
#   pattern     the pattern to match
#   string      the string
#   arrayref    the array to store the matches in
# OUTPUT
#   array       same content as written into arrayref
# SYNOPSIS
#   IDS::preg_match_all(qr/(?:[\d+-=\/\* ]+(?:\s?,\s?[\d+-=\/\* ]+)+){4,}/ms, $value, \@matches)
#   if (IDS::preg_match_all(qr/(?:[\d+-=\/\* ]+(?:\s?,\s?[\d+-=\/\* ]+)+){4,}/ms, $value, \@matches)) {
#       print 'match';
#   }
#****

sub preg_match_all {
    (my $pattern, my $string, my $matches) = @_;
    return (@$matches = ($string =~ /$pattern/g));
}

#****if* IDS/preg_replace
# NAME
#   preg_replace
# DESCRIPTION
#   Equivalent to PHP's preg_replace, but with three arguments only
# INPUT
#   + pattern      the pattern(s) to match
#   replacement  the replacement(s)
#   + string       the string(s)
# OUTPUT
#   string       the string(s) with all replacements done
# SYNOPSIS
#   IDS::preg_replace(\@patterns, $replacement, $string);
#   IDS::preg_replace(qr/^f.*ck/i, 'censored', $string);
#   IDS::preg_replace(['badword', 'badword2', 'badword3'], ['censored1', 'censored2', 'censored3'], $string);
#****

sub preg_replace {
    (my $patterns, my $replacements, my $strings) = @_;

    # check input
    if (!defined($strings) || !$strings ||
        !defined($patterns) || !$patterns ) {
        return '';
    }

    my $return_string = '';
    if (ref($strings) ne 'ARRAY') {
        $return_string = $strings;
    }

    if (ref($strings) eq 'ARRAY') {
        my @replaced_strings = map {
            preg_replace($patterns, $replacements, $_);
        } @$strings;
        return \@replaced_strings;
    }
    elsif (ref($patterns) eq 'ARRAY') {
        my $pattern_no = 0;
        foreach my $pattern (@$patterns) {
            if (ref($replacements) eq 'ARRAY') {
                $return_string = preg_replace($pattern, @$replacements[$pattern_no++], $return_string);
            }
            else {
                $return_string = preg_replace($pattern, $replacements, $return_string);
            }
        }
    }
    else {
        my $repl = '';

        if (ref($replacements) eq 'ARRAY') {
            $repl = @$replacements[0];
        }
        else {
            if (!defined($replacements)) {
                $repl = '';
            }
            else {
                $repl = $replacements;
            }
        }
        $repl =~ s/\\/\\\\/g;
        $repl =~ s/\"/\\"/g;
        $repl =~ s/\@/\\@/g;
        $repl =~ s/\$(?!\d)/\\\$/g; # escape $ if not substitution variable like $1
        $repl = qq{"$repl"};
        $return_string =~ s/$patterns/defined $repl ? $repl : ''/eeg;
    }
    return $return_string;
}

#****if* IDS/str_replace
# NAME
#   str_replace
# DESCRIPTION
#   Equivalent to PHP's str_replace, but with three arguments only (simply a wrapper for preg_replace, but escapes pattern meta characters)
# INPUT
#   pattern      the pattern(s) to match
#   replacement  the replacement(s)
#   string       the string(s)
# OUTPUT
#   string       the string(s) with all replacements done
# SYNOPSIS
#   IDS::str_replace(\@patterns, $replacement, $string);
#   IDS::str_replace('bad\tword', 'censored', $string); # replaces 'bad\tword' but not 'bad word' or "bad\tword"
#   IDS::str_replace(['badword', 'badword2', 'badword3'], ['censored1', 'censored2', 'censored3'], $string);
#****

sub str_replace {
    (my $patterns, my $replacements, my $strings) = @_;

    my @escapedpatterns = ();

    if (ref($patterns) eq 'ARRAY') {
        @escapedpatterns = map {quotemeta($_)} @$patterns;
        return preg_replace(\@escapedpatterns, $replacements, $strings);
    }
    else {
        return preg_replace(quotemeta($patterns), $replacements, $strings);
    }
}

#****if* IDS/str_split
# NAME
#   str_split
# DESCRIPTION
#   Equivalent to PHP's str_split
# INPUT
#   string  the string to split
# OUTPUT
#   array   the split string
# SYNOPSIS
#   IDS::str_split($string);
#****

sub str_split {
    (my $string, my $limit) = @_;
    if (defined($limit)) {
        return ($string =~ /(.{1,$limit})/g);
    }
    else {
        return split(//, $string);
    }
}

#****if* IDS/strlen
# NAME
#   strlen
# DESCRIPTION
#   Equivalent to PHP's strlen, wrapper for Perl's length()
# INPUT
#   string  the string
# OUTPUT
#   string  the string's length
# SYNOPSIS
#   IDS::strlen($url);
#****

sub strlen {
    (my $string) = @_;
    return length($string);
}

#****if* IDS/urldecode
# NAME
#   urldecode
# DESCRIPTION
#   Equivalent to PHP's urldecode
# INPUT
#   string  the URL to decode
# OUTPUT
#   string  the decoded URL
# SYNOPSIS
#   IDS::urldecode($url);
#****

sub urldecode {
    (my $theURL) = @_;
    $theURL =~ tr/+/ /;
    $theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $theURL =~ s/<!–(.|\n)*–>//g;
    utf8::decode($theURL);
    return $theURL;
}

#****if* IDS/urlencode
# NAME
#   urlencode
# DESCRIPTION
#   Equivalent to PHP's urlencode
# INPUT
#   string  the URL to encode
# OUTPUT
#   string  the encoded URL
# SYNOPSIS
#   IDS::urlencode($url);
#****

sub urlencode {
    (my $theURL) = @_;
    $theURL =~ s/([\W])/sprintf("%%%02X",ord($1))/eg;
    utf8::encode($theURL);
    return $theURL;
}

#****if* IDS/implode
# NAME
#   implode
# DESCRIPTION
#   Equivalent to PHP's implode (simply wrapper of join)
# INPUT
#   string  glue    the glue to put between the pieces
#   array   pieces  the pieces to be put together
# OUTPUT
#   string  the imploded string
# SYNOPSIS
#   IDS::implode(';', @pieces);
#****

sub implode {
    (my $glue, my @pieces) = @_;
    return join($glue, @pieces);
}

#****if* IDS/explode
# NAME
#   explode
# DESCRIPTION
#   Equivalent to PHP's explode (simply wrapper of split, but escapes met characters)
# INPUT
#   string  glue    the glue to put between the pieces
#   string  string  the string to split
# OUTPUT
#   array   the exploded string
# SYNOPSIS
#   IDS::explode(';', $string);
#****

sub explode {
    (my $glue, my $string) = @_;
    return split(quotemeta($glue), $string);
}

#****if* IDS/stripslashes
# NAME
#   stripslashes
# DESCRIPTION
#   Equivalent to PHP's stripslashes
# INPUT
#   string  string  the string
# OUTPUT
#   string  the stripped string
# SYNOPSIS
#   IDS::stripslashes($string);
#****

sub stripslashes {
    (my $string) = @_;
    # $string =~ s/(?:\\(\'|\"|\\|\0|N))/$1/g;
    $string =~ s/\\([^\\])/$1/g;
    return $string;
}

#****if* IDS/strip_tags
# NAME
#   strip_tags
# DESCRIPTION
#   Equivalent to PHP's strip_tags, but without 'allowable_tags' parameter
# INPUT
#   string  string  the string
# OUTPUT
#   string  the stripped string
# SYNOPSIS
#   IDS::strip_tags($string);
#****

sub strip_tags {
    (my $string) = @_;

    while ($string =~ s/<\S[^<>]*(?:>|$)//gs) {};

    return $string;
}

1;

__END__

=head1 XML INPUT FILES

=head2 Filters

This module is compatible with the PHPIDS filter set.
Please find the latest (frequently updated) filter file from the PHPIDS Subversion repository at
L<https://dev.itratos.de/projects/php-ids/repository/raw/trunk/lib/IDS/default_filter.xml>.

=head3 Example XML Code

 <filters>
     <filter>
         <id>1</id>
         <rule><![CDATA[(?:"+.*>)|(?:[^\w\s]\s*\/>)|(?:>")]]></rule>
         <description>finds html breaking injections including whitespace attacks</description>
         <tags>
             <tag>xss</tag>
             <tag>csrf</tag>
         </tags>
         <impact>4</impact>
     </filter>
     <filter>
         <id>2</id>
         <rule><![CDATA[(?:"+.*[<=]\s*"[^"]+")|(?:"\w+\s*=)|(?:>\w=\/)|(?:#.+\)["\s]*>)|(?:"\s*(?:src|style|on\w+)\s*=\s*")]]></rule>
         <description>finds attribute breaking injections including whitespace attacks</description>
         <tags>
             <tag>xss</tag>
             <tag>csrf</tag>
         </tags>
         <impact>4</impact>
     </filter>
 </filters>

=head3 Used XML Tags

=over 4

=item * filters

The root tag.

=over 4

=item * filter

Filter item.

=over 4

=item * id

Filter ID for referring in log files etc.

=item * rule

The regular expression for detection of malicious code.
Case-insensitive; mode modifiers I<i>, I<m> and I<s> in use.

=item * description

Description of what the filter finds.

=item * tags

Set of tags that describe the kind of attack.

=over 4

=item * tag

Currently used values are I<xss>, I<csrf>, I<sqli>, I<dt>, I<id>, I<lfi>, I<rfe>, I<spam>, I<dos>.

=back

=item * impact

Value of impact, defines the weight of the attack.
Each detection run adds the particular filter impacts to one total impact sum.

=back

=back

=back

=head2 Whitelist

Using a whitelist you can improve the speed and the accurancy (reduce false positives) of the IDS. A whitelist defines which
parameters do not need to undergo the expensive scanning (if their values match given rules and given conditions).

=head3 Example XML Code

 <whitelist>
     <param>
         <key>scr_id</key>
         <rule><![CDATA[(?:^[0-9]+\.[0-9a-f]+$)]]></rule>
     </param>
     <param>
         <key>uid</key>
     </param>
     <param>
         <key>json_value</key>
         <encoding>json</encoding>
     </param>
     <param>
         <key>login_password</key>
         <conditions>
             <condition>
                 <key>username</key>
                 <rule><![CDATA[(?:^[a-z]+$)]]></rule>
            </condition>
            <condition>
                <key>send</key>
            </condition>
            <condition>
                <key>action</key>
                <rule><![CDATA[(?:^login$)]]></rule>
            </condition>
         </conditions>
     </param>
     <param>
         <key>sender_id</key>
         <rule><![CDATA[(?:[0-9]+\.[0-9a-f]+)]]></rule>
         <conditions>
             <condition>
                 <key>action</key>
                 <rule><![CDATA[(?:^message$)]]></rule>
            </condition>
         </conditions>
     </param>
 </whitelist>

=head3 Used XML Tags

=over 4

=item * whitelist

The root tag.

=over 4

=item * param

Parameter item. Defines the query parameter to be whitelisted.

=over 4

=item * key

Parameter key.

=item * rule

Regular expression to match.
If the parameter value matches this rule or the rule tag is not present, the IDS will not run its filters on it.
Case-sensitive; mode modifiers I<m> and I<s> in use.

=item * encoding

Use value I<json> if the parameter contains JSON encoded data. IDS will test the decoded data,
otherwise a false positive would occur due to the 'suspicious' JSON encoding characters.

=item * conditions

Set of conditions to be fulfilled. This is the parameter environment in which
the whitelisted parameter has to live in. The parameter will only be skipped if
all conditions (and its own parameter rule) match.

In the example XML this means: I<login_password> may only be skipped of filtering if
parameter I<action> equals I<login>, parameter I<send> is present
and parameter I<username> contains only small letters.

=over 4

=item * condition

A condition to be fulfilled.

=over 4

=item * key

Parameter key.

=item * rule

Regular expression to match. Missing C<E<lt>ruleE<gt>> means I<key has to be present no matter what content (can even be empty)>.

=back

=back

=back

=back

=back

=head3 Helper methods for building and improving whitelists

 # check request
 my $impact = $ids->detect_attacks( request => $request);

 # print reasons and key/value pairs to a logfile for analysis of your application parameters.
 print LOG "filtered_keys:\n"
 foreach my $entry (@{$ids->{filtered_keys}}) {
     print LOG "\t".$entry->{reason}."\t".$entry->{key}.' => '.$entry->{value}."\n";
 }
 print LOG "non_filtered_keys:\n"
 foreach my $entry (@{$ids->{non_filtered_keys}}) {
     print LOG "\t".$entry->{reason}."\t".$entry->{key}.' => '.$entry->{value}."\n";
 }

C<$entry-E<gt>{reason}> returns following reasons for skipping and non-skipping a value:

=over 4

=item C<$ids-E<gt>{filtered_keys}>

=over 4

=item * I<key>: key not whitelisted

Filtered due to missing rule set for this key.

=item * I<cond>: condition mismatch

Filtered due to mismatching conditions for this key.

=item * I<rule>: rule mismatch

Filtered due to mismatching rule for this key.

=item * I<enc>: value contains encoding

Filtered due to containing (JSON) encoding for this key.

=back

=back

=over 4

=item C<$ids-E<gt>{non_filtered_keys}>

=over 4

=item * I<empty>: empty value

Not filtered due to empty value for this key.

=item * I<harml>: harmless value

Not filtered due to harmless value string for this key.

=item * I<key>: key generally whitelisted

Not filtered because the key has been generally whitelisted.

=item * I<r&c>: rule & conditions matched

Not filtered due to matching rules and conditions for this key.

=back

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-ids at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-IDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::IDS


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/hinnerk-a/perlids>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-IDS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-IDS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-IDS>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-IDS>

=back

=head1 CREDITS

Thanks to:

=over 4

=item * Mario Heiderich (L<https://phpids.org/>)

=item * Christian Matthies (L<https://phpids.org/>)

=item * Ingo Bax (L<http://www.epublica.de/>)

=item * epublica GmbH (L<http://www.epublica.de/>)

=item * XING AG (L<https://www.xing.com/>) for making this work possible and running PerlIDS under heavy load for a long time.


=back

=head1 AUTHOR

Hinnerk Altenburg, C<< <hinnerk at cpan.org> >>

=head1 SEE ALSO

L<https://phpids.org/>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008-2014 Hinnerk Altenburg (L<http://www.hinnerk-altenburg.de/>)

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
