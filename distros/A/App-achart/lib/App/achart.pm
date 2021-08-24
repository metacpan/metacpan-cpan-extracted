package App::achart;

our $VERSION = '0.01';

1;

__END__

=encoding utf8

=head1 NAME

App::achart -  A program to print ASCII charts in the terminal

=head1 SYNOPSIS

  # Read a number from stdin
  $ perl -E'while (sleep 1) { $|=1; say 10 + 200 * rand }' | achart

  # Read multiple numbers from stdin
  # echo "x=10,y=42;z=23" | achart

  # Run a program that output rows of numbers
  $ achart --program "perl -lE'say x=>int 100*rand; say y=>100+int 50*rand'"

  # Example environment variables
  ACHART_BAR_CHAR="-";
  ACHART_COLORS="green,green-on_black,red-on_black";

=head1 DESCRIPTION

L<App::achart> is a program that produces colorful ASCII-based bar charts.

  $ achart --program "perl -lE'say x=>int 100*rand; say y=>100+int 50*rand'"
  09:16:56 x  56 ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎
  09:16:56 y 140 ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎
  09:16:57 x  22 ∎∎∎∎∎∎∎∎∎
  09:16:57 y 141 ∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎∎

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C), Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
