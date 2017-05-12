package Acme::MetaSyntactic::List;
use strict;
use Acme::MetaSyntactic (); # do not export metaname and friends
use Acme::MetaSyntactic::RemoteList;
use List::Util qw( shuffle );
use Carp;

our @ISA = qw( Acme::MetaSyntactic::RemoteList );
our $VERSION = '1.001';

sub init {
    my ($self, $data) = @_;
    my $class = caller(0);

    $data ||= Acme::MetaSyntactic->load_data($class);
    croak "The optional argument to init() must be a hash reference"
      if ref $data ne 'HASH';

    no strict 'refs';
    no warnings;
    ${"$class\::Theme"} = ( split /::/, $class )[-1];
    @{"$class\::List"}  = do { my %seen;
         grep !$seen{$_}++, split /\s+/, $data->{names} };
    *{"$class\::import"} = sub {
        my $callpkg = caller(0);
        my $theme   = ${"$class\::Theme"};
        my $meta    = $class->new();
        *{"$callpkg\::meta$theme"} = sub { $meta->name(@_) };
      };
    ${"$class\::meta"} = $class->new();
}

sub name {
    my ( $self, $count ) = @_;
    my $class = ref $self;

    if( ! $class ) { # called as a class method!
        $class = $self;
        no strict 'refs';
        $self = ${"$class\::meta"};
    }

    if( defined $count && $count == 0 ) {
        no strict 'refs';
        return
          wantarray ? shuffle @{"$class\::List"} : scalar @{"$class\::List"};
    }

    $count ||= 1;
    my $list = $self->{cache};
    {
      no strict 'refs';
      if (@{"$class\::List"}) {
          push @$list, shuffle @{"$class\::List"} while @$list < $count;
      }
    }
    splice( @$list, 0, $count );
}

sub new {
    my $class = shift;

    bless { cache => [] }, $class;
}

sub theme {
    my $class = ref $_[0] || $_[0];
    no strict 'refs';
    return ${"$class\::Theme"};
}

1;

__END__

=head1 NAME

Acme::MetaSyntactic::List - Base class for simple lists of names

=head1 SYNOPSIS

    package Acme::MetaSyntactic::beatles;
    use Acme::MetaSyntactic::List;
    our @ISA = ( Acme::MetaSyntactic::List );
    __PACKAGE__->init();
    1;

    =head1 NAME
    
    Acme::MetaSyntactic::beatles - The fab four theme
    
    =head1 DESCRIPTION
    
    Ladies and gentlemen, I<The Beatles>. I<(hysteric cries)>

    =cut
    
    __DATA__
    # names
    john paul
    george ringo

=head1 DESCRIPTION

C<Acme::MetaSyntactic::List> is the base class for all themes that are
meant to return a random excerpt from a predefined list.

=head1 METHOD

Acme::MetaSyntactic::List offers several methods, so that the subclasses
are easy to write (see full example in L<SYNOPSIS>):

=over 4

=item new()

The constructor of a single instance. An instance will not repeat items
until the list is exhausted.

=item init()

init() must be called when the subclass is loaded, so as to read the
__DATA__ section and fully initialise it.

=item name( $count )

Return $count names (default: C<1>).

Using C<0> will return the whole list in list context, and the size of the
list in scalar context.

=item theme()

Return the theme name.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>

=head1 COPYRIGHT

Copyright 2005-2012 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

