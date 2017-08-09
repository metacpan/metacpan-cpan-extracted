package Dancer2::Plugin::Paginator;

$Dancer2::Plugin::Paginator::VERSION   = '2.02';
$Dancer2::Plugin::Paginator::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Dancer2::Plugin::Paginator - Dancer2 plugin for Paginator::Lite.

=head1 VERSION

Version 2.02

=cut

use strict; use warnings;

use Dancer2::Plugin;
use Paginator::Lite;

register paginator => sub {
    my ($dsl, %params) = @_;

    my $conf = plugin_setting;
    $conf->{frame_size} ||= 5;
    $conf->{page_size}  ||= 10;

    return Paginator::Lite->new(%{$conf}, %params);
};

register_plugin;

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Paginator;

    get '/list' => sub {
        my $paginator = paginator(
            'curr'     => $page,
            'items'    => rset('Post')->count,
            'base_url' => '/posts/page/',
        );

        template 'list', { paginator => $paginator };
    };

    dance;

=head1 CONFIGURATION

Configuration can be done in your L<Dancer2> app config file as described below:

    plugins:
        Paginator:
            frame_size: 3
            page_size: 7

=head1 METHODS

=head2 method paginator(%params)

Returns a L<Paginator::Lite> object. Receives same parameters that as the L<Paginator::Lite>
constructor.

=head1 AUTHOR

Original author Blabos de Blebe, C<< <blabos@cpan.org> >>

Recently brought to live from BackPAN by Mohammad S Anwar, C<< <mohammad.anwar@yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Dancer2-Plugin-Paginator>

=head1 ACKNOWLEDGEMENTS

Blabos de Blebe has kindly  transferred  the ownership of this distribution to me
and even handed over the GitHub repository as well.

=head1 SEE ALSO

L<Paginator::Lite>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-captcha at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Captcha>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Paginator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-Paginator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Paginator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Paginator>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-Paginator/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Blabos de Blebe.
Copyright (C) 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the terms same as Perl 5.

=cut

1; # End of Dancer2::Plugin::Paginator
