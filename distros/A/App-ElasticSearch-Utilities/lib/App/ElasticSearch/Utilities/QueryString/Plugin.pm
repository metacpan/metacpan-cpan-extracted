package App::ElasticSearch::Utilities::QueryString::Plugin;
# ABSTRACT: Moo::Role for implementing QueryString Plugins

use Hash::Merge::Simple qw(clone_merge);
use Moo::Role;
use Sub::Quote;



requires qw(handle_token);

# Attributes
has name => (
    is => 'ro',
    isa => quote_sub(q{die "Needs to be a string" if ref $_[0]}),
    builder => '_build_name',
    lazy => 1,
);
has priority => (
    is      => 'ro',
    isa     => quote_sub(q{die "Not between 1 and 100" unless $_[0] > 0 && $_[0] <= 100 }),
    builder => '_build_priority',
    lazy    => 1,
);

around 'handle_token' => sub {
    my $orig = shift;
    my $self = shift;
    my $refs = $orig->($self,@_);
    if( defined $refs ) {
        if( ref $refs eq 'ARRAY' ) {
            foreach my $doc (@{ $refs }) {
                $doc->{_by} = $self->name;
            }
        }
        elsif( ref $refs eq 'HASH' ) {
            $refs->{_by} = $self->name;
        }
        return $refs;
    }
    else {
        return;
    }
};

# Builders
sub _build_name {
    my $self = shift;
    my $class = ref $self;
    return (split /::/, $class)[-1];
}
sub _build_priority { 50; }

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

=encoding UTF-8

=head1 NAME

App::ElasticSearch::Utilities::QueryString::Plugin - Moo::Role for implementing QueryString Plugins

=head1 VERSION

version 5.3

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

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
