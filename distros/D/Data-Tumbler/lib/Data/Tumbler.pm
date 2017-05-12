package Data::Tumbler;

use strict;
use warnings;

=head1 NAME

Data::Tumbler - Dynamic generation of nested combinations of variants

=head1 SYNOPSIS

    $tumbler = Data::Tumbler->new(

        add_path => sub {
            my ($path, $name) = @_;
            return [ @$path, $name ];
        },

        add_context => sub {
            my ($context, $value) = @_;
            return [ @$context, $value ]
        },

        consumer  => sub {
            my ($path, $context, $payload) = @_;
            print "@$path: @$context\n";
        },
    );

    $tumbler->tumble(
        [   # provider code refs
            sub { (red => 42, green => 24, mauve => 19) },
            sub { (circle => 1, square => 2) },
            # ...
        ],
        [], # initial path
        [], # initial context
        [], # initial payload
    );

The consumer code outputs:

    green circle: 24 1
    green square: 24 2
    mauve circle: 19 1
    mauve square: 19 2
    red circle: 42 1
    red square: 42 2

Here's a longer example showing more features:

    use List::Util qw(sum);

    $tumbler = Data::Tumbler->new(

        # The default add_path is as shown above
        # The default add_context is as shown above

        consumer  => sub {
            my ($path, $context, $payload) = @_;
            printf "path: %-20s  context: %-12s  payload: %s\n",
                join("/",  @$path),
                join(", ", @$context),
                join(", ", map { "$_=>$payload->{$_}" } sort keys %$payload);
        },
    );

    $tumbler->tumble(
        [   # providers
            sub {
                my ($path, $context, $payload) = @_;

                my %variants = (red => 42, green => 24, mauve => 19);

                return %variants;
            },
            sub {
                my ($path, $context, $payload) = @_;

                # change paint to matt based on context
                $payload->{paint} = 'matt' if sum(@$context) > 20;

                my %variants = (circle => 10, square => 20);

                # add an extra triangular variant for mauve
                $variants{triangle} = 13 if grep { $_ eq 'mauve' } @$path;

                return %variants;
            },
            sub {
                my ($path, $context, $payload) = @_;

                # skip all variants if path contains anything red or circular
                return if grep { $_ eq 'red' or $_ eq 'circle' } @$path;

                $payload->{spotty} = 1 if sum(@$context) > 35;

                my %variants = (small => 17, large => 92);

                return %variants;
            },
            # ...
        ],
        [], # initial path
        [], # initial context
        { paint => 'gloss' }, # initial payload
    );

The consumer code outputs:

    path: green/square/large    context: 24, 20, 92    payload: paint=>matt, spotty=>1
    path: green/square/small    context: 24, 20, 17    payload: paint=>matt, spotty=>1
    path: mauve/square/large    context: 19, 20, 92    payload: paint=>gloss, spotty=>1
    path: mauve/square/small    context: 19, 20, 17    payload: paint=>gloss, spotty=>1
    path: mauve/triangle/large  context: 19, 13, 92    payload: paint=>gloss
    path: mauve/triangle/small  context: 19, 13, 17    payload: paint=>gloss

=head1 DESCRIPTION

NOTE: This is alpha code and liable to change while it and L<Test::WriteVariants>
mature.

The tumble() method calls a sequence of 'provider' code references each of
which returns a hash.  The first provider is called and then, for each hash
item it returns, the tumble() method recurses to call the next provider.

The recursion continues until there are no more providers to call, at which
point the consumer code reference is called.  Effectively the providers create
a tree of combinations and the consumer is called at the leafs of the tree.

If a provider returns no items then that part of the tree is pruned. Further
providers, if any, are not called and the consumer is not called.

During a call to tumble() three values are passed down through the tree and
into the consumer: path, context, and payload.

The path and context are derived from the names and values of the hashes
returned by the providers. Typically the path define the current "path"
through the tree of combinations.

