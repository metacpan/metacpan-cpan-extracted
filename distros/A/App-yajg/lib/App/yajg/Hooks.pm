package App::yajg::Hooks;

# Various hooks to modify data that is not array or hash ref
# The refs to subs from this package are used at App::yajg::modify_data

use 5.014000;
use strict;
use warnings;
use utf8;

use JSON qw();

sub boolean_to_scalar_ref {
    return unless JSON::is_bool($_[0]);
    $_[0] = $_[0]
      ? \(my $t = 1)
      : \(my $f = 0);
}

sub boolean_to_int {
    return unless JSON::is_bool($_[0]);
    $_[0] = int(!!$_[0]);
}

sub boolean_to_str {
    return unless JSON::is_bool($_[0]);
    $_[0] = $_[0]
      ? 'true'
      : 'false';
}

sub _decode_uri ($) {
    local $_ = shift // return undef;
    tr/\+/ /;
    s/\%([a-f\d]{2})/pack("C",hex($1))/ieg;
    utf8::decode($_) unless utf8::is_utf8($_);
    return $_;
}

# Do not use URI for increase speed
sub uri_parse {
    return unless defined $_[0] and not ref $_[0];
    my %uri;
    # From URI::Split::uri_split
    @uri{qw/scheme host path query fragment/} =
      $_[0] =~ m,(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?,;
    return unless defined $uri{'host'};
    $uri{'uri'}   = $_[0];
    $uri{'path'} = [
        map { _decode_uri($_) } split '/' => $uri{'path'} =~ s,^/,,r
    ];
    # From URI::_query::query_form
    $uri{'query'} = {
        map { _decode_uri($_) }
          map { /=/ ? split(/=/, $_, 2) : ($_ => undef) }
          split /[&;]/ => ($uri{'query'} // '')
    };
    $uri{'fragment'} = _decode_uri($uri{'fragment'});
    $_[0] = \%uri;
}

sub make_code_hook ($) {
    my $code = shift;
    utf8::decode($code) unless utf8::is_utf8($code);
    return sub {
        local $_ = $_[0];
        { no strict; no warnings; eval $code; }
        warn "$@\n" if $@;
        $_[0] = $_;
    };
}

1;
