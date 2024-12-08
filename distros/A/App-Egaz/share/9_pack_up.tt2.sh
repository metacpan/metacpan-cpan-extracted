[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

find . -type f |
    grep -v -E "\.(sh|2bit)$" |
    grep -v -E "(_fasta|_raw)\/" |
    grep -v -F "fake_tree.nwk" \
    > file_list.txt

tar -czvf [% opt.multiname %].tar.gz -T file_list.txt

log_info [% opt.multiname %].tar.gz generated

exit;
