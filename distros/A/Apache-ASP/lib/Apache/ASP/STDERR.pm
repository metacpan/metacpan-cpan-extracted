package Apache::ASP::STDERR;

# don't know what this code is used for, but keeping
# it around in case I find out!  --jc 4/20/2002

use strict;

# alias printing to the response object
sub TIEHANDLE { bless { asp => $_[1] }; }
sub PRINT {
    shift->{asp}->Out(@_);
}
sub PRINTF {
    my($self, $format, @list) = @_;   
    my $output = sprintf($format, @list);
    $self->{asp}->Out($output);
}

1;

