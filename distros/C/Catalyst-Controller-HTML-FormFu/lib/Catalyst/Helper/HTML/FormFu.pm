package Catalyst::Helper::HTML::FormFu;

use strict;
use warnings;

our $VERSION = '2.04'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use File::Spec;
use HTML::FormFu::Deploy;
use Carp qw/ croak /;

sub mk_stuff {
    my ( $self, $helper, $dir ) = @_;

    my @files = HTML::FormFu::Deploy::file_list();

    my $form_dir = File::Spec->catdir( $helper->{base}, 'root', ( defined $dir ? $dir : 'formfu' ) );

    $helper->mk_dir($form_dir) unless -d $form_dir;

    for my $filename (@files) {
        my $path = File::Spec->catfile( $form_dir, $filename );
        my $data = HTML::FormFu::Deploy::file_source($filename);

        $helper->mk_file( $path, $data );
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Helper::HTML::FormFu

=head1 VERSION

version 2.04

=head1 SYNOPSIS

    script/myapp_create.pl HTML::FormFu

=head1 DESCRIPTION

As of version 0.02000, L<HTML::FormFu> doesn't use the TT template files by
default - it uses in internal rendering engine.

If you don't want to customise the generated markup, you don't need to use
L<Catalyst::Helper::HTML::FormFu> at all.

If you want to customise the generated markup, you'll need a local copy of the
template files. To create the files in the default C<root/formfu> directory,
run:

    script/myapp_create.pl HTML::FormFu

To create the files in a different subdirectory of C<root>, pass the path as an
argument. The following example would create the template files into the
directory C<root/forms>.

    script/myapp_create.pl HTML::FormFu forms

You'll  also need to tell HTML::FormFu to use the TT renderer, this can be
achieved with L<Catalyst::Controller::HTML::FormFu>, with the following
Catalyst application YAML config:

    ---
    'Controller::HTML::FormFu':
      constructor:
        render_method: tt

=head1 NAME

Catalyst::Helper::HTML::FormFu - Helper to deploy HTML::FormFu template files.

=head1 SUPPORT

IRC:

    Join #catalyst on irc.perl.org.

Mailing Lists:

    http://lists.rawmode.org/cgi-bin/mailman/listinfo/html-widget

=head1 SEE ALSO

L<HTML::FormFu>, L<Catalyst::Helper>

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=head1 AUTHORS

=over 4

=item *

Carl Franks <cpan@fireartist.com>

=item *

Nigel Metheringham <nigelm@cpan.org>

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007-2018 by Carl Franks / Nigel Metheringham / Dean Hamstead.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
