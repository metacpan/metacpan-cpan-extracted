package Begin;

our $VERSION = '0.01';

use strict;
use warnings;

use Data::Dumper;


sub import {
    package main;
    shift;
    eval "no strict; no warnings;\n" . join(',', @_);
    if ($@) {
	$@ =~ s/ at \(eval \d*\) line \d*//;
	warn "Begin error: $@";
	exit(1);
    }
}

1;
__END__

=head1 NAME

Begin - Run arbitrary code before your script starts

=head1 SYNOPSIS

  perl -MBegin='print "hello world\n"' script.pl

  perl -MBegin='$debug = 1' script.pl

=head1 DESCRIPTION

This module effectively allows to inject arbitrary code from the
command line before running any perl script.

It can be used to set global variables.

I find it also useful when running the perl debugger as a REPL to test
things. For instance:
 
  perl -MBegin='$ssh=Net::OpenSSH->new(host)' -de 1


=head1 SEE ALSO

L<perlrun>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
