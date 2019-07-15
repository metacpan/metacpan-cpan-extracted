package Bot::IRC::Store;
# ABSTRACT: Bot::IRC persistent data storage with YAML

use 5.012;
use strict;
use warnings;

use YAML::XS qw( LoadFile DumpFile );

our $VERSION = '1.24'; # VERSION

sub init {
    my ($bot) = @_;
    my $obj = __PACKAGE__->new($bot);

    $bot->subs( 'store' => sub { return $obj } );
}

sub new {
    my ( $class, $bot ) = @_;
    my $self = bless( {}, $class );

    $self->{file} = $bot->vars || 'store.yaml';

    eval {
        unless ( -f $self->{file} ) {
            DumpFile( $self->{file}, {} );
        }
        else {
            LoadFile( $self->{file} );
        }
    };
    die qq{Unable to use "$self->{file}" for YAML storage in the Bot::IRC::Store plugin\n} if ($@);

    return $self;
}

sub get {
    my ( $self, $key ) = @_;
    return LoadFile( $self->{file} )->{ ( caller() )[0] }{$key};
}

sub set {
    my ( $self, $key, $value ) = @_;

    my $data = LoadFile( $self->{file} );
    $data->{ ( caller() )[0] }{$key} = $value;

    DumpFile( $self->{file}, $data );
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::Store - Bot::IRC persistent data storage with YAML

=head1 VERSION

version 1.24

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Store'],
        vars    => { store => 'bot.yaml' },
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin provides a very simple persistent storage mechanism. It
stores all its data in a single YAML file. This makes things easy when you're
dealing with a small amount of data, but performance will get increasingly bad
as data increases. Consequently, you should probably not use this module
specifically in a long-running production bot. Instead, use some Storage
pseudo sub-class like L<Bot::IRC::Store::SQLite>.

=head1 EXAMPLE USE

This plugin adds a single sub to the bot object called C<store()>. Calling it
will return a storage object which itself provides C<get()> and C<set()>
methods. These operate just like you would expect.

=head2 set

    $bot->store->set( user => { nick => 'gryphon', score => 42 } );

=head2 get

    my $score = $bot->store->get('user')->{score};

=head1 PSEUDO SUB-CLASSES

Pseudo sub-classes of Bot::IRC::Store should implement the same interface
as this plugin. Also, they should call C<register()> to ensure plugins that
require storage don't clobber the C<store()> of whatever pseudo sub-class
is used.

    $bot->register('Bot::IRC::Store');

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init new

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
