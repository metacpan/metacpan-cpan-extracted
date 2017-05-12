package Class::DBI::Plugin::Param;

use warnings;
use strict;
use Carp;

our $VERSION = '0.03';

sub import {
    my $class = shift;
    my $callpkg = caller;
    die "This module only works correctly under a subclass of Class::DBI"
        unless ($callpkg->isa('Class::DBI'));
    {
        no strict 'refs';
        *{$callpkg."::param"} = sub {
            my $self = shift;
            my $column_name = shift or
                croak "You gave me no parameters to param()!";
            return $self->$column_name(@_);
        }
    }
}

1;

__END__

=head1 NAME

Class::DBI::Plugin::Param - Adding param() method to your CDBI object.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Just use this module in your subclass of CDBI.

    package MyApp::DBI;
    use base 'Class::DBI';

    use Class::DBI::Plugin::Param; # just use

    MyApp::DBI->connection(
        ...
    );

    package MyApp::Music
    use base 'MyApp::DBI';
    ...

    # in your script
    my $music = MyApp::Music->retrieve($id);
    print $music->param('title');
    $music->param(title => 'Waltz For Debby');

Or use the 'additional_classes' option with Class::DBI::Loader.

    use Class::DBI::Loader;
    my $loader = Class::DBI::Loader->new(
        ...
        additional_classes => qw/Class::DBI::Plugin::Param/
    );

=head1 DESCRIPTION

This module allows you to add param() method to your Class::DBI
object. This makes it easier to pass your object to
L<HTML::FillinForm> / L<Template::Plugin::FillInForm> /
L<HTML::Template> like this:

    my $music = MyApp::Music->retrieve($id);
    my $fif = HTML::FillInForm->new;
    my $output = $fif->fill(
        scalarref => \$html,
        fobject => $music
    );

    # OR
    [% USE FillInForm %]
    [% FILTER fillinform fobject => music %]
    <form method="get">
        ...
    </form>
    [% END %]

    # OR
    my $template = HTML::Template->new(
        filename => 'template.tmpl',
        associate => $music,
    );

=head1 FUNCTIONS

=head2 param

Gets/Sets the parameters.

=head1 AUTHOR

Naoya Ito, C<< <naoya at bloghackers.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-class-dbi-plugin-param at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-Plugin-Param>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::DBI::Plugin::Param

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-DBI-Plugin-Param>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-DBI-Plugin-Param>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DBI-Plugin-Param>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-DBI-Plugin-Param>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Naoya Ito, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

