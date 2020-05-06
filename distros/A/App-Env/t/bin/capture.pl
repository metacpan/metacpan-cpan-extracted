
if ( @ARGV ) {

    exit(1) if $ARGV[0] eq 'exit';

    print STDOUT "$_\n" foreach @ARGV;

}

else {

    print STDERR "STDERR\n";
    print STDOUT "STDOUT\n";

}
