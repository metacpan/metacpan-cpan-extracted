package Couchbase;
use strict;
use warnings;

use Couchbase::Core;

our @ERRMAP = ();
our $VERSION = $Couchbase::Core::VERSION;

package Couchbase::Cluster;
use strict;
use warnings;
use URI;
use Couchbase::Bucket;

sub q2hash($) {
    my $s = shift || '';
    my %rv = ();
    foreach my $pair (split('&', $s)) {
        my ($k,$v) = split('=', $pair);
        $rv{$k} = $v;
    }
    return \%rv;
}

sub parse_connstr($) {
    # Parses a connection string into its constituent parts
    my $uri = URI->new(shift);
    my %h = ();

    $h{scheme} = $uri->scheme;
    $h{hosts} = [ split(/,/, $uri->authority) ];
    $h{options} = q2hash($uri->query);
    $h{bucket} = $uri->path;
    $h{bucket} =~ s,^/+,,g;
    return \%h;
}

sub new {
    my ($pkg,$connstr) = @_;
    bless my $self = {
        connstr => parse_connstr($connstr),
        buckets => {}
    }, $pkg;
}

sub open_bucket {
    require Couchbase::Bucket;

    my ($self, $bucket_spec, $options) = @_;
    # Inject the URI into the connection string, merging them
    $bucket_spec = sprintf("%s://XXX/%s", $self->{connstr}->{scheme}, $bucket_spec);
    my $b_cstr = parse_connstr($bucket_spec);

    # Build the URI
    my $s = sprintf("%s://%s/%s?",
                    $self->{connstr}->{scheme},
                    join(',', @{ $self->{connstr}->{hosts} }),
                    $b_cstr->{bucket});


    # Now, merge the options:
    my %h = ( %{$self->{connstr}->{options} } );
    # Allow any overrides:
    %h = (%h, % { $b_cstr->{options} });
    my @tmp;
    while (my ($k,$v) = each %h) {
        push @tmp, "$k=$v";
    }
    $s .= join('&', @tmp);
    if ($self->{buckets}->{$s}) {
        return $self->{buckets}->{$s};
    } else {
        return $self->{buckets}->{$s} = Couchbase::Bucket->new($s, $options);
    }
}

1;

__END__

=head1 NAME

Couchbase - Couchbase Client Library


=head2 DESCRIPTION

B<You probably want to see L<Couchbase::Bucket> for the actual documentation>.

This document contains general information about the module and installation
instructions


=head3 INSTALLING

This module depends on the Couchbase C library
(L<libcouchbase|http://docs.couchbase.com/developer/c-2.4/download-install.html>);
please ensure this module is installed before attempting to install this
module.

If you can't use C extensions, Couchbase has a pure memcached emulation
layer called C<moxi> - which can then be used with any traditional Memcached
client (and in fact, this is what I used before writing this module).


=head3 EXAMPLES

Examples may be found in the C<eg> directory of the module. Other examples
can be found in the tests, which are actually in C<lib/Couchbase/Test>.


=head3 RELATION TO L<Couchbase::Client>

This module B<replaces> the older L<Couchbase::Client> module. Development
on the latter has ceased, ans it is no longer maintained. It is maintained
on CPAN purely so existing code using the module continues to function.

This module represents a complete rewrite of the older module


=head3 SUPPORT

While sponsored by Couchbase, this module is not officially supported by
Couchbase, Inc. Issues and problems may be reported in the following
venues.


=over

=item *

L<Github project page|https://github.com/mnunberg/perl-Couchbase-Client>

=item *

Couchbase mailing list (C<couchbase at googlegroups dot com>)

=item *

C<#libcouchbase> IRC channel on freenode

=item *

Perl's RT bug tracker (see the link on the cpan page).

=back
