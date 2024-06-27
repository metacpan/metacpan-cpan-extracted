package Aozora2Epub::File;
use strict;
use warnings;
use utf8;
use Aozora2Epub::Gensym;
use HTML::Element;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw/content name/);

our $VERSION = '0.04';

sub new {
    my ($class, $content) = @_;
    return bless {
        name => gensym,
        content => $content,
    }, $class;
}

sub _to_html {
    my $e = shift;
    unless ($e->isa('HTML::Element')) {
        return $e;
    }
    return $e->as_HTML('<>&', undef, {});
}

sub as_html {
    my $self = shift;
    return join('', map { _to_html($_) } @{$self->{content}});
}

sub insert_content {
    my ($self, @c) = @_;
    unshift @{$self->{content}}, @c;
}

1;

__END__
