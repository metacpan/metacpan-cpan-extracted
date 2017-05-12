describe("A testsuite", function() {
    it( "should report a success", function(){
        expect( $('h1:first').text() ).toBe('Perl is dancing');
    });
    it( "will fail", function(){
        expect( 0 ).toBeTruthy();
    });
});
