casper.test.begin('Cow can moo', 2, function suite(test) {
    var cow = new Cow();
    test.assertEquals(cow.moo(), 'moo!', 'we can moo!');
    test.assert(cow.mowed);
    test.done();
});
