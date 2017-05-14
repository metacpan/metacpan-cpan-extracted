casper.test.begin('Precow can Premoo', 2, function suite(test) {
    var precow = new PreCow();
    test.assertEquals(precow.premoo(), 'Pre moo!', 'we can premoo!');
    test.assert(precow.premowed);
    test.done();
});
