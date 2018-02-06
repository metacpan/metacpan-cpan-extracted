package App::ShellCheckWiki;

use 5.006;
use strict;
use warnings;

use Term::ANSIColor;
use WWW::Mechanize;

our $VERSION = '0.03';

my $formats = {
    '# '   => 'bold green',   # H1
    '## '  => 'bold magenta', # H2
    '### ' => 'bold red',     # H3
    '```'  => 'yellow',       # Code Block
};

my $wiki_url = 'https://raw.githubusercontent.com/wiki/koalaman/shellcheck';
my $wiki_toc = 'https://github.com/koalaman/shellcheck/wiki';

my $mech = WWW::Mechanize->new( autocheck => 0 );

sub run {
    my $page = $ARGV[0];
    if (defined($page)) {
        my ($page_id) = $page =~ m|(\d+)$|;
        my $wiki_page = $wiki_url . '/SC' . $page_id . '.md';
        $mech->get($wiki_page);
        if ($mech->success) {
            print colored(['green'],"ShellCheck Error CS$page_id\n");
            format_page($mech->content());
        } else {
            print "Unable to find page '$page'!\n";
            show_topics();
        }
    } else {
        show_topics();
    }
    exit 0;
}

sub format_page {
    my ($content) = @_;
    my $indent  = 0;
    my $code_block = '```';
    my $code_block_format = $formats->{$code_block} || 'yellow';

    for my $line ( split /\n/, $content ) {
        my $matched = 0;
        for my $start ( sort keys %$formats ) {
            if ( my ($remainder) = starts_with( $line, $start ) ) {
                $matched = 1;
                my $format = $formats->{$start};
                if ( $start eq $code_block ) {
                    $indent = ( $indent + 1 ) % 2;
                    $code_block_format = $format;
                    print "\n";
                } else {
                    print $start;
                    print colored( [$format], $remainder )."\n";
                }
            }
        }

        # Regular Line or Code Block
        if ( not $matched ) {
            if ($indent) {
                # Code Block
                print colored( [$code_block_format], "    $line\n" );
            } else {
                # Regular Line
                print $line . "\n";
            }
        }
    }
    print "\n";
}

sub starts_with {
    my ($line, $format) = @_;
    return unless length($line) >= length($format);
    my $start = substr($line,0,length($format),'');
    return unless $start eq $format;
    return $line;
}

sub show_topics {
    print colored(['bold magenta'], "Checking for Available Topics: ");
    print colored(['green'], "SCxxxx\n");
    $mech->get($wiki_toc);
    my $topics = {};
    if ($mech->success()) {
        for my $link ($mech->links()) {
            next unless $link->url =~ m|SC(\d+)|;
            $topics->{$1}++;
        }
        my @ranges = number_range( keys %$topics );
        for my $range (@ranges) {
            print colored(['cyan'], $range . "\n");
        }
    } else {
        print "FAIL!";
    }
}

sub number_range {
    my (@numbers) = sort { $a <=> $b } @_;
    my @ranges;
    my $start = shift @numbers;
    my $stop = $start;
    while(scalar @numbers) {
        my $next = shift @numbers;
        if ( $next == $stop + 1 ) {
            $stop = $next;
        } else {
            if ($start == $stop) {
                push @ranges, $start;
            } else {
                push @ranges, $start . '-' . $stop;
            }
            $start = $stop = $next;
        }
    }

    # Group by Leading digits;
    my $groups;
    for my $range (@ranges) {
        my $leading = substr($range,0,2);
        push @{ $groups->{$leading} }, $range;
    }
    my @output_ranges;
    for my $leading ( sort keys %$groups ) {
        push @output_ranges, join(',', sort @{ $groups->{$leading} });
    }

    return @output_ranges;
}

1; # End of App::ShellCheckWiki
__END__

=head1 NAME

App::ShellCheckWiki - Check the wiki for details about shellcheck errors.

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Check the official ShellCheck wiki page for detailed shellcheck error info.

    # Show the wiki in the terminal for ShellCheck Error SC1234
    $ shellcheckwiki 1234

    # Show List of all Errors documented in the wiki
    $ shellcheckwiki

=head1 INSPIRATION

    ShellCheck is a static analysis tool for shell scripts.  Available from
    L<Github|https://github.com/koalaman/shellcheck> with an online demo at
    L<shellcheck.net|https://www.shellcheck.net/>.

    Think of it as the perlcritic for shell scripts.  It produces useful, but
    terse error messages with an error code, like SC1234.  There is a
    long-form description of most of these messages available on the
    L<github wiki page|https://github.com/koalaman/shellcheck/wiki>.

    The shellcheckwiki script can be used to fetch and display in the terminal
    a specific page or a table of contents, all from the comfort of the command
    line.

=head1 DEMO

    See shellcheckwiki in action at L<asciinema|https://asciinema.org/a/J0z2MZTJe8iesCGk2OsEL3sWb>

=head1 AUTHOR

Felix Tubiana, C<< <felixtubiana at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-shellcheckwiki at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ShellCheckWiki>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ShellCheckWiki


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ShellCheckWiki>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ShellCheckWiki>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ShellCheckWiki>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ShellCheckWiki/>

=item * Github Repo

L<http://github.com/xxfelixxx/shellcheckwiki>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Felix Tubiana.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (1.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_1_0>

Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution. Such use shall not be
construed as a distribution of this Package.

The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut
