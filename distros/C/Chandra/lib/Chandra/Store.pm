package Chandra::Store;

use strict;
use warnings;

# Load XS functions from Chandra bootstrap
use Chandra ();

our $VERSION = '0.23';

1;

__END__

=head1 NAME

Chandra::Store - Persistent key-value storage for Chandra apps

=head1 SYNOPSIS

    use Chandra::Store;

    my $store = Chandra::Store->new(name => 'myapp');

    $store->set('theme', 'dark');
    my $theme = $store->get('theme');               # 'dark'
    my $val   = $store->get('missing', 'default');  # 'default'

    $store->set('window.width', 800);
    $store->set('window.height', 600);
    my $w      = $store->get('window.width');       # 800
    my $window = $store->get('window');             # { width => 800, height => 600 }

    $store->has('theme');                           # 1
    $store->delete('theme');

    $store->set_many({
        'ui.font_size' => 14,
        'ui.sidebar'   => 1,
        'recent_files' => ['/path/a', '/path/b'],
    });

    my $all = $store->all;
    $store->clear;

    # Manual save mode — batch multiple writes into one disk write
    my $s = Chandra::Store->new(name => 'myapp', auto_save => 0);
    $s->set('x', 1)->set('y', 2)->set('z', 3);
    $s->save;

    # Reload picks up external changes
    $s->reload;

    # Via Chandra::App
    my $app = Chandra::App->new(title => 'My App', ...);
    my $store = $app->store;     # name derived from app title

=head1 DESCRIPTION

Chandra::Store provides persistent key-value storage for Chandra desktop
applications, backed by a JSON file at C<~/.chandra/E<lt>nameE<gt>/store.json>
by default.

Keys support dot notation for nested structures (e.g. C<window.width>).
Writes are atomic: data is written to a C<.tmp.PID> file then renamed into
place. File locking (flock) prevents corruption from concurrent processes.

=head1 METHODS

=head2 new(%args)

    Chandra::Store->new(name => 'myapp')
    Chandra::Store->new(path => '/explicit/path/store.json')
    Chandra::Store->new(name => 'myapp', auto_save => 0)

Either C<name> or C<path> is required. C<name> stores the file at
C<~/.chandra/E<lt>nameE<gt>/store.json>. Parent directories are created
automatically.

C<auto_save> defaults to 1. When enabled, every mutating call (C<set>,
C<delete>, C<set_many>, C<clear>) triggers an immediate disk write.

=head2 get($key [, $default])

Return the value for C<$key>. Supports dot notation to reach nested
values. Returns C<$default> (or C<undef>) if the key does not exist.

=head2 set($key, $value)

Set C<$key> to C<$value>. Dot notation creates intermediate hashes as
needed. Croaks if an intermediate segment exists but is not a hash.
Returns C<$self> for chaining.

=head2 has($key)

Returns 1 if C<$key> exists, 0 otherwise. Supports dot notation.

=head2 delete($key)

Delete C<$key>. Supports dot notation; sibling keys are unaffected.
Returns C<$self>.

=head2 set_many(\%pairs)

Set multiple keys in a single call. When C<auto_save> is on, writes to
disk once after all keys are set rather than once per key. Returns C<$self>.

=head2 all()

Returns a reference to the internal data hash (not a copy). Top-level
keys only; nested structures are hashrefs.

=head2 clear()

Remove all keys. Writes C<{}> to disk if C<auto_save> is on. Returns C<$self>.

=head2 save()

Write the current in-memory state to disk. Use with C<auto_save => 0> for
manual control over when writes occur. Returns C<$self>.

=head2 reload()

Re-read the store file from disk, replacing in-memory state. Useful when
another process may have modified the file. Returns C<$self>.

=head2 path()

Returns the absolute path to the backing JSON file.

=head2 auto_save([$bool])

Getter/setter for the C<auto_save> flag. With no argument returns the
current value. With an argument sets it and returns C<$self>.

=head1 SEE ALSO

L<Chandra>, L<Chandra::App>

=cut
