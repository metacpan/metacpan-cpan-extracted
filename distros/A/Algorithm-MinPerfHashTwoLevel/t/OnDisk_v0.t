$ENV{VARIANT}= 0;
unless (my $return= do(my $file="./t/OnDisk.pl")) {
    if ($@) {
        die $@;
    } elsif (!defined $return) {
        die "couldn't do '$file': $!";
    } else {
        die "'$file' returned false";
    }
}