The providers are passed the current path, context, and payload.
The payload is cloned at each level of recursion so that any changes made to it
by providers are only visible within the scope of the generated sub-tree.

Note that although the example above shows the path, context and payload as
array references, the tumbler code makes no assumptions about them. They can be
any kinds of values.

See L<Test::WriteVariants> for a practical example use.

=head1 ATTRIBUTES

=head2 consumer

    $tumbler->consumer( sub { my ($path, $context, $payload) = @_; ... } );

Defines the code reference to call at the leafs of the generated tree of combinations.
The default is to throw an exception.

=head2 add_path

    $tumbler->add_path( sub { my ($path, $name) = @_; return [ @$path, $name ] } )

Defines the code reference to call to create a new path value that combines
the existing path and the new name. The default is shown in the example above.


=head2 add_context

    $tumbler->add_context( sub { my ($context, $value) = @_; return [ @$context, $value ] } )

Defines the code reference to call to create a new context value that combines
the existing context and the new value. The default is shown in the example above.

=cut

use Storable qw(dclone);
use Carp qw(confess);

our $VERSION = '0.010';

=head1 METHODS

=head2 new

Contructs new Data::Tumbler, deals with initial values for L</ATTRIBUTES>.

=cut

sub new {
    my ($class, %args) = @_;

    my %defaults = (
        consumer    => sub { confess "No Data::Tumbler consumer defined" },
        add_path    => sub { my ($path,    $name ) = @_; return [ @$path,    $name  ] },
        add_context => sub { my ($context, $value) = @_; return [ @$context, $value ] },
    );
    my $self = bless \%defaults => $class;

    for my $attribute (qw(consumer add_path add_context)) {
        next unless exists $args{$attribute};
        $self->$attribute(delete $args{$attribute});
    }
    confess "Unknown $class arguments: @{[ keys %args ]}"
        if %args;

    return $self;
}


sub consumer {
    my $self = shift;
    $self->{consumer} = shift if @_;
    return $self->{consumer};
}

sub add_path {
    my $self = shift;
    $self->{add_path} = shift if @_;
    return $self->{add_path};
}

sub add_context {
    my $self = shift;
    $self->{add_context} = shift if @_;
    return $self->{add_context};
}

=head2 tumble

Tumbles providers to compute variants.

=cut

sub tumble {
    my ($self, $providers, $path, $context, $payload) = @_;

    if (not @$providers) { # no more providers in this context
        $self->consumer->($path, $context, $payload);
        return;
    }

    # clone the $payload so the provider can alter it for the consumer
    # at and below this point in the tree of variants
    $payload = dclone($payload) if ref $payload;

    my ($current_provider, @remaining_providers) = @$providers;

    # call the current provider to supply the variants for this context
    # returns empty if the consumer shouldn't be called in the current context
    # returns a single (possibly nil/empty/dummy) variant if there are
    # no actual variations needed.
    my %variants = $current_provider->($path, $context, $payload);

    # for each variant in turn, call the next level of provider
    # with the name and value of the variant appended to the
    # path and context.

    for my $name (sort keys %variants) {

        $self->tumble(
            \@remaining_providers,
            $self->add_path->($path,  $name),
            $self->add_context->($context, $variants{$name}),
            $payload,
        );
    }

    return;
}

1;

__END__

=head1 BUGS

Please report any bugs or feature requests to
C<bug-Data-Tumbler at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Tumbler>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Tumbler

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Tumbler>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Tumbler>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Tumbler>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Tumbler/>

=back

=head1 AUTHOR

Tim Bunce, C<< <timb at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

This module has been created to support DBI::Test in design and separation
of concerns.

=head1 COPYRIGHT

Copyright 2014-2015 Tim Bunce and Perl5 DBI Team.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either:

        a) the GNU General Public License as published by the Free
        Software Foundation; either version 1, or (at your option) any
        later version, or

        b) the "Artistic License" which comes with this Kit.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

=cut
