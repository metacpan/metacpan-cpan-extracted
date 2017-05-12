package CGI::IDS::Whitelist;

our $VERSION = '1.0217';

#------------------------- Notes -----------------------------------------------
# This source code is documented in both POD and ROBODoc format.
# Please find additional POD documentation at the end of this file
# (search for "__END__").
#-------------------------------------------------------------------------------

#****c* IDS::Whitelist
# NAME
#   PerlIDS Whitelist (CGI::IDS::Whitelist)
# DESCRIPTION
#   Whitelist Processor for PerlIDS (CGI::IDS)
# AUTHOR
#   Hinnerk Altenburg <hinnerk@cpan.org>
# CREATION DATE
#   2010-03-29
# COPYRIGHT
#   Copyright (C) 2010-2014 Hinnerk Altenburg
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

CGI::IDS::Whitelist - Whitelist Processor for PerlIDS - Perl Website Intrusion Detection System (XSS, CSRF, SQLI, LFI etc.)

=head1 DESCRIPTION

Whitelist Processor for PerlIDS (L<CGI::IDS|CGI::IDS>). Performs a basic string check and the whitelist check.
See section L<CGI::IDS/Whitelist> for details on setting up a whitelist file. CGI::IDS::Whitelist may also be
used standalone without CGI::IDS to check whether a request has suspicious parameters at all before
handing it over to CGI::IDS. This may be the case if you let worker servers do the more expensive
CGI::IDS job and only want to send over the requests that have suspicious parameters.
See L<SYNOPSIS|CGI::IDS::Whitelist/SYNOPSIS> for an example.

