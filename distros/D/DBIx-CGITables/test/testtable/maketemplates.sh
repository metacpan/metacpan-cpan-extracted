# Mock up some ugly templates:
perl -MDBIx::CGITables::MakeTemplates -e 'make "dbi:mysql:test:localhost"' \
          < testtable.dd

# Add testuser identified by testpass as the DB user:
echo '!Username=testuser' >> test.testtable.param.dbt
echo '!Password=testpass' >> test.testtable.param.dbt
 
