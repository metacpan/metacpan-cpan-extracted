# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;

BEGIN{
    package Derived;
    use Moose;
    extends 'Carp::Proxy';

    sub hook {}

    #-----
    # Here we come up with different values for most attributes.  These
    # are applied via overridden _build_* methods.
    #-----
    our %changed_attributes =
        (
         as_yaml        => 1,
         banner_title   => 'Oops',
         begin_hook     => \&hook,
         body_indent    => 4,
         columns        => 76,
         context        => 'croak',
         disposition    => 'warn',
         end_hook       => \&hook,
         exit_code      => 13,
         handler_pkgs   => ['Derived'],
         handler_prefix => '_hand_',
         header_indent  => 3,
         maintainer     => 'me@here',
         pod_filename   => 'fakename',
         section_title  => 'Header',
         sections       => [['fixed', 'sample', 'empty']],
         tags           => { key1 => 'val1', key2 => 'val2' },
        );

    sub _build_as_yaml        { $changed_attributes{ 'as_yaml'        }}
    sub _build_banner_title   { $changed_attributes{ 'banner_title'   }}
    sub _build_begin_hook     { $changed_attributes{ 'begin_hook'     }}
    sub _build_body_indent    { $changed_attributes{ 'body_indent'    }}
    sub _build_columns        { $changed_attributes{ 'columns'        }}
    sub _build_context        { $changed_attributes{ 'context'        }}
    sub _build_disposition    { $changed_attributes{ 'disposition'    }}
    sub _build_end_hook       { $changed_attributes{ 'end_hook'       }}
    sub _build_exit_code      { $changed_attributes{ 'exit_code'      }}
    sub _build_handler_pkgs   { $changed_attributes{ 'handler_pkgs'   }}
    sub _build_handler_prefix { $changed_attributes{ 'handler_prefix' }}
    sub _build_header_indent  { $changed_attributes{ 'header_indent'  }}
    sub _build_maintainer     { $changed_attributes{ 'maintainer'     }}
    sub _build_pod_filename   { $changed_attributes{ 'pod_filename'   }}
    sub _build_section_title  { $changed_attributes{ 'section_title'  }}
    sub _build_sections       { $changed_attributes{ 'sections'       }}
    sub _build_tags           { $changed_attributes{ 'tags'           }}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

package main;

use Carp::Proxy;
BEGIN{
    Derived->import( fatal1 => {} );
}

main();
done_testing();

#----------------------------------------------------------------------

sub main {

    test_base();
    test_derived();
    return;
}

sub handler {
    my( $cp, $tag_value_pairs ) = @_;

    keys %{ $tag_value_pairs };
    while(my($tag, $value) = each %{ $tag_value_pairs }) {

        my $observed = $cp->$tag;
        is_deeply $observed, $value, "in-handler comparison of $tag";
    }

    $cp->disposition( 'return' );
    return;
}

sub _hand_handler { handler( @_ ) }

sub test_base {

    my %tvp =
        (
         #-----
         # Based on building a default proxy from this test file we should
         # end up with the following parameters.
         #-----
         fq_proxy_name  => 'main::fatal',
         handler_name   => 'handler',
         handler_pkgs   => [qw( main )],
         pod_filename   => __FILE__,
         proxy_filename => __FILE__,
         proxy_name     => 'fatal',
         proxy_package  => 'main',

         as_yaml        => 0,
         banner_title   => 'Fatal',
         begin_hook     => undef,
         body_indent    => 2,
         columns        => 78,
         context        => 'confess',
         disposition    => 'die',
         end_hook       => undef,
         exit_code      => 1,
         handler_prefix => undef,
         header_indent  => 2,
         maintainer     => '',
         section_title  => 'Description',
         sections       => [],
         tags           => {},
        );

    $EVAL_ERROR  = $tvp{eval_error}    = 'made up syntax error';
    $CHILD_ERROR = $tvp{child_error}   = 258;
    $ERRNO       = $tvp{numeric_errno} = 14;
    $ARG         = $tvp{arg}           = 'some string';

    fatal 'handler', \%tvp;

    return;
}

sub test_derived {

    my %tvp =
        (
         fq_proxy_name  => 'main::fatal1',
         handler_name   => 'handler',
         proxy_filename => __FILE__,
         proxy_name     => 'fatal1',
         proxy_package  => 'main',
        );

    foreach my $attr (qw{
                            as_yaml
                            banner_title
                            begin_hook
                            body_indent
                            columns
                            context
                            disposition
                            end_hook
                            exit_code
                            handler_prefix
                            header_indent
                            maintainer
                            pod_filename
                            section_title
                            sections
                            tags
                    }) {

        $tvp{ $attr } = $Derived::changed_attributes{ $attr };
    }

    $EVAL_ERROR  = $tvp{eval_error}    = 'made up error';
    $CHILD_ERROR = $tvp{child_error}   = 259;
    $ERRNO       = $tvp{numeric_errno} = 19;
    $ARG         = $tvp{arg}           = 'another string';

    fatal1 'handler', \%tvp;

    return;
}

