package testlib::CrazyStatus;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(crazy_statuses);

sub crazy_statuses {
    return (
        {
            "id" => "crazy: string 'busybird'",
            "busybird" => "hoge"
        },
        {
            id => "crazy: array 'busybird'",
            busybird => []
        },
        {
            id => "crazy: string 'entities'",
            entities => "hoge"
        },
        {
            id => "crazy: array 'entities'",
            entities => []
        },
        {
            id => "crazy: string 'entities.urls'",
            entities => { urls => "" },
        },
        {
            id => "crazy: hash 'entities.urls'",
            entities => { urls => {} }
        },
        {
            id => "crazy: string urls Entity",
            entities => {
                urls => [
                    "hoge"
                ]
            }
        },
        {
            id => "crazy: array urls Entitiy",
            entities => {
                urls => [
                    []
                ]
            }
        },
        {
            id => "crazy: string Entity 'indices'",
            entities => {
                urls => [
                    { indices => "hoge" }
                ]
            }
        },
        {
            id => "crazy: hash Entity 'indices'",
            entities => {
                urls => [
                    { indices => {} }
                ]
            }
        },
        {
            id => "crazy: string 'user'",
            user => "hoge",
        },
        {
            id => "crazy: array 'user'",
            user => []
        },
        {
            id => "crazy: string 'busybird' with 'retweeted_status'",
            busybird => "hoge",
            retweeted_status => {}
        },
        {
            id => "crazy: string 'retweeted_status'",
            retweeted_status => "foobar"
        },
    );
}

1;
