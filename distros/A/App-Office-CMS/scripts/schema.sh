#!/bin/bash

DBI_DSN=dbi:Pg:dbname=cms
DBI_USER=cms
DI_PASS=cms
export DBI_DSN
export DBI_USER
export DBI_PASS

dbi.schema.pl svg > docs/cms.schema.svg

echo Wrote docs/cms.schema.png
