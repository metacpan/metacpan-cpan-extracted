package App::Pod2CpanHtml;

###############################################################################
#
# App::Pod2CpanHtml - Convert Pod to search.cpan.org style HTML.
#
#
# Copyright 2009, John McNamara, jmcnamara@cpan.org
#
# Documentation after __END__
#

use strict;
use Pod::Simple::HTML;

use vars qw(@ISA $VERSION);

@ISA     = 'Pod::Simple::HTML';
$VERSION = '0.04';

###############################################################################
#
# new()
#
# Simple constructor inheriting from Pod::Simple::HTML.
#
sub new {

    my $class                   = shift;
    my $self                    = Pod::Simple::HTML->new(@_);
       $self->{index}           = 1;
       $self->{html_css}        = 'http://search.cpan.org/s/style.css';

    bless  $self, $class;
    return $self;
}

1;

__END__

=pod

=head1 NAME

App::Pod2CpanHtml - Convert Pod to search.cpan.org style HTML.

=head1 DESCRIPTION

This module is used for converting Pod documents to L<http://search.cpan.org/> style HTML.

Pod is Perl's I<Plain Old Documentation> format, see L<perlpod>.

C<App::Pod2CpanHtml> produces HTML output similar to search.cpan.org by using the same conversion module, L<Pod::Simple::HTML> and the same CSS, L<http://search.cpan.org/s/style.css>.

It should be noted that this utility isn't the actual program used to create the HTML for seach.cpan.org. However, the output should visually be the same.

This module comes with a L<pod2cpanhtml> utility that will convert Pod to search.cpan.org style HTML on the command line.


=head1 SYNOPSIS


To create a simple filter to convert Pod to search.cpan.org style HTML.

    #!/usr/bin/perl -w

    use strict;
    use App::Pod2CpanHtml;


    my $parser = App::Pod2CpanHtml->new();

    if (defined $ARGV[0]) {
        open IN, $ARGV[0]  or die "Couldn't open $ARGV[0]: $!\n";
    } else {
        *IN = *STDIN;
    }

    if (defined $ARGV[1]) {
        open OUT, ">$ARGV[1]" or die "Couldn't open $ARGV[1]: $!\n";
    } else {
        *OUT = *STDOUT;
    }

    $parser->output_fh(*OUT);
    $parser->parse_file(*IN);

    __END__


To convert Pod to search.cpan.org style HTML using the installed C<pod2cpanhtml> utility:

    pod2cpanhtml file.pod > file.html

=head1 METHODS

=head2 new()

The C<new> method is used to create a new C<App::Pod2CpanHtml> object.

=head2 Other methods

C<App::Pod2CpanHtml> inherits all of the methods of its parent modules C<Pod::Simple> and C<Pod::Simple::HTML>. See L<Pod::Simple> for more details if you need finer control over the output of this module.


=head1 RATIONALE

This module is a very thin wrapper around L<Pod::Simple::HTML>. I wrote the initial version is response to a question on Perlmonks L<http://www.perlmonks.com/?node_id=596075>.

Despite its simplicity it has proved to be very useful tool for proofing Pod documentation prior to uploading to CPAN. It is also the basis of a script that I frequently copy from machine to machine and it is the answer to a question that is frequently asked on Perl forums. As such, I thought it was time to roll it into a module.


=head1 SEE ALSO

This module also installs a L<pod2cpanhtml> command line utility. See C<pod2cpanhtml --help> for details.

You can render a Pod document using search.cpan's own engine at the following link: L<http://search.cpan.org/pod2html>.

Graham Barr's patch to Pod::Simple to produce the search.cpan output: L<http://cpan.org/authors/id/G/GB/GBARR/search.cpan.org-Pod-Simple-HTML.patch>

See L<Pod::ProjectDocs> for generating multiple, inter-linked, search.cpan like documents


=head1 ACKNOWLEDGEMENTS

Thanks to Sean M. Burke and the past and current maintainers for C<Pod::Simple>.

Thanks to Graham Barr and everyone involved with L<http://search.cpan.org>.

Thanks to Lars Dieckow for the useful links.

The initial structure of this module was created using L<Module::Starter>, thanks to Andy Lester.


=head1 AUTHOR

John McNamara, C<jmcnamara@cpan.org>


=head1 COPYRIGHT & LICENSE

Copyright 2009 John McNamara.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License. See L<http://dev.perl.org/licenses/> for more information.

=cut

