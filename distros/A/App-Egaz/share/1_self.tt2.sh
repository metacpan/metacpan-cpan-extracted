[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

mkdir -p Pairwise

[% FOREACH item IN opt.data -%]
if [ -e Pairwise/[% item.name %]vsSelf ]; then
    log_info Skip Pairwise/[% item.name %]vsSelf
else
    log_info lastz Pairwise/[% item.name %]vsSelf
    egaz lastz \
        --isself --set set01 -C 0 [% IF opt.partition %]--tp --qp [% END %]\
        --parallel [% opt.parallel %] --verbose \
        [% item.dir %] [% item.dir %] \
        -o Pairwise/[% item.name %]vsSelf

    log_info lpcnam Pairwise/[% item.name %]vsSelf
    egaz lpcnam \
        --parallel [% opt.parallel %] --verbose \
        [% item.dir %] [% item.dir %] Pairwise/[% item.name %]vsSelf
fi

[% END -%]

exit;
