use Apache::TestRequest 'UPLOAD_BODY_ASSERT';
print UPLOAD_BODY_ASSERT "/TestCGI__upload", undef, content => "ABCDEFGHIJ";
