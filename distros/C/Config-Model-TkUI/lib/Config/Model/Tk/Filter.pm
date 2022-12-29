#
# This file is part of Config-Model-TkUI
#
# This software is Copyright (c) 2008-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tk::Filter 1.376;

use 5.10.1;
use strict;
use warnings;
use Carp;
use Log::Log4perl 1.11;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/apply_filter/;

my $logger = Log::Log4perl::get_logger('Tk::Filter');

sub _get_filter_action {
    my ($elt, $elt_filter, $filtered_state, $unfiltered_state, $default_state) = @_;

    my $action = $default_state;
    if (length($elt_filter) > 2) {
        if ($elt =~ /$elt_filter/) {
            $action = $filtered_state ;
        }
        else {
            $action = $unfiltered_state;
        }
    }
    return $action;
}

# scan a tree and return a hash where each found path is the key and the
# value is either hide, show or an empty string.
sub apply_filter {
    my (%args) = @_;

    # fd_path: force display path. The show action must be set in the
    # call back so that the 'show' action can be propagated from the
    # shown leaf up to the root of the tree.

    my $show_only_custom = $args{show_only_custom} // 0;
    my $hide_empty_values = $args{hide_empty_values} // 0;
    my $instance = $args{instance} // carp "missing instance" ;
    my $actions = $args{actions} // carp "missing actions ref" ;
    my $fd_path = $args{fd_path} // '';

    # flush the hash, but keep the ref
    %$actions = ();

    # need 3 state logic. '' means that tree node is left as is,
    # either closed or opened, depending on user choice.

    # 'show' trumps '' which trumps 'hide'
    my %combine_as_is_over_hide = (
        show => { show => 'show', '' => 'show', hide => 'show'},
        ''   => { show => 'show', '' => ''    , hide => ''    },
        hide => { show => 'show', '' => ''    , hide => 'hide'},
    );

    # inner hide or show wins
    my %combine_for_node = (
        show => { show => 'show', hide => 'hide', '' => 'show'},
        ''   => { show => 'show', hide => 'hide', '' => ''    },
        hide => { show => 'show', hide => 'hide', '' => 'hide'},
    );

    my $leaf_cb = sub {
        my ($scanner, $data_ref, $node,$element_name,$index, $leaf_object) = @_ ;
        my $loc = $leaf_object->location;
        my $action = '';
        if ( $show_only_custom and not $leaf_object->has_data) {
            $action = 'hide';
        }
        if ( $hide_empty_values ) {
            my $v = $leaf_object->fetch(qw/check no/);
            $action = 'hide' unless (defined $v and length($v)) ;
        }
        $action = 'show' if $loc eq $fd_path;
        $logger->trace("'$loc' leaf filter is '$action'");
        $data_ref->{return} = $data_ref->{actions}{$loc} = $action ;
    };

    my $check_list_cb = sub {
        my ($scanner, $data_ref,$node,$element_name,undef, $obj) = @_;
        my $loc = $obj->location;
        my $action = '';
        if ( $hide_empty_values and not $obj->fetch(mode => 'user')) {
             $action = 'hide';
        }
        $action = 'show' if $loc eq $fd_path;
        $logger->trace("'$loc' check_list filter is '$action'");
        $data_ref->{return} = $data_ref->{actions}{$loc} = $action ;
    };

    my $hash_cb = sub {
        my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;
        my $obj = $node->fetch_element($element_name);
        my $loc = $obj->location;

        # resume exploration
        my $hash_action = $hide_empty_values || $show_only_custom ? 'hide' : '';
        foreach my $key (@keys) {
            my $inner_ref = { actions => $data_ref->{actions}, filter => $data_ref->{filter} };
            $scanner->scan_hash($inner_ref, $node, $element_name, $key);
            $hash_action = $combine_as_is_over_hide{$hash_action}{$inner_ref->{return}};
        }
        $hash_action = 'show' if $loc eq $fd_path;
        $logger->trace("'$loc' hash filter is '$hash_action'");
        $data_ref->{return} = $data_ref->{actions}{$loc} = $hash_action;
    };

    my $node_cb = sub {
        my ($scanner, $data_ref,$node, @element_list) = @_ ;
        my $node_loc = $node->location;
        my $elt_filter = $data_ref->{filter};

        my $node_action = $hide_empty_values || $show_only_custom ? 'hide' : '';
        foreach my $elt ( @element_list ) {
            my $filter_action = _get_filter_action($elt,$elt_filter,'show','hide','');
            my $obj = $node->fetch_element($elt);
            my $loc = $obj->location;
            # make sure that the hash ref stays attached to $data_ref
            $data_ref->{actions} //= {};
            my $inner_ref = {
                actions => $data_ref->{actions},
                # stop filter propagation when current element is
                # shown so all elements below can be shown or hidden
                # at user's choice
                filter => $filter_action eq 'show' ? '' : $data_ref->{filter}
            };
            $scanner->scan_element($inner_ref, $node,$elt);
            my $elt_action = $combine_for_node{$filter_action}{$inner_ref->{return}};
            $logger->trace("'$loc' node elt filter is '$elt_action'");
            $data_ref->{actions}{$loc} = $elt_action;
            $node_action = $combine_as_is_over_hide{$node_action}{$elt_action};
        }

        $node_action = 'show' if $node_loc eq $fd_path;

        $logger->trace("'$node_loc' node filter is '$node_action'");
        $data_ref->{return} = $data_ref->{actions}{$node_loc} = $node_action;
    };

    my $scan = Config::Model::ObjTreeScanner-> new (
        leaf_cb => $leaf_cb,
        hash_element_cb => $hash_cb,
        list_element_cb => $hash_cb,
        node_content_cb => $node_cb,
    ) ;

    my $data_ref = {
        filter => $args{elt_filter_value} // '',
        actions => $actions,
    };
    $scan->scan_node($data_ref, $instance->config_root) ;
}

1;

