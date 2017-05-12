#!/bin/bash

dbigraph.pl --dsn=dbi:Pg:dbname=cms --user=cms --pass=cms --as=png > cms.schema.png

echo Wrote ./cms.schema.png
