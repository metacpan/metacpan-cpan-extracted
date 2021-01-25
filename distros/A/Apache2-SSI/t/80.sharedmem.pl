#!perl
BEGIN
{
    use strict;
    use lib './lib';
    use Apache2::SSI::Notes;
};

{
    ## We open it in write mode, but not create, because 80.notes.t will have created for us already
    my $shem = Apache2::SSI::SharedMem->new(
        debug => Apache2_SSI_Notes_Debug,
        create => 0,
        key => 'test_key',
        size => 2048,
        destroy => 0,
        mode => 0666,
        debug => 0,
    );
    ## For debugging only
    ## $shem->create(1);
    ## $shem->destroy(1);
    my $s = $shem->open || die( $shem->error );
    my $ref = $s->read;
    defined( $ref ) || die( $s->error );
    ref( $ref ) eq 'HASH' || die( "Shared memory data is not an hash reference." );
    # $ref = {};
    $ref->{year} = 2021;
    defined( $s->write( $ref ) ) || die( "Unable to write to shared memory: $!" );
    ## $ref = $s->read;
    ## ref( $ref ) eq 'HASH' || die( "Shared memory data is not an hash reference." );
    print( STDOUT "ok\n" );
    ## $s->remove;
    exit( 0 );
}

__END__

