package Cache::Swifty;

use strict;
use warnings;
use Storable qw/nfreeze thaw/;

require Exporter;

our @ISA = qw/Exporter/;

our %EXPORT_TAGS = (
    'all'   => [
        qw/swifty_err swifty_adler32 swifty_new swifty_get swifty_set/,
    ],
);
our @EXPORT_OK = (
    @{$EXPORT_TAGS{'all'}},
);
our @EXPORT = qw();

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('Cache::Swifty', $VERSION);

sub FLAGS_USE_CHECKSUM () { 1 }

sub SWIFTY        () { 0 }
sub HASH_CALLBACK () { 1 }

sub new {
    my ($class, $opts) = @_;
    $class = ref($class) || $class;
    my $self = bless [
        swifty_new(
            $opts->{dir},
            $opts->{lifetime} || 3600,
            $opts->{refresh_before} || 0,
            $opts->{flags} || 0,
        ),
        $opts->{hash_callback} || undef,
    ], $class;
    die 'failed to open swifty cache (' . swifty_err() . ")\n"
        unless $self->[SWIFTY];
    $self;
}

sub DESTROY {
    my $self = shift;
    if ($self->[SWIFTY]) {
        swifty_free($self->[SWIFTY]);
        $self->[SWIFTY] = undef;
    }
}

sub get {
    no warnings;
    my ($self, $key) = @_;
    my $value = swifty_get(
        $self->[SWIFTY],
        $self->[HASH_CALLBACK] ? $self->[HASH_CALLBACK]->($key) : 0xffffffff,
        $key,
    );
    return $value unless $value =~ /^\0/;
    thaw substr($value, 1);
}

sub set {
    my ($self, $key, $value, $expires) = @_;
    $value = "\0" . nfreeze($value) if ref $value;
    swifty_set(
        $self->[SWIFTY],
        $self->[HASH_CALLBACK] ? $self->[HASH_CALLBACK]->($key) : 0xffffffff,
        $key,
        $value,
        $expires || 0,
    ) == 0;
}

sub lifetime {
    my $self = shift;
    swifty_set_lifetime($self->[SWIFTY], shift) if @_;
    swifty_get_lifetime($self->[SWIFTY]);
}

sub refresh_before {
    my $self = shift;
    swifty_set_refresh_before($self->[SWIFTY], shift) if @_;
    swifty_get_refresh_before($self->[SWIFTY]);
}

sub do_refresh {
    my $self = shift;
    swifty_do_refresh($self->[SWIFTY]);
}

sub flags {
    my $self = shift;
    swifty_set_flags($self->[SWIFTY], shift) if @_;
    swifty_get_flags($self->[SWIFTY]);
}

1;

__END__

=head1 NAME

Cache::Swifty - A Perl frontend for the Swifty cache engine

=head1 SYNOPSIS

  use Cache::Swifty;
  
  my $cache = Cache::Swifty->new({
    dir => 'path_to_cache_dir',
  });
  
  $cache->set('key', 'value');
  my $value = $cache->get('key');

=head1 DESCRIPTION

C<Cache::Swifty> is a perl frontend for the Swifty cache engine.  For more information, please refer to http://labs.cybozu.co.jp/blog/kazuhoatwork/swifty/.

=head1 THE CONSTRUCTOR

The following parameters are recognized by the C<new> function.

=head2 dir

Required.  Cache directory to be used.  The directory must be initialized prior to calling the method by using the swifty command line tool.

=head2 hash_callback

Optional.  Reference to a hash function taking a scalar and its length as arguments.  If omitted, L<Cache::Swifty> will use its internal adler32 function for hash calculation.

=head2 lifetime

Optional.  Lifetime of cached entries in seconds.  Defaults to 3600 if omitted.

=head2 refresh_before

Optional.

=head2 flags

Optional.

=head1 FLAGS

Cache::Swifty supports following flags.  The flags can be set at initialization by using the constructor.  It is also possible to adjust the flags laterwards by calling the C<flags> accessor.

=head2 FLAGS_USE_CHECKSUM

Flag to activate / disactivate internal checksum for data integrity.

=head1 METHODS

=head2 get(key)

Returns cached value or undef if not found.

=head2 set(key, value[, expires])

Sets given key,value pair.  Only scalar variables can be stored.

=head2 lifetime([ new_lifetime ])

Accessor for default lifetime.

=head2 refresh_before([ new_refresh_before ])

Accessor for the forwarded refresh notifier (set in seconds).

=head2 do_refresh()

Returns if the entry should be refreshed.

=head2 flags([ new_flags ])

Accessor for flags.

=head2 swifty_err()

Returns error code of swifty.

=head2 swifty_adler32(scalar)

The default hash function.

=head1 SEE ALSO

http://labs.cybozu.co.jp/blog/kazuhoatwork/swify/

=head1 AUTHOR

Copyright (c) 2007 Cybozu Labs, Inc.  All rights reserved.

written by Kazuho Oku E<lt>kazuhooku@gmail.comE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
