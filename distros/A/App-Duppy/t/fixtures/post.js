casper.test.begin('Postcow can Postmoo', 2, function suite(test) {
    var postcow = new PostCow();
    test.assertEquals(postcow.postmoo(), 'Post moo!', 'we can postmoo!');
    test.assert(postcow.postmowed);
    test.done();
});
