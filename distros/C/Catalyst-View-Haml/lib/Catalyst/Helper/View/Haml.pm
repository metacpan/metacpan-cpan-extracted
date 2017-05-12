package Catalyst::Helper::View::Haml;

use strict;

=head1 NAME

Catalyst::Helper::View::Haml - Helper for Haml Views

=head1 SYNOPSIS

For a standard View class:

    script/create.pl view HTML Haml

You can also pass parameters at will:

    script/create.pl view HTML Haml vars_as_subs=1 format=html5


=head1 DESCRIPTION

This is a helper module for Haml Views. It is not meant to be used
directly. Instead, you should use your Catalyst app's "create" script
(see the SYNOPSIS for syntax).

=head2 Arguments

As any other view helper, the first argument is your View's name. In the
synopsys example we used "HTML", and it's usually a good name :)

The Haml helper accepts the same construction arguments as
L<Text::Haml itself|Text::Haml>.
List arguments can be separated by comma:

    script/create.pl view HTML Haml path=/var/templates,/templates
 

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
    }

    $helper->render_file( $template, $file );
}

sub _parse_args {
    my $args = {};

    my %need_array = map { $_, 1 } qw(path);
    my %need_hash  = map { $_, 1 } qw();     #TODO

    foreach my $item (@_) {
        my ($key, $value) = split /=(?![>])/, $item;

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

L<Catalyst::View::Haml>, L<Catalyst::Manual>, L<Catalyst::Helper>,
L<Text::Haml>.

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
use Moose;

extends 'Catalyst::View::Haml';

[% FOREACH key = loader_args.keys -%]
has '+[% key %]' => ([% loader_args.${key} %]);

[% END -%]

1;

=head1 NAME

[% class %] - Haml View for [% app %]

=head1 DESCRIPTION

Haml View for [% app %].

=cut
