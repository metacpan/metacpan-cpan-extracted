package App::Navegante;

use warnings;
use strict;

=encoding utf-8

=head1 NAME

App::Navegante - a framework to build intrusive high order proxies

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

  $ navegante examples/program

=head1 DESCRIPTION

This module is mostly a place holder for the documentation. All the
magic is done whith the C<navegante> program.

To build an application using Navegante you need to have a program
file. This program file is splitted in two major sections:

=over 4

=item DSL oefinitions

The first section is used to specify application parameters
using a well defined DSL, detailed in the next section.

=item Generic definitions

The second section is used to define any kind of functions
needed by our application in Perl syntax.

=back

=head2 Domain Specific Language

The statements that can currently be used are:

=over 4

=item C<init(STRING)>

The name of the function that is called in the beginning of every 
application call.

=item C<desc(STRING)>

The function that prints the application's behavior.

=item C<formtitle(STRING)>

Define the form's title of the application.

=item C<save>

TODO

=item C<mail>

TODO

=item C<filename(STRING)>

The destination filename for the newly create application. If no C<filename>
is specified, prints to standard output.

=item C<feedback(STRING)>

The function that is called when the application's feedback link is
followed.

=item C<proc(STRING)>

The function that is used to actually process the page content.

=item C<proctags(STRING)>

The functions that should be called to process specific HTML tags
content. For example:

C<proctags(h1=>toitalic,h2=>underline)>

would call the function C<toitalic> when processing C<H1> tag's content, 
and C<underline> when processing C<H2> tag's content.

=item C<protect(LIST)>

Comma separated list of HTML tags that will not be processed by the 
C<proc> function. By default this list is: 'html','head','script'
and 'title'.

=item C<livefeedback(STRING)>

The function that is used to render the feedback section in the 
application's banner.

=item C<annotate(STRING)>

The fucntion that is called when the form user data, in the application's
banner is submitted.

=item C<iform(STRING)>

Used to used the form that is going to be rendered in the application's
banner. For example:

C<iform(name=>text,"Set name!"=>submit)>

Would render a iframe with a two elements form: a text box named C<name>
and a submit button. See also C<iframe> for a more elaborate method
to define this form.

=item C<iframe(STRING)>

If defining the form that is used in the banner is not enough, you can
use C<iframe> to define the name of a function that returns the entire
iframe content. Note that C<iframe> always takes precedence over
C<iform> in case you define both.

=item C<quit(STRING)>

The function that is called when the appliccation's banner quit button
is followed.

=back

=head2 Generic Definitions

The space between "##" and EOF is just copied do application. Tipycally,
it should include the implementation of the function described as arguments.

=head1 EXAMPLES

An example program file should look something like:

  filename(reverse)
  formtitle(Reverse Browsed Content)
  feedback(reverseFeedback)
  proc(reverseFuncion)
  desc(reverseDesc)

  ##

  sub reverseFunction {
  ...

For more examples refer see TODO.

=head1 AUTHOR

J.Joao Almeira, C<< <jj@di.uminho.pt> >>

Alberto Simões, C<< <albie@alfarrabio.di.uminho.pt> >>

Nuno Carvalho, C<< <smash@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-navegante at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Navegante>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Navegante


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Navegante>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Navegante>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Navegante>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Navegante>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007-2012 Project Natura.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::Navegante
