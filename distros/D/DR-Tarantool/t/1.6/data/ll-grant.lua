

box.cfg{

}

box.schema.user.create('test_user')
box.schema.user.grant('test_user', 'read,write', 'universe')
