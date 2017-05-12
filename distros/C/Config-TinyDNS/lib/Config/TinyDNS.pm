package Config::TinyDNS;

=head1 NAME

Config::TinyDNS - Manipulate tinydns' data file

=head1 SYNOPSIS

    use Config::TinyDNS qw/filter_tdns_data/;

    my $data = File::Slurp::read_file(...);
    $data = filter_tdns_data $data, qw/include vars lresolv/;

=head1 DESCRIPTION

Tinydns, the DNS server in Dan Bernstein's djbdns package, uses a simple
line-based format instead of a zone file. The format was designed to be
easy for machines to parse, so it sometimes requires rather a lot of
repetition. This module provides functions for manipulating these files,
however it is primarily intended as the backend for
L<tinydns-filter(1)>.

The general principle of operation is that the file is split into
records and fields, these records are passed through a series of
filters, and the results joined back up into a config file. The basic
file format is line-based, with each line consisting of a
single-character operator followed by a number of colon-separated
arguments. For more details on the format, see L<tinydns-data(8)>.

=head1 FUNCTIONS

=cut

use 5.010;
use warnings;
use strict;
use Scalar::Util    qw/reftype/;
use List::MoreUtils qw/natatime/;
use Carp;

use Exporter::NoWork;

our $VERSION = 1;

my %Filters;

=head2 C<split_tdns_data I<STRING>>

Breaks the provided string up into a list of arrayrefs. Each arrayref
represents a line of the input; each line is broken into the initial
single-character operator and the subsequent colon-separated fields.
Trailing blank fields are removed. Blank lines are removed. Comments are
not broken up into fields.

For example, an input of

    +foo.com:1.2.3.4:
    Idynamic/bar.org
    # some:comment

would produce a data structure like

    ["+", "foo.com", "1.2.3.4"],
    ["I", "dynamic/bar.org"],
    ["#", " some:comment"],

=cut

sub split_tdns_data {
    map { 
        s/(.)// 
            ? [$1, ($1 eq "#" ? $_ : split /:/)] 
            : () 
    } split /\n/, $_[0];
}

sub _strip_blank { 
    @_ = @{[@_]}; 
    pop while @_ and not (defined $_[-1] and length $_[-1]); 
    @_;
}

=head2 C<join_tdns_data I<LIST>>

Join the result of C<L</split_tdns_data>> back up into a single string.
Undef fields are silently rendered as blanks. Trailing empty fields are
removed.

=cut

