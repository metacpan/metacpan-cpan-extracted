#!/bin/bash

set -ue

# This script sets up the buzzsaw database and owner if you are
# starting from scratch. This should, normally, be run as the postgres
# user.

createuser --no-createrole --no-createdb --no-superuser buzzsaw
createuser --no-createrole --no-createdb --no-superuser logfiles_reader
createuser --no-createrole --no-createdb --no-superuser logfiles_writer

createdb --owner buzzsaw buzzsaw
createlang plpgsql buzzsaw


