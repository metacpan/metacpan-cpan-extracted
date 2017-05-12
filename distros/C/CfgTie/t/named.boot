;
; a caching only nameserver config
;
directory                              /var/named
cache           .                      named.ca
#primary         0.0.127.in-addr.arpa   named.local
#primary		113.98.209.in-addr.arpa	named.rev
#primary		xiotech.com		named.hosts
secondary	visi.com	209.98.98.98 209.98.98.98	named.net.bak
limit transfers-in	10