sub join_tdns_data {
    no warnings "uninitialized";
    join "", map "$_\n", map { 
        $_->[0] . join ":", _strip_blank @$_[1..$#$_] 
    } @_;
}

sub _lookup_filt {
    my ($k, @args) = @_;
    my $f = $Filters{$k} or croak "bad filter: $k";
    given (reftype $f) {
        when ("CODE")   { return $f }
        when ("REF")    { return ($$f)->(@args) }
        default         { die "bad \%Filters entry: $k => $f" }
    }
}
    
sub _decode_filt {
    my ($f) = @_;
    defined $f or return;
    given (reftype $f) {
        when ("CODE")   { return $f }
        when (undef)    { return _lookup_filt $f }
        when ("ARRAY")  { return _lookup_filt @$f }
        default         { croak "bad filter: $f" }
    }
}

sub _call_filt {
    my $c = shift;
    my $r = @_ ? shift : $_;
    my ($f, @r) = @$r;
    local $_ = $f;
    $c->(@r);
}

=head2 C<filter_tdns_data I<STRING>, I<FILTERS>>

Break I<STRING> up using C<L</split_tdns_data>>, pass it through a
series of filters, and join it up again with C<L</join_tdns_data>>.
I<FILTERS> should be a list of the following:

=over 4

=item * a CODE ref

The coderef will be called once for each line of input. C$_> will be set
to the initial single character and the arguments in C<@_> will be the
remaining fields. The return value should be a list of arrayrefs as from
C<L</split_tdns_data>>. A simple filter that changes nothing looks like

    sub { return [$_, @_] }

=item * a plain string

This requests a filter registered with C<L</register_tdns_filter>>. See
L</FILTERS> below for a list of the predefined filters.

=item * an ARRAY ref

The first argument will be looked up as a registered filter. If this is
a generator-type filter (see below), the generator will be called with
the rest of the contents of the arrayref as arguments.

=back

=cut

sub filter_tdns_data {
    my @lines = split_tdns_data shift;
    for my $f (@_) {
        my $c = _decode_filt $f;
        @lines = 
            map _call_filt($c),
            @lines;
    }
    return join_tdns_data @lines;
}

=head2 C<register_tdns_filters I<LIST>>

Register filters to be called by name later. I<LIST> should be a list of
key C<< => >> value pairs, where each value is either

=over 4

=item * a CODE ref

The coderef will be called as though it had been supplied to
C<filter_tdns_data> directly. Any arguments passed (using an arrayref)
will be ignored.

=item * a ref to a CODE ref

For example

    record => \sub {
        my %vars;
        sub {
            /\$/ or return [$_, @_];
            $vars{$_[0]} = $_[1];
        };
    },

The coderef will be called once when C<filter_tdns_data> is called, and
the return value will be used as the filter sub. Any arguments supplied
will be passed to the generator sub.

=back

=cut

sub register_tdns_filters {
    my $i = natatime 2, @_;
    while (my ($k, $c) = $i->()) {
        $Filters{$k}    and croak "filter '$k' is already registered";
        ref $c and (
            reftype $c eq "CODE" or (
                reftype $c eq "REF" and reftype $$c eq "CODE"
            )
        )               or  croak "filter must be a coderef(ref)";
        $Filters{$k} = $c;
    }
}

# just for the tests
sub _filter_hash { \%Filters }

=head1 FILTERS

Many of these filters introduce ordering constraints on the lines of the
file. Be careful about re-ordering files written for them.

=head2 null

Pass all lines through unchanged. Note that blank lines and trailing
blank fields will still be removed.

=cut

register_tdns_filters 
    null => sub { [$_, @_] };

=head2 vars

Input lines of the form

    $name:value

are treated as variable definitions and removed from the output.
Variables may have any name, but only those matching C<\w+> are useful.
Expressions looking like C</\$\w+/> will be substituted across all
fields, including in variable definitions. This allows a form of symref,
use of which should be discouraged. Variables must be defined before
they are used; nonexistent variables will be silently replaced with the
empty string. Dollars can be escaped by doubling them.

    $foo:foo.com
    =$foo:1.2.3.4
    +www.$foo:1.2.3.4
    "txt.$foo:this $$ is a dollar

translates to

    =foo.com:1.2.3.4
    +www.foo.com:1.2.3.4
    "txt.foo.com:this $ is a dollar

=cut

register_tdns_filters 
    vars => \sub {
        my %vars = ('$' => '$');
        sub {
            no warnings "uninitialized";
            s/\$(\$|\w+)/$vars{$1}/ge for @_;
            /\$/            or return [$_, @_];
            $_[0] eq '$'    and return;
            $vars{$_[0]} = $_[1]; 
            return;
        }
    };

=head2 include

This interprets lines of the form

    Isome/file

as a request to include the contents of F<some/file> at this point. The
included lines are scanned for further includes but are not passed
through any other filters (though this may change at some point).

=cut

register_tdns_filters
    include => \sub {
        my $include;
        $include = sub {
            /I/ or return [$_, @_];
            require File::Slurp;
            return map _call_filt($include),
                split_tdns_data scalar File::Slurp::read_file($_[0]);
        };
    };

=head2 lresolv

Resolve hostnames in IP-address slots in the configuration using the
information in this file. Names must be defined before they will be
translated. Currently only the C<+ = . & @> lines used by
tinydns-data(1) are recognised. If you want to run both lresolv and
L</rresolv>, you need to run lresolv first or local hostnames will
already have been replaced.

For example

    =foo.com:1.2.3.4
    +www.foo.com:foo.com

would translate to

    =foo.com:1.2.3.4
    +www.foo.com:1.2.3.4

=cut

register_tdns_filters
    lresolv => \sub {
        no warnings "uninitialized";
        my %hosts;
        my $repl = sub {
            for ((defined $_[1] ? "$_[0]:$_[1]" : ()), $_[0]) {
                if (
                    $_[0] =~ /[^0-9.]/ and 
                    defined $hosts{$_}
                ) {
                   $_[0] = $hosts{$_};
                   last;
                }
            }
        };
        my $qual = sub { $_[0] =~ /\./ ? $_[0] : "$_[0].$_[1].$_[2]" };
        my $lo   = sub { $_[0] . (defined $_[1] ? ":$_[1]" : "") };
        sub { 
            given ($_) {
                when ([".", "&"]) { 
                    $repl->(@_[1, 5]);
                    my $key = $lo->($qual->($_[2], "ns", $_[0]), $_[5]);
                    $hosts{$key} = $_[1];
                }
                when (["=", "+"]) {
                    $repl->(@_[1, 4]);
                    $hosts{$lo->($_[0], $_[4])} = $_[1];
                }
                when (["@"]) {
                    $repl->(@_[1, 6]);
                    $hosts{$lo->($qual->($_[2], "mx", $_[0]), $_[6])} = $_[1];
                }
            }
            [$_, @_];
        };
    };

=head2 rresolv

Resolve hostnames in IP-address slots in the configuration by looking
them up in the current DNS. This assumes anything which doesn't match
C</[0-9.]*/> is a hostname, and any hostname that doesn't resolve is
replaced with C<0.0.0.0>. Currently this only recognises the standard
C<+=.&@> lines.

=cut

register_tdns_filters
    rresolv => \sub {
        require Socket;
        my $repl = sub { 
            if ($_[0] =~ /[^0-9.]/) {
                $_[0] = Socket::inet_ntoa(
                    gethostbyname($_[0]) // 
                        Socket::inet_aton("0.0.0.0")
                );
            }
        };
        sub { /[.&+=\@]/ and $repl->($_[1]); [$_, @_]; };
    };

=head2 site I<SITES>

This adds an extra field to C<%> lines, so they look like

    %lo:ipprefix:site

If I<site> is in the list of I<SITES> provided, the I<site> field will
be removed and the line left in the output. Otherwise, the line will be
removed entirely. This makes it possible to build data files for several
different views on the DNS from one master file.

=cut

register_tdns_filters
    site => \sub {
        my %sites = map +($_, 1), @_;
        sub {
            /%/             or return [$_, @_];
            @_ > 2          or return [$_, @_];
            my $site = pop;
            $sites{$site}   or return;
            return [$_, @_];
        };
    };

1;

=head1 SEE ALSO

L<tinydns-filter(1)>, L<tinydns-data(8)>.

=head1 AUTHOR

Ben Morrow <ben@morrow.me.uk>

=head1 COPYRIGHT

Copyright 2010 Ben Morrow.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item *

Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BEN MORROW BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
