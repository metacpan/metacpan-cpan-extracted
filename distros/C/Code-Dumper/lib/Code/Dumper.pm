package Code::Dumper;

our $VERSION = '0.01';

use strict;
use warnings;

use Filter::Simple;

FILTER_ONLY
	'executable' => sub {
		s{
			\s* \# \s* DUMP \s* [(] \s*
			(.*?)
			\s* \# \s* [)] \s*
		 }
		 {
			print ' \n$1\n ';
			$1;
		 }gisx;
	};

1;

__END__

=head1 NAME

Code::Dumper - A debugging module to have your cake and eat it too 

=head1 SYNOPSIS

  use Code::Dumper;

  # DUMP (

  print "just another perl hacker";

  # )

=head1 DESCRIPTION

Surround code with the special Code::Dumper comments (see L<SYNOPSIS>) and your code will be:

=over

=item

executed as normal

=item

printed as well

=back

Debugging can be fun. However after B<too many> print statements and L<Data::Dumper>s have been sprinked all around, lets face it... it can do your head in. B<Code::Dumper> is a module that attempts to bring back debugging context and your sanity. 

=head1 BUGS

Please report them. Better yet, submit a patch :)

=head1 AUTHOR

Alfie John, E<lt>alfiejohn@flamebait.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
