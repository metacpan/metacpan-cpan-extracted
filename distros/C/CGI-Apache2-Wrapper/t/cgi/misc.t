use Apache::TestRequest 'GET_BODY_ASSERT';
print GET_BODY_ASSERT "/TestCGI__misc/extra/path/info?opening=hello;closing=goodbye";
