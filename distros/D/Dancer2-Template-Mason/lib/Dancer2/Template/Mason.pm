package Dancer2::Template::Mason;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Mason wrapper for Dancer2
$Dancer2::Template::Mason::VERSION = '0.1.1';
use strict;
use warnings;

use HTML::Mason::Interp;

use Moo;

require FindBin;

with 'Dancer2::Core::Role::Template';

has _engine => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my %config = %{$_[0]->config || {}};

        delete @config{qw/ environment location extension /};

        HTML::Mason::Interp->new( %config );
    },
);

has _root_dir => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my $self = shift;

        $self->config->{comp_root} ||= 
            $self->settings->{views} || $FindBin::Bin . '/views';
    },
);

sub _build_name { 'Dancer2::Template::Mason' }

has '+default_tmpl_ext' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->config->{extension} || 'mason';
    },
);

sub render {
    my ($self, $template, $tokens) = @_;

    my $root_dir = $self->_root_dir;
    
    $template =~ s/^\Q$root_dir//;  # cut the leading path

    my $content;
    $self->_engine->out_method( \$content );
    $self->_engine->exec($template, %$tokens);
    return $content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Template::Mason - Mason wrapper for Dancer2

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

  # in 'config.yml'
  template: 'mason'

  # in the app
 
  get '/foo', sub {
    template 'foo' => {
        title => 'bar'
    };
  };

Then, on C<views/foo.mason>:

    <%args>
    $title
    </%args>

    <h1><% $title %></h1>

    <p>Mason says hi!</p>

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<HTML::Mason> templating system. 
For templates using L<Mason> version
2.x, what you want is L<Dancer2::Template::Mason2>.

In order to use this engine, set the template to 'mason' in the configuration
file:

    template: mason

=head1 HTML::Mason::Interp CONFIGURATION

Parameters can also be passed to the L<HTML::Mason::Interp> interpreter via
the configuration file, like so:

    engines:
        mason:
            default_escape_flags: ['h']

If unspecified, C<comp_root> defaults to the C<views> configuration setting
or, if it's undefined, to the C</views> subdirectory of the application.

=head2 Notes on Mason Caching and Performance

To improve performance of your templates, Mason creates a long-term cache on
disk. This is great in production, where you want to squeak every ounce of
performance out of your application, but in development, it can be a pain
to constantly clear the cache. And when developing, it's not always clear
where Mason even stores the cache!

For development, we recommend disabling the Mason cache. In your
F<environments/development.yml> file, you'd put the following:

    template: "mason"
    engines:
      template:
        mason:
          use_object_files: 0
          static_source: 0

(static_source is also a potential performance enhancing setting.
See L<the Mason docs|https://metacpan.org/dist/HTML-Mason/view/lib/HTML/Mason/Admin.pod#Static-Source-Mode>
for more details)

In production (F<environments/production.yml>), recommended settings are:

    template: "mason"
    engines:
      template:
        mason:
          extension: m
          data_dir: "/path/to/your/app/var/"
          use_object_files: 1
          static_source: 1

C<data_dir> tells Mason where to store its long-term cache. It must be
an absolute path.

Clearing the cache is as easy as:

    rm -rf /path/to/your/app/var/obj

See L<the Mason docs|https://metacpan.org/dist/HTML-Mason/view/lib/HTML/Mason/Admin.pod#Object-Files>
for more information on the object files and caching.

=head1 SEE ALSO

L<Dancer2>, L<HTML::Mason>.

For Mason v2, see L<Mason> and L<Dancer2::Template::Mason2>.

And, of course, there is the original L<Dancer::Template::Mason>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
