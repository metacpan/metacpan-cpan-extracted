package App::Cerberus::Plugin;
$App::Cerberus::Plugin::VERSION = '0.11';
use strict;
use warnings;
use Carp;

#===================================
sub new {
#===================================
    my $class = shift;
    my $self = bless {}, $class;
    $self->init(@_);
    return $self;
}

#===================================
sub init { }
#===================================

#===================================
sub request {
#===================================
    my $self = shift;
    croak "The request() must be overriden in: " . ref $self;
}

1;

# ABSTRACT: A base class for App::Cerberus plugins

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cerberus::Plugin - A base class for App::Cerberus plugins

=head1 VERSION

version 0.11

=head1 DESCRIPTION

If you want to write a plugin for L<App::Cerberus> then you must provide
a C<request> method, which accepts a L<Plack::Request> object as its first
argument, and a C<\%response> hashref as its second.

    package App::Cerberus::Plugin::Foo;

    use parent 'App::Cerberus::Plugin';

    sub request {
        my ($self, $request, $response) = @_;

        $response->{foo} = {.....};

    }

Optionally, you can also add an C<init> method, which will be called with
any options that were specified in the config file:

    sub init {
        my ($self,@args) = @_;
        ...
    }

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
