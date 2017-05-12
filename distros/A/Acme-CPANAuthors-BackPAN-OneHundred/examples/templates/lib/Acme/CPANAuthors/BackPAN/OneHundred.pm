package Acme::CPANAuthors::BackPAN::OneHundred;
use strict;
use warnings;

{
    no strict "vars";
    $VERSION = "[% VERSION %]";
}

use Acme::CPANAuthors::Register (

[% FOREACH item = LIST1 %]
[% item %]

[% END %]

);

q<
We are programmed just to do
Anything you want us to

We are the robots, we are the robots
We are the robots, we are the robots

Lyrics copyright Ralf Hütter
>

__END__

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::BackPAN::OneHundred - The CPAN Authors who have 100+ distributions on BackPAN

=head1 DESCRIPTION

This class provides a hash of CPAN authors' PAUSE ID and name to be 
used with the C<Acme::CPANAuthors> module.

This module was created to capture all those CPAN Authors who have valiantly
submitted their modules and distributions to CPAN, and now have the honour of
having submitted 100 or more distributions to CPAN. 

Note that the CPAN authors listed here may not be maintaining 100 or more
distributions on CPAN, but have submitted 100 or more distributions to PAUSE, 
where some older distributions may have been deprecated or adopted by other 
authors. The numbers here represent the number of distributions a CPAN author 
has listed on BackPAN.

See L<http://backpan.cpantesters.org>.

=head1 THE AUTHORS

[% FOREACH item = LIST2 %]
[% item %]

[% END %]

List last updated: [% WHEN %]


=head1 MAINTENANCE

If you are aware of any CPAN author that has attained the heady heights of 100
distributions on CPAN, and who is not listed here, please send me their ID/name
via email or RT, and I will update the module. If there are any mistakes, 
please contact me as soon as possible, and I'll amend the entry right away.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one

L<Acme::CPANAuthors::CPAN::OneHundred> - 100+ distributions on CPAN.

=head1 SUPPORT

Bugs, patches and feature requests can be reported at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-BackPAN-OneHundred>

=item * GitHub

L<http://github.com/barbie/acme-cpanauthors-backpan-onehundred>

=back

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to 
the RT queue. However, it would help greatly if you are able to pinpoint 
problems or even supply a patch. 

Fixes are dependent upon their severity and my availability. Should a fix 
not be forthcoming, please feel free to (politely) remind me.

=head1 ACKNOWLEDGEMENTS

Thanks to Kenichi Ishigaki for writing C<Acme::CPANAuthors>.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT & LICENSE

  Copyright [% COPYRIGHT %] Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
