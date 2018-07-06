# use the location of the current module as a guide for where to find configs
(my $filename = __PACKAGE__ ) =~ s#::#/#g;
$filename .= '.pm';
(my $path = $INC{$filename}) =~ s#/\Q$filename\E$##g; # strip / and filename
