package Apache2::Controller::Dispatch::HashTree;

=head1 NAME

Apache2::Controller::Dispatch::HashTree - 
Hash tree dispatch for L<Apache2::Controller::Dispatch>

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 SYNOPSIS

 <Location "/subdir">
     SetHandler modperl
     PerlInitHandler MyApp::Dispatch
 </Location>

 # lib/MyApp::Dispatch:

 package MyApp::Dispatch;
 use base qw(
     Apache2::Controller::Dispatch::HashTree
 );

 # return a hash reference from dispach_map()
 sub dispatch_map { return {
    foo => {
        default     => 'MyApp::C::Foo',
        bar => {
            biz         => 'MyApp::C::Biz',
            baz         => 'MyApp::C::Baz',
        },
    },
    default => 'MyApp::C::Default',
 } }

 1;
 __END__

This maps uri's to controller modules as follows:

 /subdir/foo                    MyApp::C::Foo->default()

 /subdir/foo/bar                MyApp::C::Foo->bar()

 /subdir/foo/bar/zerm           MyApp::C::Foo->bar(), path_args == ['zerm']

 /subdir/foo/bar/biz            MyApp::C::Biz->default()

 /subdir/foo/biz/baz/noz/wiz    MyApp::C::Baz->noz(), path_args == ['wiz']

In the second example, if C<<MyApp::C::Foo>> did not implement or allow
C<<bar()>> as a controller method, then this would select
C<<MyApp::C::Foo->default()>>.

=head1 DESCRIPTION

Implements find_controller() for Apache2::Controller::Dispatch with
a simple hash-based mapping.  Uses substr to divide the uri and
exists to check cached mappings, so it should be pretty fast.

This dispatches URI's in a case-insensitive fashion.  

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';
use Carp qw( confess );

use base qw( Apache2::Controller::Dispatch );

use Apache2::Controller::X;
use Apache2::Controller::Funk qw( controller_allows_method check_allowed_method );

use Log::Log4perl qw(:easy);
use YAML::Syck;

=head2 find_controller

Find the controller and method for a given URI from the data
set in the dispatch class module.

=cut

sub find_controller {
    my ($self) = @_;
    my $dispatch_map = $self->get_dispatch_map();
    my $r = $self->{r};
    my $location = $r->location();
    my $uri = $r->uri();
    my $uri_below_loc = substr $uri, length $location;

    DEBUG(sub{Dump({
        uri             => $uri,
        uri_below_loc   => $uri_below_loc,
        location        => $location,
    })});

    # efficiently split up the uri into an array of path parts
    my @path;
    my $j = 0;
    my $uri_len = length $uri_below_loc;
    my $last_char_idx = $uri_len - 1;
    my $prev_char = q{};
    my $uri_without_leading_slash = '';
    CHAR:
    for (my $i = 0; $i <= $last_char_idx; $i++) {
        my $char = substr $uri_below_loc, $i, 1;
        DEBUG(sub { "j=$j; char $i = '$char' (".ord($char).")" });
        if ($char eq '/') {
            # skip over first /
            if ($i == 0) {
                $prev_char = $char;
                next CHAR;
            }

            # skip over repeat //'s
            next CHAR if $char eq $prev_char;

            # skip a trailing /
            last CHAR if $i == $last_char_idx;

            # not skipped, so iterate the path counter
            $j++;
        }
        else {
            $path[$j] .= $char;
            DEBUG("added $char to path[$j] ($path[$j])");
        }
        $prev_char = $char;
        $uri_without_leading_slash .= $char;
    }
    $uri_below_loc = $uri_without_leading_slash;
    DEBUG("uri_below_loc is now $uri_below_loc");

    # follow these keys through the hash and push remaining path parts
    # to an array for after we're done searching for the method
    my $node = $dispatch_map;

    DEBUG(sub{"path: (@path)"});

    my @trace_path;
    @trace_path = map { 
        ref $node   # wow, i didn't know you could do this...
            ? do { $node = $node->{$_}; $node }
            : undef
    } @path;
    DEBUG(sub{"dispatch hash trace_path:\n".Dump(\@trace_path)});
    
    my %results = ();
    my @path_args;

    FIND_NODE:
    for (my $i = $#trace_path; $i >= 0; $i--) {

        next FIND_NODE if !exists $trace_path[$i];

        my $node = $trace_path[$i];

        my $part = $path[$i];

        DEBUG(sub { "part = '$part', i = $i, path=(@path), node = ".Dump($node) });

        my $ref  = ref $node;

        my $maybe_method = $path[$i + 1];
        my $maybe_controller = $ref ? $node->{default} : $node;

        next FIND_NODE if !$maybe_controller;  # no default specified, no matches

        DEBUG(sub {
            "ctrl? => '$maybe_controller', method? => ".($maybe_method || '[none]')
        });

        if  (   $maybe_method
            &&  controller_allows_method($maybe_controller => $maybe_method)
            ) {
            # got it!
            $results{controller}    = $maybe_controller;
            $results{method}        = $maybe_method;
            $results{relative_uri}  = join('/', @path[ 0 .. $i ]);
            @path_args              = @path[ $i + 2 .. $#path ];
            last FIND_NODE;
        }
        else {  # maybe 'default' here?
            if (controller_allows_method($maybe_controller => 'default')) {
                $results{controller}    = $maybe_controller;
                $results{method}        = 'default';
                $results{relative_uri}  = join('/', @path[ 0 .. $i ]);
                @path_args              = @path[ $i + 1 .. $#path ];
                last FIND_NODE;
            }
            else {
                # not here... go back one
                next FIND_NODE;
            }
        }
    }

    # if still no controller, select the default
    if (!$results{controller}) {
        my $ctrl = $dispatch_map->{default};

        a2cx "$uri no default controller" if !$ctrl;

        a2cx "$uri no references allowed in dispatch_map for default"
            if ref $ctrl;

        $results{controller} = $ctrl;

        # and find a method.
        my $maybe_method = $path[0];
        if  (   $maybe_method 
            &&  controller_allows_method($results{controller}, $maybe_method)
            ) {
            $results{method} = $maybe_method;
            @path_args = @path[ 1 .. $#path ] if exists $path[1];
        }
        elsif (controller_allows_method($results{controller}, 'default')) {
            $results{method} = 'default';
            @path_args = @path[ 0 .. $#path ] if exists $path[0];
        }
        else {
            a2cx "$uri cannot find a working method in $results{controller}";
        }

        # relative uri is ''
        $results{relative_uri} = '';
    }

    DEBUG(sub{Dump({
        path_args => \@path_args,
        results => \%results,
    })});

    # make sure this worked
    a2cx "did not detect $_"
        for grep !exists $results{$_}, 
        qw( controller method relative_uri );

    # save the info in pnotes
    my $pnotes = $r->pnotes;
    $pnotes->{a2c}{$_} = $results{$_} for keys %results;
    $pnotes->{a2c}{path_args} = \@path_args;

    # now try finding a matching module in dispatch_map

    #######################################################
    return $results{controller};
}

=head1 SEE ALSO

L<Apache2::Controller::Dispatch>

L<Apache2::Controller::Dispatch::Simple>

L<Apache2::Controller>

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)| formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.

=cut


1;
