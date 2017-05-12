package Data::Phrasebook::Loader;
use strict;
use warnings FATAL => 'all';
use base qw( Data::Phrasebook::Debug );
use Carp qw( croak );

use Module::Pluggable   search_path => ['Data::Phrasebook::Loader'];

use vars qw($VERSION);
$VERSION = '0.35';

=head1 NAME

Data::Phrasebook::Loader - Plugin Loader module

=head1 SYNOPSIS

  my $loader = Data::Phrasebook::Loader->new( class => 'Text' );

=head1 DESCRIPTION

C<Data::Phrasebook::Loader> acts as an autoloader for phrasebook plugins.

=head1 CONSTRUCTOR

=head2 new

C<new> takes one optional named argument: the class. It returns a new
instance to the class. Any further arguments to C<new> are given to
the C<new> method of the appropriate class.

If no class is specified the default class of 'Text' is used.

  my $loader = Data::Phrasebook::Loader->new();

  OR

  my $loader = Data::Phrasebook::Loader->new( class => 'Text' );

=cut

my $DEFAULT_CLASS = 'Text';

sub new {
    my $self  = shift;
    my %args  = @_;
    my $class = delete $args{class} || 'Text';

    if($self->debug) {
		$self->store(3,"$self->new IN");
		$self->store(4,"$self->new class=[$class]");
	}

    # in the event we have been subclassed
    $self->search_path( add => "$self" );

    my $plugin;
    my @plugins = $self->plugins();
    for(@plugins) {
        $plugin = $_    if($_ =~ /\b$class$/);
    }

    croak("no loader available of that name\n") unless($plugin);

    eval {
        (my $file = $plugin) =~ s|::|/|g;
        require $file . '.pm';
        $plugin->import();
        1;
    } or do {
        croak "Couldn't require $plugin : $@";
    };

    $self->store(4,"$self->new plugin=[$plugin]")	if($self->debug);
    return $plugin->new( %args );
}

1;

__END__

=head1 SEE ALSO

L<Data::Phrasebook>.

=head2 Known implementations

L<Data::Phrasebook::Loader::Text>,
L<Data::Phrasebook::Loader::YAML>,
L<Data::Phrasebook::Loader::Ini>,
L<Data::Phrasebook::Loader::XML>,
L<Data::Phrasebook::Loader::DBI>.

=head1 SUPPORT

Please see the README file.

=head1 AUTHOR

  Original author: Iain Campbell Truskett (16.07.1979 - 29.12.2003)
  Maintainer: Barbie <barbie@cpan.org> since January 2004.
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003 Iain Truskett.
  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
