package Dancer2::Template::HTCompiled;
use strict;
use warnings;
our $VERSION = '0.003'; # VERSION

use Moo;
use Carp qw/ croak /;
use HTML::Template::Compiled;

with 'Dancer2::Core::Role::Template';

has '+default_tmpl_ext' => (
    default => sub { 'html' }
);
has '+engine' => (
    isa => sub {
        $_[0] eq "HTML::Template::Compiled"
    },
);

sub _build_engine {
    'HTML::Template::Compiled'
}

sub render {
    my ($self, $tmpl, $vars) = @_;

    my %config = %{ $self->config };
    my $env = delete $config{environment};
    my $location = delete $config{location};
    $config{path} = File::Spec->catfile($location, $config{path})
        if defined $location;
    my $htc = $self->engine;
    my $content = eval {
        my $t;
        if ( ref($tmpl) eq 'SCALAR' ) {
            $t = $htc->new_scalar_ref($tmpl, %config);
        }
        else {
            $t = $htc->new_file($tmpl, %config);
        }
        $t->param($vars);
        $t->output;
    };

    if (my $error = $@) {
        croak $error;
    }

    return $content;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dancer2::Template::HTCompiled - HTML::Template::Compiled template engine for Dancer2

=head1 SYNOPSIS

config.yaml:

    template: HTCompiled
    engines:
      template:
        HTCompiled:
          path: "views"
          case_sensitive: 1
          default_escape: "HTML"
          loop_context_vars: 1
          tagstyle: ["-classic", "-comment", "-asp", "+tt"]
          expire_time: 1

    use Dancer2;
    get /page/:number => sub {
        my $page_num = params->{number};
        template "foo.html", { page_num => $page_num };
    };

=head1 METHODS

=over

=item render

    my $output = $htc->render($template, $param);
    my $output = $htc->render(\$string, $param);

    my $htc = Dancer2::Template::HTCompiled->new(
        config => {
            path => "path/to/templates",
        },
    );
    my $param = {
        something => 23,
    };
    my $template = "foo.html";
    my $output = $htc->render($template, $param);
    my $string = "foo [%= bar %]";
    my $output = $htc->render(\$string, $param);

=back

=head1 SEE ALSO

L<HTML::Template::Compiled>, L<Dancer2>

=head1 LICENSE

This software is copyright (c) 2014 by Tina Müller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

