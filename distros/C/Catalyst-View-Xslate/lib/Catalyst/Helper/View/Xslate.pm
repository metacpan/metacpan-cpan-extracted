package Catalyst::Helper::View::Xslate;

use strict;

=head1 NAME

Catalyst::Helper::View::Xslate - Helper for Xslate Views

=head1 SYNOPSIS

For a standard (Kolon) syntax

    script/create.pl view HTML Xslate

Alternatively, for a Template-Toolkit syntax:

    script/create.pl view HTML Xslate bridge=TT2 syntax=TTerse


=head1 DESCRIPTION

This is a helper module for Xslate Views. It is not meant to be used
directly. Instead, you should use your Catalyst app's "create" script
(see the SYNOPSIS for syntax).

=head2 Arguments

As any other view helper, the first argument is your View's name. In the
synopsys example we used "HTML", and it's usually a good name :)

The Xslate helper accepts the same construction arguments as
L<Text::Xslate itself|Text::Xslate>.
List arguments can be separated by comma:

    script/create.pl view HTML Xslate cache=2 header=foo.tx,bar.tx suffix=.tt
 
For convenience, it also takes the following argument:

C<bridge> - The optional bridge method. It can be set to C<TT2> for
L<Template-Toolkit|Template> compatibility, or C<TT2Like> for a similar
layer, but that doesn't require Template-Toolkit installed at all.

So, if you specify C<bridge=TT2Like> (for example), you'll automatically get:

  module => [ 'Text::Xslate::Bridge::TT2Like' ]

If you also wish to use TT's syntax, remember to also pass C<syntax=TTerse>
on the command line.

=head2 METHODS

=head3 mk_compclass

This method is used by the Catalyst helper engine to generate files properly.

=cut

sub mk_compclass {
    my ( $self, $helper, @args ) = @_;

    my $file = $helper->{file};
    my $template = 'compclass';

    if ( @args ) {
        $helper->{loader_args} = _build_strings(_parse_args(@args));
        $template .= 'extended';
    }

    $helper->render_file( $template, $file );
}

sub _parse_args {
    my $args = {};

    my %need_array = map { $_, 1 } qw(path module header footer);
    my %need_hash  = map { $_, 1 } qw(function);

    foreach my $item (@_) {
        my ($key, $value) = split /=(?![>])/, $item;

        # the bridge key is a special case
        if ($key eq 'bridge') {
            $key = 'module';
            $value = 'Text::Xslate::Bridge::' . $value;
        }

        if ( exists $need_array{$key} ) {
            push @{ $args->{$key} }, split /,/, $value;
        }
        elsif (exists $need_hash{$key} ) {
            $args->{$key}->{'data'} = $value;
        }
        else {
            $args->{$key} = $value;
        }
    }
    return $args;
}

sub _build_strings {
    my $args = shift;
    my $return = {};

    foreach my $key (keys %$args) {
        my $ref = ref $args->{$key};

        my $value = '';
        if (!$ref) {
            $value = q[ default => '] . $args->{$key} . q[' ];
        }
        elsif ($ref eq 'HASH') {
            $value = $/
                   . '    default => sub { { '
                   . $args->{$key}->{'data'}
                   . ' } }'
                   . $/
                   ;
        }
        elsif ($ref eq 'ARRAY') {
            $value = $/ 
                   . '    default => sub { [ '
                   . (join ', ', map { "'$_'" } @{$args->{$key}} )
                   . ' ] }'
                   . $/
                   ;
        }
        $return->{$key} = $value;
    }
    return $return;
}

=head1 SEE ALSO

L<Catalyst::View::Xslate>, L<Catalyst::Manual>, L<Catalyst::Helper>,
L<Text::Xslate>.

=head1 AUTHOR

Breno G. de Oliveira C<< <garu@cpan.org> >>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use warnings;

use base 'Catalyst::View::Xslate';

__PACKAGE__->config(
    template_extension => '.tx',
);

1;

=head1 NAME

[% class %] - Xslate View for [% app %]

=head1 DESCRIPTION

Xslate View for [% app %].

=cut

__compclassextended__
package [% class %];
use Moose;

extends 'Catalyst::View::Xslate';

[% FOREACH key = loader_args.keys -%]
has '+[% key %]' => ([% loader_args.${key} %]);

[% END -%]

1;

=head1 NAME

[% class %] - Xslate View for [% app %]

=head1 DESCRIPTION

Xslate View for [% app %].

=cut
