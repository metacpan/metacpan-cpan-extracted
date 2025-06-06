package Dancer2::Template::Simple;
# ABSTRACT: Pure Perl 5 template engine for Dancer2
$Dancer2::Template::Simple::VERSION = '1.1.2';
use Moo;
use Dancer2::FileUtils 'read_file_content';
use Ref::Util qw<is_arrayref is_coderef is_plain_hashref>;

with 'Dancer2::Core::Role::Template';

has start_tag => (
    is      => 'rw',
    default => sub {'<%'},
);

has stop_tag => (
    is      => 'rw',
    default => sub {'%>'},
);

sub BUILD {
    my $self     = shift;
    my $settings = $self->config;

    $settings->{$_} and $self->$_( $settings->{$_} )
      for qw/ start_tag stop_tag /;
}

sub render {
    my ( $self, $template, $tokens ) = @_;
    my $content;

    $content = read_file_content($template);
    $content = $self->parse_branches( $content, $tokens );

    return $content;
}

sub parse_branches {
    my ( $self, $content, $tokens ) = @_;
    my ( $start, $stop ) = ( $self->start_tag, $self->stop_tag );

    my @buffer;
    my $prefix             = "";
    my $should_bufferize   = 1;
    my $bufferize_if_token = 0;

#    $content =~ s/\Q${start}\E(\S)/${start} $1/sg;
#    $content =~ s/(\S)\Q${stop}\E/$1 ${stop}/sg;

    # we get here a list of tokens without the start/stop tags
    my @full = split( /\Q$start\E\s*(.*?)\s*\Q$stop\E/, $content );

    # and here a list of tokens without variables
    my @flat = split( /\Q$start\E\s*.*?\s*\Q$stop\E/, $content );

    # eg: for 'foo=<% var %>'
    #   @full = ('foo=', 'var')
    #   @flat = ('foo=')

    my $flat_index = 0;
    my $full_index = 0;
    for my $word (@full) {

        # flat word, nothing to do
        if ( defined $flat[$flat_index]
            && ( $flat[$flat_index] eq $full[$full_index] ) )
        {
            push @buffer, $word if $should_bufferize;
            $flat_index++;
            $full_index++;
            next;
        }

        my @to_parse = ($word);
        @to_parse = split( /\s+/, $word ) if $word =~ /\s+/;

        for my $w (@to_parse) {

            if ( $w eq 'if' ) {
                $bufferize_if_token = 1;
            }
            elsif ( $w eq 'else' ) {
                $should_bufferize = !$should_bufferize;
            }
            elsif ( $w eq 'end' ) {
                $should_bufferize = 1;
            }
            elsif ($bufferize_if_token) {
                my $bool = _find_value_from_token_name( $w, $tokens );
                $should_bufferize = _interpolate_value($bool) ? 1 : 0;
                $bufferize_if_token = 0;
            }
            elsif ($should_bufferize) {
                my $val =
                  _interpolate_value(
                    _find_value_from_token_name( $w, $tokens ) );
                push @buffer, $val;
            }
        }

        $full_index++;
    }

    return join "", @buffer;
}


sub _find_value_from_token_name {
    my ( $key, $tokens ) = @_;
    my $value = undef;

    my @elements = split /\./, $key;
    foreach my $e (@elements) {
        if ( not defined $value ) {
            $value = $tokens->{$e};
        }
        elsif ( is_plain_hashref($value) ) {
            $value = $value->{$e};
        }
        elsif ( ref($value) ) {
            local $@;
            eval { $value = $value->$e };
            $value = "" if $@;
        }
    }
    return $value;
}

sub _interpolate_value {
    my ($value) = @_;
    if ( is_coderef($value) ) {
        local $@;
        eval { $value = $value->() };
        $value = "" if $@;
    }
    elsif ( is_arrayref($value) ) {
        $value = "@{$value}";
    }

    $value = "" if not defined $value;
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Template::Simple - Pure Perl 5 template engine for Dancer2

=head1 VERSION

version 1.1.2

=head1 SYNOPSIS

To use this engine, you may configure L<Dancer2> via C<config.yaml>:

    template: simple

=head1 DESCRIPTION

This template engine is primarily to serve as a migration path for users of 
L<Dancer>. It should be fine for development purposes, but you would be 
better served by using L<Dancer2::Template::TemplateToolkit> or one of the
many alternatives available on CPAN to power an application with Dancer2 
in production environment. 

C<Dancer2::Template::Simple> is written in pure Perl and has no C bindings 
to accelerate the template processing.

=head1 METHODS

=head2 render($template, \%tokens)

Renders the template.  The first arg is a filename for the template file
or a reference to a string that contains the template.  The second arg
is a hashref for the tokens that you wish to pass to
L<Template::Toolkit> for rendering.

=head1 SYNTAX

A template written for C<Dancer2::Template::Simple> should be working just fine
with L<Dancer2::Template::TemplateToolkit>. The opposite is not true though.

=over 4

=item B<variables>

To interpolate a variable in the template, use the following syntax:

    <% var1 %>

If B<var1> exists in the tokens hash given, its value will be written there.

=back

=head1 SEE ALSO

L<Dancer2>, L<Dancer2::Core::Role::Template>,
L<Dancer2::Template::TemplateToolkit>.

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
