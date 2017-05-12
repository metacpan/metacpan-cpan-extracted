base=${0%/*}/..
lib=${base}/lib
perl5lib=${base}/local/lib/perl5
app=${base}/cli.psgi

rm ${lib}/App/DB/Schema.pm
perl -I $perl5lib -I $lib $app cli load_schema > ${lib}/App/DB/Schema.pm.$$
mv ${lib}/App/DB/Schema.pm.$$ ${lib}/App/DB/Schema.pm