=head1 SYNOPSIS

 use CGI;
 use CGI::IDS::Whitelist;

 $query = new CGI;

 my $whitelist = CGI::IDS::Whitelist->new(
   whitelist_file  => '/home/hinnerk/sandbox/ids/cgi-bin/param_whitelist.xml',
 );

 my @request_keys = keys %$query->Vars;
 foreach my $key (@request_keys) {
   if ( $whitelist->is_suspicious(key => $key, request => $query->Vars ) {
     send_to_ids_worker_server( $query->Vars );
     last;
   }
 }

=head1 METHODS

=cut

#------------------------- Pragmas ---------------------------------------------
use strict;
use warnings;

#------------------------- Libs ------------------------------------------------
use XML::Simple qw(:strict);
use Carp;
use JSON::XS;
use Encode;

#------------------------- Subs ------------------------------------------------

#****m* IDS/new
# NAME
#   Constructor
# DESCRIPTION
#   Creates a Whitelist object.
#   The whitelist will stay loaded during the lifetime of the object.
#   You may call is_suspicious() multiple times, the collecting debug
#   arrays suspicious_keys() and non_suspicious_keys() will only be
#   emptied by an explizit reset() call.
# INPUT
#   HASH
#     whitelist_file  STRING  The path to the whitelist XML file
# OUTPUT
#   Whitelist object, dies (croaks) if a whitelist parsing error occurs.
# EXAMPLE
#   # instantiate object
#   my $whitelist = CGI::IDS::Whitelist->new(
#       whitelist_file  => '/home/hinnerk/sandbox/ids/cgi-bin/param_whitelist.xml',
#   );
#   # instantiate object without a whitelist, just performs a basic string check
#   my $whitelist = CGI::IDS::Whitelist->new();

#****

=head2 new()

Constructor. Can optionally take the path to a whitelist file.
If I<whitelist_file> is not given, just a basic string check will be performed.

The whitelist will stay loaded during the lifetime of the object.
You may call C<is_suspicious()> multiple times, the collecting debug
arrays C<suspicious_keys()> and C<non_suspicious_keys()> will only be
emptied by an explizit C<reset()> call.

For example, the following are valid constructors:

 my $whitelist = CGI::IDS::Whitelist->new(
     whitelist_file  => '/home/hinnerk/sandbox/ids/cgi-bin/param_whitelist.xml',
 );

 my $whitelist = CGI::IDS::Whitelist->new();

The Constructor dies (croaks) if a whitelist parsing error occurs.

=cut

sub new {
    my ($package, %args) = @_;

    # self member variables
    my $self = {
        whitelist_file      => $args{whitelist_file},
        suspicious_keys     => [],
        non_suspicious_keys => [],
    };

    # create object
    bless $self, $package;

    # read & parse XML
    $self->_load_whitelist_from_xml($self->{whitelist_file});

    return $self;
}

#****m* IDS/Whitelist/is_suspicious
# NAME
#   is_suspicious
# DESCRIPTION
#   Performs the whitelist check for a given request parameter.
# INPUT
#   HASHREF
#     + key       The key of the request parameter to be checked
#     + request   HASHREF to the complete request (for whitelist conditions check)
# OUTPUT
#   1 if you should check it with the complete filter set,
#   0 if harmless or sucessfully whitelisted.
# SYNOPSIS
#   $whitelist->is_suspicious( key => 'mykey', request => $request );
#****

=head2 is_suspicious()

 DESCRIPTION
   Performs the whitelist check for a given request parameter.
 INPUT
   HASHREF
     + key       The key of the request parameter to be checked
     + request   HASHREF to the complete request (for whitelist conditions check)
 OUTPUT
   1 if you should check it with the complete filter set,
   0 if harmless or sucessfully whitelisted.
 SYNOPSIS
   $whitelist->is_suspicious( key => 'mykey', request => $request );

=cut

sub is_suspicious {
    my ($self, %args)       = @_;
    my $key                 = $args{key};
    my $request             = $args{request};
    my $request_value       = $args{request}->{$key};
    my $contains_encoding   = 0;

    # skip if value is empty or generally whitelisted
    if ( $request_value ne '' &&
        !(  $self->{whitelist}{$key} &&
            !defined($self->{whitelist}{$key}->{rule}) &&
            !defined($self->{whitelist}{$key}->{conditions}) &&
            !defined($self->{whitelist}{$key}->{encoding})
        )
    ) {
        my $request_value_orig = $request_value;
        $request_value = $self->convert_if_marked_encoded(key => $key, value => $request_value);
        if ($request_value ne $request_value_orig) {
            $contains_encoding = 1;
        }

        $request_value = $self->make_utf_8($request_value);

        # scan only if value is not harmless
        if ( !$self->is_harmless_string($request_value) ) {
            my $attacks = {};

            if (!$self->{whitelist}{$key}) {
                # apply filters to value, not in whitelist
                push (@{$self->{suspicious_keys}}, {key => $key, value => $request_value, reason => 'key'}); # key not whitelisted
                return 1;
            }
            else {
                # check if all conditions match
                my $condition_mismatch = 0;
                foreach my $condition (@{$self->{whitelist}{$key}->{conditions}}) {
                    if (! defined($request->{$condition->{key}}) ||
                        ( defined ($condition->{rule}) && $request->{$condition->{key}} !~ $condition->{rule} )
                    ) {
                        $condition_mismatch = 1;
                    }
                }

                # Apply filters if key is not in whitelisted environment conditions
                # or if the value does not match the whitelist rule if one is set.
                # Filtering is skipped if no rule is set.
                if ( $condition_mismatch ||
                    (defined($self->{whitelist}{$key}->{rule}) &&
                    $request_value !~ $self->{whitelist}{$key}->{rule}) ||
                    $contains_encoding
                ) {
                    # apply filters to value, whitelist rules mismatched
                    my $reason = '';
                    if ($condition_mismatch) {
                        $reason = 'cond'; # condition mismatch
                    }
                    elsif (!$contains_encoding) {
                        $reason = 'rule'; # rule mismatch
                    }
                    else {
                        $reason = 'enc'; # contains encoding
                    }
                    push (@{$self->{suspicious_keys}}, {key => $key, value => $request_value, reason => $reason});
                    return 1;
                }
                else {
                    # skipped, whitelist rule matched
                    push (@{$self->{non_suspicious_keys}}, {key => $key, value => $request_value, reason => 'r&c'}); # rule & conditions matched
                }
            }
        }
        else {
            # skipped, harmless string
            push (@{$self->{non_suspicious_keys}}, {key => $key, value => $request_value, reason => 'harml'}); # harmless
        }
    }
    else {
        # skipped, empty value or key generally whitelisted
        my $reason = $request_value ? 'key' : 'empty';
        push (@{$self->{non_suspicious_keys}}, {key => $key, value => $request_value, reason => $reason});
    }
    return 0;
}

#****m* IDS/Whitelist/convert_if_marked_encoded
# NAME
#   convert_if_marked_encoded
# DESCRIPTION
#   Tries to JSON-decode and flatten a value to a plain string if the key has been marked as JSON in the whitelist.
#   Other encodings may follow in future.
# INPUT
#   HASHREF
#     + key
#     + value
# OUTPUT
#   The JSON-decoded and flattened 'value' if key is marked JSON. Plain keys and values, newline separated.
#   Untouched 'value' otherwise.
# SYNOPSIS
#   $whitelist->convert_if_marked_encoded( key => 'data', value = '{"a":"b","c":["123", 111, "456"]}');
#****

=head2 convert_if_marked_encoded()

 DESCRIPTION
   Tries to JSON-decode and flatten a value to a plain string if the key has been marked as JSON in the whitelist.
   Other encodings may follow in future.
 INPUT
   HASHREF
     + key
     + value
 OUTPUT
   The JSON-decoded and flattened 'value' if key is marked JSON. Plain keys and values, newline separated.
   Untouched 'value' otherwise.
 SYNOPSIS
   $whitelist->convert_if_marked_encoded( key => 'data', value => '{"a":"b","c":["123", 111, "456"]}');

=cut

sub convert_if_marked_encoded {
    my ($self, %args)   = @_;
    my $key             = $args{key};
    my $request_value   = $args{value};

    # If marked as JSON, try to convert from JSON to reduce false positives
    if (defined($self->{whitelist}{$key}) &&
        defined($self->{whitelist}{$key}->{encoding}) &&
        $self->{whitelist}{$key}->{encoding} eq 'json') {

        $request_value = _json_to_string($request_value);
    }
    return $request_value;
}

#****m* IDS/Whitelist/suspicious_keys
# NAME
#   suspicious_keys
# DESCRIPTION
#   Returns the set of filters that are suspicious
#   Keys are listed from the last reset() or Whitelist->new()
# INPUT
#   none
# OUTPUT
#   [ { 'value' => , 'reason' => , 'key' =>  }, { ... } ]
# SYNOPSIS
#   $whitelist->suspicious_keys();
#****

=head2 suspicious_keys()

 DESCRIPTION
   Returns the set of filters that are suspicious
   Keys are listed from the last reset() or Whitelist->new()
 INPUT
   none
 OUTPUT
   [ { 'value' => , 'reason' => , 'key' =>  }, { ... } ]
 SYNOPSIS
   $whitelist->suspicious_keys();

=cut

sub suspicious_keys {
    my ($self) = @_;
    return $self->{suspicious_keys};
}

#****m* IDS/Whitelist/non_suspicious_keys
# NAME
#   non_suspicious_keys
# DESCRIPTION
#   Returns the set of filters that have been checked but are not suspicious
#   Keys are listed from the last reset() or Whitelist->new()
# INPUT
#   none
# OUTPUT
#   [ { 'value' => , 'reason' => , 'key' =>  }, { ... } ]
# SYNOPSIS
#   $whitelist->non_suspicious_keys();
#****

=head2 non_suspicious_keys()

 DESCRIPTION
   Returns the set of filters that have been checked but are not suspicious
   Keys are listed from the last reset() or Whitelist->new()
 INPUT
   none
 OUTPUT
   [ { 'value' => , 'reason' => , 'key' =>  }, { ... } ]
 SYNOPSIS
   $whitelist->non_suspicious_keys();

=cut

sub non_suspicious_keys {
    my ($self) = @_;
    return $self->{non_suspicious_keys};
}

#****m* IDS/Whitelist/reset
# NAME
#   reset
# DESCRIPTION
#   resets the member variables suspicious_keys and non_suspicious_keys to []
# INPUT
#   none
# OUTPUT
#   none
# SYNOPSIS
#   $whitelist->reset();
#****

=head2 reset()

 DESCRIPTION
   resets the member variables suspicious_keys and non_suspicious_keys to []
 INPUT
   none
 OUTPUT
   none
 SYNOPSIS
   $whitelist->reset();

=cut

sub reset {
    my ($self) = @_;
    $self->{suspicious_keys}     = [];
    $self->{non_suspicious_keys} = [];
}

#****f* IDS/Whitelist/is_harmless_string
# NAME
#   is_harmless_string
# DESCRIPTION
#   Performs a basic regexp check for harmless characters
# INPUT
#   + string
# OUTPUT
#   BOOLEAN (pattern match return value)
# SYNOPSIS
#   $whitelist->is_harmless_string( $string );
#****

=head2 is_harmless_string()

 DESCRIPTION
   Performs a basic regexp check for harmless characters
 INPUT
   + string
 OUTPUT
   BOOLEAN (pattern match return value)
 SYNOPSIS
   $whitelist->is_harmless_string( $string );

=cut

sub is_harmless_string {
    my ($self, $string) = @_;

    $string = $self->make_utf_8($string);

    return ( $string !~ m/[^\w\s\/@!?\.]+|(?:\.\/)|(?:@@\w+)/ );
}

#****f* IDS/Whitelist/make_utf_8
# NAME
#   make_utf_8
# DESCRIPTION
#   Encodes string to UTF-8 and strips malformed UTF-8 characters
# INPUT
#   + string
# OUTPUT
#   UTF-8 string
# SYNOPSIS
#   $whitelist->make_utf_8( $string );
#****

=head2 make_utf_8()

 DESCRIPTION
   Encodes string to UTF-8 and strips malformed UTF-8 characters
 INPUT
   + string
 OUTPUT
   UTF-8 string
 SYNOPSIS
   $whitelist->make_utf_8( $string );

=cut

sub make_utf_8 {
    my ($self, $string) = @_;

    # make string UTF-8
    my $utf8_encoded = '';
    eval {
        $utf8_encoded = Encode::encode('UTF-8', $string, Encode::FB_CROAK);
    };
    if ($@) {
        # sanitize malformed UTF-8
        $utf8_encoded = '';
        my @chars = split(//, $string);
        foreach my $char (@chars) {
            my $utf_8_char = eval { Encode::encode('UTF-8', $char, Encode::FB_CROAK) }
                or next;
            $utf8_encoded .= $utf_8_char;
        }
    }
    return $utf8_encoded;
}

#****im* IDS/Whitelist/_load_whitelist_from_xml
# NAME
#   _load_whitelist_from_xml
# DESCRIPTION
#   loads the parameter whitelist XML file
#   croaks if a xml or regexp parsing error occors
# INPUT
#   whitelistfile   path + name of the XML whitelist file
# OUTPUT
#   int             number of loaded rules
# SYNOPSIS
#   $self->_load_whitelist_from_xml('/home/xyz/param_whitelist.xml');
#****

sub _load_whitelist_from_xml {
    my ($self, $whitelistfile) = @_;
    my $whitelistcnt = 0;

    if ($whitelistfile) {
        # read & parse whitelist XML
        my $whitelistxml;
        eval {
            $whitelistxml = XMLin($whitelistfile,
                forcearray  => [ qw(whitelist param conditions condition)],
                keyattr     => [],
            );
        };
        if ($@) {
            croak "Error in _load_whitelist_from_xml while parsing $whitelistfile: $@";
        }

        # convert XML structure into handy data structure
        foreach my $whitelistobj (@{$whitelistxml->{param}}) {
            my @conditionslist = ();
            foreach my $condition (@{$whitelistobj->{conditions}[0]{condition}}) {
                if (defined($condition->{rule})) {
                    # copy for error message
                    my $rule = $condition->{rule};

                    eval {
                        $condition->{rule} = qr/$condition->{rule}/ms;
                    };
                    if ($@) {
                        croak 'Error in whitelist rule of condition "' . $condition->{key} . '" for param "' . $whitelistobj->{key} . '": ' . $rule . ' Message: ' . $@;
                    }
                }
                push(@conditionslist, $condition);
            }
            my %whitelisthash = ();
            if (defined($whitelistobj->{rule})) {
                eval {
                    $whitelisthash{rule} = qr/$whitelistobj->{rule}/ms;
                };
                if ($@) {
                    croak 'Error in whitelist rule for param "' . $whitelistobj->{key} . '": ' . $whitelistobj->{rule} . ' Message: ' . $@;
                }
            }
            if (@conditionslist) {
                $whitelisthash{conditions} = \@conditionslist;
            }
            if ($whitelistobj->{encoding}) {
                $whitelisthash{encoding} = $whitelistobj->{encoding};
            }
            $self->{whitelist}{$whitelistobj->{key}} = \%whitelisthash;
            $whitelistcnt++;
        }
    }
    return $whitelistcnt;
}

#****if* IDS/Whitelist/_json_to_string
# NAME
#   _json_to_string
# DESCRIPTION
#   Tries to decode a string from JSON. Uses _datastructure_to_string().
# INPUT
#   value   the string to convert
# OUTPUT
#   value   converted string if correct JSON, the unchanged input string otherwise
# SYNOPSIS
#   IDS::Whitelist::_json_to_string($value);
#****

sub _json_to_string {
    my ($value) = @_;
    my $json_ds;
    eval {
        $json_ds = JSON::XS::decode_json($value);
    };
    if (!$@) {
        $value = _datastructure_to_string($json_ds)."\n";
    }
    return $value;
}

#****if* IDS/Whitelist/_datastructure_to_string
# NAME
#   _datastructure_to_string
# DESCRIPTION
#   Walks recursively through array or hash and concatenates keys and values to one single string (\n separated)
# INPUT
#   ref     the array/hash to convert
# OUTPUT
#   string  converted string
# SYNOPSIS
#   IDS::Whitelist::_datastructure_to_string($ref);
#****

sub _datastructure_to_string {
    my $in = shift;
    my $out = '';
    if (ref $in eq 'HASH') {
        foreach (keys %$in) {
            $out .= $_."\n";
            $out .= _datastructure_to_string($in->{$_});
        }
    }
    elsif (ref $in eq 'ARRAY') {
        foreach (@$in) {
            $out = _datastructure_to_string($_) . $out;
        }
    }
    else {
            $out .= $in."\n";
    }
    return $out;
}

1;

__END__

=head1 BUGS & SUPPORT

see L<CGI::IDS/BUGS> and L<CGI::IDS/SUPPORT>

=head1 AUTHOR

Hinnerk Altenburg, C<< <hinnerk at cpan.org> >>

=head1 SEE ALSO

L<CGI::IDS>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2014 Hinnerk Altenburg (L<http://www.hinnerk-altenburg.de/>)

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
