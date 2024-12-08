[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Pairwise

[% FOREACH item IN opt.data -%]
[% IF loop.first -%]
# Target [% item.name %]

[% ELSE -%]
[% t = opt.data.0.name -%]
[% q = item.name -%]
if [ -e Pairwise/[% t %]vs[% q %] ]; then
    log_info Skip Pairwise/[% t %]vs[% q %]
else
    log_info lastz Pairwise/[% t %]vs[% q %]
    egaz lastz \
        --set set01 -C 0 [% IF opt.partition %]--tp --qp [% END %]\
        --parallel [% opt.parallel %] --verbose \
        [% opt.data.0.dir %] [% item.dir %] \
        -o Pairwise/[% t %]vs[% q %]

    log_info lpcnam Pairwise/[% t %]vs[% q %]
    egaz lpcnam \
        --syn --parallel [% opt.parallel %] --verbose \
        [% opt.data.0.dir %] [% item.dir %] Pairwise/[% t %]vs[% q %]
fi

[% END -%]
[% END -%]

exit;
