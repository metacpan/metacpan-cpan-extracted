prove -Ilib t/05setup_db-*
perl -Ilib t/56writes.t --update-archive
mv t/expected-NEW.zip t/expected.zip