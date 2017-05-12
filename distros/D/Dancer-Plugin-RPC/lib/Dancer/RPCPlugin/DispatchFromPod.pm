package Dancer::RPCPlugin::DispatchFromPod;
use warnings;
use strict;
use Exporter 'import';
our @EXPORT = qw/dispatch_table_from_pod/;

use Dancer qw/error warning info debug/;

use Dancer::RPCPlugin::DispatchItem;
use Params::Validate ':all';
use Pod::Simple::PullParser;

sub dispatch_table_from_pod {
    my $args = validate(
        @_,
        {
            label    => { regex => qr/^(xmlrpc|jsonrpc|restrpc)$/ },
            packages => { type  => ARRAYREF },
        }
    );

    my $pp = Pod::Simple::PullParser->new();
    $pp->accept_targets($args->{label});
    debug("[dispatch_table_from_pod] for $args->{label}");

    my %dispatch;
    for my $package (@{ $args->{packages} }) {
        eval "require $package;";
        if (my $error = $@) {
            error("Cannot load '$package': $error");
            die "Stopped";
        }
        my $pkg_dispatch = _parse_file(
            package => $package,
            parser  => $pp,
        );
        @dispatch{keys %$pkg_dispatch} = @{$pkg_dispatch}{keys %$pkg_dispatch};
    }

    debug("[dispatch_table_from_pod]->", Data::Dumper::Dumper(\%dispatch));
    return \%dispatch;
}

sub _parse_file {
    my $args = validate(
        @_,
        {
            package => { regex => qr/^\w[\w:]*$/ },
            parser  => { type  => OBJECT },
        }
    );
    (my $pkg_as_file = "$args->{package}.pm") =~ s{::}{/}g;
    my $pkg_file = $INC{$pkg_as_file};
    use autodie;
    open my $fh, '<', $pkg_file;

    my $p = $args->{parser};
    $p->set_source($fh);

    my $dispatch;
    while (my $token = $p->get_token) {
        next if not ($token->is_start && $token->is_tag('for'));

        my $label = $token->attr('target');

        my $ntoken = $p->get_token;
        while ($ntoken && ! $ntoken->can('text')) { $ntoken = $p->get_token; }
        last if !$ntoken;

        debug("=for-token $label => ", $ntoken->text);
        my ($if_name, $code_name) = split " ", $ntoken->text;
        debug("[build_dispatcher] $args->{package}\::$code_name => $if_name");

        my $pkg = $args->{package};
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
        return dispatch_table_from_pod(%arguments);
    }

=head1 DESCRIPTION

=head2 dispatch_table_from_pod(%arguments)

=head3 Arguments

Named:

=over

=item package => $package_name

=item parser => $pod_simple_pullparser

=back

=head3 Returns

=head1 COPYRIGHT

(c) MMXV - Abe Timmerman <abeltje@cpan.org>

=cut
