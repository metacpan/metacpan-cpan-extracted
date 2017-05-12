package Blitz::Validate;

use strict;
use warnings;
use Regexp::Common qw/URI/;

=head1 NAME

Blitz::Validate - Perl module for assisting with the validation of calls to Blitz.io

=cut

=head2 validate

Takes a hash reference of options to be sent to the blitz.io servers
and validates its content. Called before any tests are executed.

Detailed API docs for communicating with the blitz servers can be found here:
https://github.com/mudynamics/blitz-app/wiki/API-Docs

=cut

sub validate {
    my $options = shift;
    my $test_type = shift;
    my $reasons = [];

    # url
    if (!$options->{url}) {
        push @$reasons, "No URL given";
    }
    elsif (! _is_url($options->{url}) ) {
        push @$reasons, "Invalid URL: $options->{url}";
    }

    # pattern
    if ($options->{pattern} && $test_type eq 'rush') {
        if (!$options->{pattern}{iterations} || ! _is_integer($options->{pattern}{iterations}) ) {
            push @$reasons, "Pattern iterations not given or not an integer";
        }
        else {
            $options->{pattern}{iterations} += 0;
        }
        if (! $options->{pattern}{intervals} || ! _is_array($options->{pattern}{intervals}) ) {
            push @$reasons, "Intervals is not an array";
        }
    }
    elsif ($options->{pattern} && $test_type eq 'sprint') {
        push @$reasons, 'Pattern is not a valid options for sprints';
    }

    # region
    if ($options->{region} && $options->{region} !~ /(california|virginia|ireland|singapore|japan)/) {

        push @$reasons, "Invalid region: $options->{region}";
    }

    # ssl
    if ($options->{ssl} && !
        ( $options->{ssl} eq 'tlsv1' || 
          $options->{ssl} eq 'sslv2' ||
          $options->{ssl} eq 'sslv3' ) 
          ){
        push @$reasons, "SSL needs to be one of the following: tlsv1, sslv2, or sslv3";
    }
    
    # data
    if ($options->{content}) {
        if (! _is_hash($options->{content})) {
            push @$reasons, "Content must be a hash";
        }
        elsif ( ! $options->{content}{data} || ! _is_array($options->{content}{data}) ) {
             push @$reasons, "Content hash must have a data key with an array value"; 
        }
    }

    # referer
    if ($options->{referer} && ! _is_url($options->{referer} )) {
        push @$reasons, "Invalid referer URL: " . $options->{referer};
    }
    # string params
    for my $key ('user-agent', 'user') {
        if ($options->{$key} && 
            ( _is_array($options->{$key}) || 
              _is_hash($options->{$key}) ) 
            ) {
                push @$reasons, "Invalid " . $key . ": " . "$options->{$key}";
        }
    }
    
    # integer params
    for my $key ('status', 'timeout') {
        if ($options->{$key} && $options->{$key} !~ /^\d+$/g) {
            push @$reasons, "Invalid " . $key . ": " . "$options->{$key}";
        }
    }
    
    # array params
    for my $key ('cookies', 'headers') {
        if ($options->{$key} && ! _is_array($options->{$key})) {
            push @$reasons, "values to $key not given as an array: " . $options->{$key};
        }
    }
    
    # XXX: variables
    # variables must be a hash
    # key/val pairs of hash must be name, followed by a hash of params
    # each params hash must have a type key, with the value being one of "list|alpha|number|udid"
    # if list, must have an entries key with a value of an array
    # if alpha, must have keys min and max, with integer values
    # if number, must have keys min and max, with integer values
    if ($options->{variables}) {
        if (! _is_hash($options->{variables})) {
            push @$reasons, "values to variables not given as a hash: " . $options->{variables};
        }
        else {
            for my $key (keys %{$options->{variables}}) {
                if (! _is_hash($options->{variables}{$key})) {
                    push @$reasons, 
                        "values to variables key $key not given as a hash: " . 
                        $options->{variables}{$key};
                }
                else {
                    my $type = $options->{variables}{$key}{type};
                    if (! $type) {
                        push @$reasons, "all variables must have a type definition";
                    }
                    elsif (! $type =~ /^(list|alpha|number|udid)$/) {
                        push @$reasons, "all variables must have type of list, alpha, number, or udid";
                    }
                    else {
                        if ($type eq 'list') {
                            if (! $options->{variables}{$key}{entries} ||
                                ! _is_array($options->{variables}{$key}{entries}) ) {
                                    push @$reasons, "all variables of type list need an array of values";
                            }
                        }
                        elsif ($type eq 'number' || $type eq 'alpha') {
                            for my $int ('min', 'max') {
                                if (! $options->{variables}{$key}{$int} ||
                                    $options->{variables}{$key}{$int} !~ /^\-*\d+$/g) {
                                        push @$reasons, "$int value must be an integer for $key";
                                }
                                else {
                                    $options->{variables}{$key}{$int} += 0;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    if ($reasons->[0]) {
        my $reason = join(', ', @$reasons);
        return (0, { error => 'Invalid parameters', reason => $reason });
    }
    else {
        return (1, {});
    }
}

sub _is_integer {
    my $val = shift;
    if ($val && $val =~ /^\d+$/g) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _is_foo {
    my ($val, $type) = @_;
    if ( ref($val) =~ $type) {
        return 1;
    }
    else {
        return 0;
    }
}
sub _is_array {
    return _is_foo($_[0], 'ARRAY');
}

sub _is_hash {
    return _is_foo($_[0], 'HASH');
}

sub _is_url {
    my $url = shift;
    return $url =~ /$RE{URI}{HTTP}{ -scheme => 'https?' }/g;
}

return 1;
