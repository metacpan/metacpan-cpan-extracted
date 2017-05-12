package DSL::HTML::Rendering;
use strict;
use warnings;

use HTML::Element;

use Scalar::Util qw/blessed/;

use Carp qw/croak confess/;
our @CARP_NOT = qw/DSL::HTML DSL::HTML::Template/;

sub template  { shift->{template}  }
sub head      { shift->{head}      }
sub body      { shift->{body}      }
sub root      { shift->{root}      }
sub tag_stack { shift->{tag_stack} }
sub css_seen  { shift->{css_seen}  }
sub js_seen   { shift->{js_seen}   }
sub css_ref   { shift->{css_ref}   }
sub js_ref    { shift->{js_ref}    }

my @STACK;
sub current {
    return $STACK[-1];
}

sub new {
    my $class = shift;
    my ( $template ) = @_;

    my $html = HTML::Element->new('html');
    my $body = HTML::Element->new('body');
    my $head = HTML::Element->new('head');

    return bless {
        template  => $template,
        tag_stack => [$html, $body],
        head      => $head,
        body      => $body,
        root      => $html,
        css_ref   => [],
        js_ref    => [],
        css_seen  => {},
        js_seen   => {},
    }, $class;
}

sub args {
    my $self = shift;
    $self->{args} = [@_] if @_;
    return unless $self->{args};
    return @{$self->{args}};
}

sub compile {
    my $self = shift;
    my (@args) = @_;

    $self->build(@args);
    return $self->as_html;
}

sub include {
    my $self = shift;
    my ($tmp, @args) = @_;

    my $sub_render = bless {
        %$self,
        template => $tmp,
    }, blessed($self);

    $sub_render->build(@args);

    return;
}

sub build {
    my $self = shift;
    my (@args) = @_;

    $self->args(@args);

    push @STACK => $self;
    my $success = eval {
        $self->template->block->($self->peek_tag, @args);
        1;
    };
    my $error = $@;
    pop @STACK;
    die $error unless $success;
}

sub as_html {
    my $self = shift;

    my $head = $self->head;
    my $body = $self->body;
    my $html = $self->root;

    for my $css ($self->css_list) {
        my $tag = HTML::Element->new(
            link => (
                rel  => 'stylesheet',
                type => 'text/css',
                href => $css,
            )
        );
        $head->push_content($tag);
    }

    $html->push_content(
        $head,
        $body,
        map {  HTML::Element->new( script => ( src => $_ )) } $self->js_list,
    );

    return $html->as_HTML(undef, $self->template->indent);
}

sub insert {
    my $self = shift;
    $self->peek_tag->push_content(@_);
}

sub push_tag {
    my $self = shift;
    my ($tag) = @_;
    push @{$self->tag_stack} => $tag;
}

sub pop_tag {
    my $self = shift;
    my ($want) = @_;
    my $got = pop @{$self->tag_stack};
    confess "Corrupt stack detected! popped the wrong tag!"
        unless $got == $want;
}

sub peek_tag {
    my $self = shift;
    return $self->tag_stack->[-1];
}

sub js_list {
    my $self = shift;
    return @{ $self->js_ref };
}

sub css_list {
    my $self = shift;
    return @{ $self->css_ref };
}

sub add_css {
    my $self = shift;
    my $seen = $self->css_seen;
    my $ref  = $self->css_ref;
    for my $file ( @_ ) {
        next if $seen->{$file}++;
        push @$ref => $file;
    }
}

sub add_js {
    my $self = shift;
    my $seen = $self->js_seen;
    my $ref  = $self->js_ref;
    for my $file ( @_ ) {
        next if $seen->{$file}++;
        push @$ref => $file;
    }
}

1;

__END__

=head1 NAME

DSL::HTML::Rendering - Used internally by L<DSL::HTML>

=head1 NOTES

You should never need to construct this yourself.

=head1 METHODS

=over 4

=item template 

=item head     

=item body     

=item tag_stack

=item css_seen 

=item js_seen  

=item css_ref  

=item js_ref   

=item current

=item args

=item compile

=item include

=item build

=item as_html

=item build_head

=item insert

=item push_tag

=item pop_tag

=item peek_tag

=item js_list

=item css_list

=item add_css

=item add_js

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

DSL-HTML is free software; Standard perl license (GPL and Artistic).

DSL-HTML is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
