package Backtick::AutoChomp;

use warnings;
use strict;
use Filter::Simple;
use PPI;
our $VERSION = '0.02';
FILTER {
  my $doc = PPI::Document->new(\$_);
  $_->set_content(sprintf 'do{local $_=%s;chomp;$_}', $_->content)
        for @{ $doc->find( sub {
                  $_[1]->isa('PPI::Token::QuoteLike::Backtick')
                  or
                  $_[1]->isa('PPI::Token::QuoteLike::Command')
                } ) || []
             };
  $_ = $doc->content;
};

1;

=pod

=head1 NAME

Backtick::AutoChomp - auto-chomp() result of backtick(``) and qx//

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Automatically C<chomp()> result of a backtick (``) or qx// command.

    $s = `echo blah` . 'stuff';
    print $s;   # blah\nstuff

    use Backtick::AutoChomp;
    $s = `echo blah` . 'stuff';
    print $s;   # blahstuff
    no Backtick::AutoChomp;

=head1 DESCRIPTION

In bash, the shell will automatically chomp the result of a backtick call.

    s=`whoami`       # me
    echo =$s=        # =me=
    echo =`whoami`=  # =me=

In perl, we mustB<**> do:

    $s = `whoami`;
    chomp($s);
    print "=$s=";

The goal of this module is for this to DWIM:

    print "=".`whoami`."=";

Another case where this is potentially useful:

    use Backtick::AutoChomp;
    printf "me(%s), host(%s), kernel(%s), date(%s)\n",
	`whoami`,
	`hostname`,
	`uname -r`,
	`date`,
    ;

B<**> Yes, there are pure-perl ways to do I<whoami>, I<hostname>, etc.  But keep in mind programs that don't have equivalents ... and also, especially for temp/quick-n-dirty scripts, the convenience factor :)

Note that this is implemented as a source filter. It replaces a backtick or qx statement with a C<do{}> statement.

=head1 SEE ALSO

L<PPI>, L<Filter::Simple>

=head1 AUTHOR

David Westbrook (CPAN: davidrw), C<< <dwestbrook at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-backtick-chomp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Backtick-AutoChomp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Backtick::AutoChomp

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Backtick-AutoChomp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Backtick-AutoChomp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Backtick-AutoChomp>

=item * Search CPAN

L<http://search.cpan.org/dist/Backtick-AutoChomp>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

