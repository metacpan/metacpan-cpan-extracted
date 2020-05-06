#!perl

eval {

    open FH, '>', $ARGV[0] or die( "unable to open $ARGV[0] for writing\n" );
    print FH $ENV{Site1_App1}, "\n";
    close FH;
} or
  do { warn $@; exit(1); };

exit(0);
