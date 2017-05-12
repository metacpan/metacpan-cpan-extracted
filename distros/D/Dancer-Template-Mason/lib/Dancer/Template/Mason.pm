package Dancer::Template::Mason;
BEGIN {
  $Dancer::Template::Mason::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Mason wrapper for Dancer
$Dancer::Template::Mason::VERSION = '0.004001';
use strict;
use warnings;

use HTML::Mason::Interp;

require Dancer;

use Moo;

require FindBin;
require Dancer::Config;

Dancer::Config->import( 'setting' );

extends 'Dancer::Template::Abstract';

has _engine => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my %config = %{$_[0]->config || {}};

        delete $config{$_} for qw/ environment location extension /;
        HTML::Mason::Interp->new( %config );
    },
);

has _root_dir => (
    is => 'rw',
    lazy => 1,
    default => sub {
        $_[0]->config->{comp_root} ||= 
            setting( 'views' ) || $FindBin::Bin . '/views';
    },
);

sub _build_name { 'Dancer::Template::Mason' }

has default_tmpl_ext => (
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

Dancer::Template::Mason - Mason wrapper for Dancer

=head1 VERSION

version 0.004001

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
2.x, what you want is L<Dancer::Template::Mason2>.

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

=head1 SEE ALSO

L<Dancer>, L<HTML::Mason>.

For Mason v2, see L<Mason> and L<Dancer::Template::Mason2>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
