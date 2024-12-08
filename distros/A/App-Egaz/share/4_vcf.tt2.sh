[% INCLUDE header.tt2 %]

#----------------------------#
# [% sh %]
#----------------------------#
log_warn [% sh %]

if [ -e [% opt.multiname %]_vcf/[% opt.multiname %].vcf ]; then
    log_info [% opt.multiname %]_vcf/[% opt.multiname %].vcf exists
    exit;
fi

mkdir -p [% opt.multiname %]_vcf

log_info Write name.list

# Make sure all queries present
# Don't write outgroup
rm -f [% opt.multiname %]_vcf/name.list
[% FOREACH item IN opt.data -%]
[% IF not loop.last -%]
echo [% item.name %] >> [% opt.multiname %]_vcf/name.list
[% ELSE -%]
[% IF not opt.outgroup -%]
echo [% item.name %] >> [% opt.multiname %]_vcf/name.list
[% END -%]
[% END -%]
[% END -%]

log_info fas2vcf
find [% opt.multiname %]_refined -type f -name "*.fas" -or -type f -name "*.fas.gz" |
    sort |
    parallel --no-run-if-empty -j [% opt.parallel %] '
        egaz fas2vcf \
            {} \
            [% args.0 %]/chr.sizes \
            --verbose --list [% opt.multiname %]_vcf/name.list \
            -o [% opt.multiname %]_vcf/{/}.vcf
    '

log_info concat and sort vcf
bcftools concat [% opt.multiname %]_vcf/*.vcf |
    bcftools sort \
    > [% opt.multiname %]_vcf/[% opt.multiname %].vcf

find [% opt.multiname %]_vcf -type f -name "*.vcf" -not -name "multi4.vcf" |
    parallel --no-run-if-empty -j 1 rm

exit;
