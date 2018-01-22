#!/usr/bin/env perl

use Data::Dump::Color;

dd {
    extended => [
        {
            ip => "65.182.224.220",
            ip_family => "ipv4",
            mac => "00:00:00:00:00:00",
            type => "static",
        }, # .[0]
        {
            ip => "65.182.224.218",
            ip_family => "ipv4",
            mac => "B8:27:EB:D5:98:37",
            type => "dhcp",
        },
    ], # in this case, this line is not aligned with the matching "[" by DD
    int => "N91-1-1-1",
};
