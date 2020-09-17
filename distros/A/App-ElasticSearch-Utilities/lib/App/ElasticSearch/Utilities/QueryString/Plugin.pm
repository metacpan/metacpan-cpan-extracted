package App::ElasticSearch::Utilities::QueryString::Plugin;
# ABSTRACT: Moo::Role for implementing QueryString Plugins

use strict;
use warnings;

our $VERSION = '7.8'; # VERSION

use Hash::Merge::Simple qw(clone_merge);
use Moo::Role;
use Ref::Util qw(is_arrayref is_hashref);
use Types::Standard qw( Str Int );


# Attributes
has name => (
    is  => 'lazy',
    isa => Str,
);
sub _build_name {
    my $self = shift;
    my $class = ref $self;
    return (split /::/, $class)[-1];
}


has priority => (
    is  => 'lazy',
    isa => Int,
);
sub _build_priority { 50; }


requires qw(handle_token);

around 'handle_token' => sub {
    my $orig = shift;
    my $self = shift;
    my $refs = $orig->($self,@_);
    if( defined $refs ) {
        if( is_arrayref($refs) ) {
            foreach my $doc (@{ $refs }) {
                $doc->{_by} = $self->name;
            }
        }
        elsif( is_hashref($refs) ) {
            $refs->{_by} = $self->name;
        }
        return $refs;
    }
    else {
        return;
    }
};


# Handle Build Args


sub BUILDARGS {
    my($class,%in) = @_;

    my @search = map { $_ => lc $_ } ($class,(split /::/, $class)[-1]);
    my $options = exists $in{options} ? delete $in{options} : {};

    my @options = ();
    foreach my $s (@search) {
        if( exists $options->{$s} ) {
            push @options, $options->{$s};
            last;
        }
    }
    push @options, \%in if keys %in;

    return scalar(@options) ? clone_merge(@options) : {};
}

1;

__END__

=pod

=head1 NAME

App::ElasticSearch::Utilities::QueryString::Plugin - Moo::Role for implementing QueryString Plugins

=head1 VERSION

version 7.8

=head1 ATTRIBUTES

=head2 name

Name of the plugin, used in debug reporting.

=head2 priority

Priority is an integer which determmines the order tokens are parsed in
low->high order.

=head1 INTERFACE

=head2 handle_token()

The handle_token() routine receives a single token from the command line, often a single word
and returns a hash reference specifying

The token expansion plugins can return undefined, which is basically a noop on the token.
The plugin can return a hash reference, which marks that token as handled and no other plugins
receive that token.  The hash reference may contain:

=head2 query_string

This is the rewritten bits that will be reassembled in to the final query string.

=head2 condition

This is usually a hash reference representing the condition going into the bool query. For instance:

    { terms => { field => [qw(alice bob charlie)] } }

Or

    { prefix => { user_agent => 'Go ' } }

These conditions will wind up in the B<must> or B<must_not> section of the B<bool> query depending on the
state of the the invert flag.

=head2 invert

This is used by the bareword "not" to track whether the token invoked a flip from the B<must> to the B<must_not>
state.  After each token is processed, if it didn't set this flag, the flag is reset.

=head2 dangles

This is used for bare words like "not", "or", and "and" to denote that these terms cannot dangle from the
beginning or end of the query_string.  This allows the final pass of the query_string builder to strip these
words to prevent syntax errors.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
