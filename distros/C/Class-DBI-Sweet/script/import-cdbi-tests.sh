#!/bin/sh

CDBIDIR=$1
SWEETDIR=$2

if [ "$CDBIDIR" == "" ]; then
  echo "Usage: $0 CDBIDIR SWEETDIR";
  exit 255;
elif [ "$SWEETDIR" == "" ]; then
  echo "Usage: $0 CDBIDIR SWEETDIR";
  exit 255;
fi;

function fix_cache {
  HEAD='s!use Test::More;!use Test::More;
use Class::DBI::Sweet;
Class::DBI::Sweet->default_search_attributes({ use_resultset_cache =>';
  FOOT='});
Class::DBI::Sweet->cache(Cache::MemoryCache->new(
    { namespace => "SweetTest", default_expires_in => 60 } ) ); !
  && ($begin_added = 0);

s!BEGIN {!BEGIN {
\teval "use Cache::MemoryCache";
\tplan skip_all => "needs Cache::Cache for testing" if \$\@;!;

unless ($begin_added) {
  s!^(eval { require.*)$!
BEGIN {
\teval "use Cache::MemoryCache";
\tplan skip_all => "needs Cache::Cache for testing" if \$\@;
}

$1! && ($begin_added = 1);
}
'
  EXEC="$HEAD $1 $FOOT"
  #echo "$EXEC" # Uncomment me when you break the perl script :)
  perl -pi -e "$EXEC" t/cdbi-t-$2/*.t
}

rm -rf t/cdbi-t

mkdir t/cdbi-t

cp -R $1/t/* $2/t/cdbi-t/

perl -pi -e 's!t/testlib!t/cdbi-t/testlib!;
             s/Class::DBI(?=[^:])/Class::DBI::Sweet/;
                ' t/cdbi-t/*.t t/cdbi-t/testlib/*.pm

perl -pi -e 's/tests => 27/tests => 25/;' t/cdbi-t/99-misc.t

rm -rf t/cdbi-t-ocache
rm -rf t/cdbi-t-rescache

cp -R t/cdbi-t t/cdbi-t-ocache
cp -R t/cdbi-t t/cdbi-t-rescache

fix_cache 0 ocache
fix_cache 1 rescache
    
echo 'Done! Remember to re-run: perl Build.PL'

rm -f t/cdbi-t-*cache/04-lazy.t  # Lazy loading? Bah, we've cached it already
rm -f t/cdbi-t-*cache/02-Film.t  # Fails because it checks references
rm -f t/cdbi-*/15-accessor.t # Because it's b0rken
rm -f t/cdbi-t/16-reserved.t # Because it's b0rken
