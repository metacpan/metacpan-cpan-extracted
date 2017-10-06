package Dancer::RPCPlugin::DispatchFromPod;
use warnings;
use strict;
use Exporter 'import';
our @EXPORT = qw/dispatch_table_from_pod/;

use Dancer qw/error warning info debug/;

use Dancer::RPCPlugin::DispatchItem;
use Pod::Simple::PullParser;
use Types::Standard qw/ Str StrMatch ArrayRef Object /;
use Params::ValidationCompiler 'validation_for';

sub dispatch_table_from_pod {
    my %args = validation_for(
        params => {
            plugin   => { type => StrMatch[ qr/^(xmlrpc|jsonrpc|restrpc)$/ ] },
            packages => { type  => ArrayRef },
            endpoint => { type => Str },
        }
    )->(@_);

    my $pp = Pod::Simple::PullParser->new();
    $pp->accept_targets($args{plugin});
    debug("[dispatch_table_from_pod] for $args{plugin}");

    my %dispatch;
    for my $package (@{ $args{packages} }) {
        eval "require $package;";
        if (my $error = $@) {
            error("Cannot load '$package': $error");
            die "Stopped";
        }
        my $pkg_dispatch = _parse_file(
            package  => $package,
            endpoint => $args{endpoint},
            parser   => $pp,
        );
        @dispatch{keys %$pkg_dispatch} = @{$pkg_dispatch}{keys %$pkg_dispatch};
    }

    # we don't want "Encountered CODE ref, using dummy placeholder"
    # thus we use Data::Dumper::Dumper() directly.
    local ($Data::Dumper::Indent, $Data::Dumper::Sortkeys, $Data::Dumper::Terse) =  (0, 1, 1);
    debug("[dispatch_table_from_pod]->", Data::Dumper::Dumper(\%dispatch));
    return \%dispatch;
}

sub _parse_file {
    my %args = validation_for(
        params => {
            package  => { type => StrMatch[ qr/^\w[\w:]*$/ ] },
            parser   => { type  => Object },
            endpoint => { type => Str },
        }
    )->(@_);

    (my $pkg_as_file = "$args{package}.pm") =~ s{::}{/}g;
    my $pkg_file = $INC{$pkg_as_file};
    use autodie;
    open my $fh, '<', $pkg_file;

    my $p = $args{parser};
    $p->set_source($fh);

    my $dispatch;
    while (my $token = $p->get_token) {
        next if not ($token->is_start && $token->is_tag('for'));

        my $label = $token->attr('target');

        my $ntoken = $p->get_token;
        while ($ntoken && ! $ntoken->can('text')) { $ntoken = $p->get_token; }
        last if !$ntoken;

        debug("=for-token $label => ", $ntoken->text);
        my ($if_name, $code_name, $ep_name) = split " ", $ntoken->text;
        $ep_name //= $args{endpoint};
        debug("[build_dispatcher] $args{package}\::$code_name => $if_name ($ep_name)");
        next if $ep_name ne $args{endpoint};

        my $pkg = $args{package};
        if (my $handler = $pkg->can($code_name)) {
            $dispatch->{$if_name} = dispatch_item(
                package => $pkg,
                code    => $handler
            );
        } else {
            die "Handler not found for $if_name: $pkg\::$code_name doesn't seem to exist.\n";
        }
    }
    return $dispatch;
}

1;

=head1 NAME

Dancer::RPCPlugin::DispatchFromPod - Build dispatch-table from POD

=head1 SYNOPSIS

    use Dancer::Plugin;
    use Dancer::RPCPlugin::DispatchFromPod;
    sub dispatch_call {
        return dispatch_table_from_pod(%parameters);
    }

=head1 DESCRIPTION

Interface to build a (partial) dispatch table from the special pod-directives in the
packages specified and for the optional endpoint specified.

=head2 POD Specifications

One can specify a sub/method to be used for the RPCPlugin by using the
POD directive C<=for> followed by the rpc-protocol supported by this plugin-set.
One of B<jsonrpc>, B<restrpc> and B<xmlrpc>.

    =for <protocol> <rpc-name> <real-code-name>[ <endpoint>]

=over

=item B<< <protocol> >> must be one of <jsonrpc|restrpc|xmlrpc>

=item B<< <rpc-name> >> is the name used by the rpc-interface to execute this
call, different protocols may use diffent 'rpc-name's to reflect the nature of
the protocol.

=item B<< <real-code-name> >> is the name of the sub/method

=item B<< <endpoint> >> this optional argument is needed for files/packages that
have code for different endpoints.

=back

The pod-directive must be in the same file the code it refers to is.

Make sure the partial dispatch table for a single endpoint is build in a single pass.

=head1 EXPORTS

=head2 dispatch_table_from_pod(%arguments)

=head3 Parameters

Named:

=over

=item plugin => <jsonrpc|restrpc|xmlrpc>

=item packages => [ $package_name, ... ]

=item endpoint => '/endpoint_for_dispatch_tabledispatch_table'

=back

=head3 Responses

A (partial) dispatch-table.

=head1 COPYRIGHT

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

=cut
