#!/bin/sh

export DBIC_MIGRATION_SCHEMA_CLASS=MyApp::Schema

dbic-migration -Ilib --target_dir ./share $@
