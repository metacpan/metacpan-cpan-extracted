# Sourced by run-suite and check-ways: load databases into the environment.
#
#   -d DB      eval "dbio-db env DB" (repeatable; DB as `dbio-db list` names it)
#   -n NAME    own database on the shared PostgreSQL: dbname=dbio_test -> dbname=NAME
#              in DBIO_TEST_PG_DSN and DBIO_TEST_PG_EXT_DSN (never work in dbio_test)
#
# Sets $dbio_args to the arguments left over. DBIO_DB_TOOL overrides the path
# of dbio-db.

dbio_db=${DBIO_DB_TOOL:-$HOME/dev/cihq-ocp/umgebungen/dbio/dbio-db}
dbio_pgname=
while getopts d:n: opt; do
  case $opt in
    d) eval "$("$dbio_db" env "$OPTARG")";;
    n) dbio_pgname=$OPTARG;;
    *) exit 64;;
  esac
done
shift $((OPTIND - 1))
if [ -n "$dbio_pgname" ]; then
  for v in DBIO_TEST_PG_DSN DBIO_TEST_PG_EXT_DSN; do
    [ -n "${!v:-}" ] && export "$v=${!v/dbname=dbio_test/dbname=$dbio_pgname}"
  done
fi
dbio_args=("$@")
