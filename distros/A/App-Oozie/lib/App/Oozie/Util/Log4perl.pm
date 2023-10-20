package App::Oozie::Util::Log4perl;
$App::Oozie::Util::Log4perl::VERSION = '0.010';
use 5.014;
use strict;
use warnings;

use App::Oozie::Util::Plugin qw(
    find_files_in_inc
    find_plugins
);
use Moo;

# TODO
sub find_template {
    my $self = shift;
    my $type = shift || 'simple';

    my @found = find_files_in_inc('App/Oozie/Util/Log4perl/Templates', 'l4p');
    my %tmpl = map { @{ $_ }{qw/ name abs_path /} } @found;

    return $tmpl{ $type } || $tmpl{simple} || die "No log4perl template file was found";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Util::Log4perl

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use App::Oozie::Util::Log4perl;
    my $file = App::Oozie::Util::Log4perl->new->find_template;

=head1 DESCRIPTION

Internal module.

=head1 NAME

App::Oozie::Util::Log4perl - Helper for handling the Log4perl template.

=head1 Methods

=head2 find_template

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
