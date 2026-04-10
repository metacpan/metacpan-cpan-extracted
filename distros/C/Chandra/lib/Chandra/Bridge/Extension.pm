package Chandra::Bridge::Extension;

use strict;
use warnings;

our $VERSION = '0.20';

use Chandra ();

1;

__END__

=head1 NAME

Chandra::Bridge::Extension - Register JavaScript extensions for the Chandra bridge

=head1 SYNOPSIS

    use Chandra::Bridge::Extension;

    # Register a JavaScript extension (available as window.chandra.utils)
    Chandra::Bridge::Extension->register('utils', <<'JS');
        return {
            formatDate: function(ts) {
                return new Date(ts * 1000).toLocaleDateString();
            },
            debounce: function(fn, delay) {
                var timer;
                return function() {
                    clearTimeout(timer);
                    var args = arguments;
                    var self = this;
                    timer = setTimeout(function() { fn.apply(self, args); }, delay);
                };
            }
        };
    JS

    # Register with dependencies
    Chandra::Bridge::Extension->register('ui', <<'JS', depends => ['utils']);
        var utils = window.chandra.utils;
        return {
            formatAndShow: function(ts) {
                alert(utils.formatDate(ts));
            }
        };
    JS

    # Register from a file
    Chandra::Bridge::Extension->register_file('charts', 'js/charts.js');

    # Query the registry
    my @names  = Chandra::Bridge::Extension->list;
    my $exists = Chandra::Bridge::Extension->is_registered('utils');
    my $js     = Chandra::Bridge::Extension->source('utils');

    # Remove
    Chandra::Bridge::Extension->unregister('utils');
    Chandra::Bridge::Extension->clear;

=head1 DESCRIPTION

C<Chandra::Bridge::Extension> lets you attach custom JavaScript modules to
the C<window.chandra> bridge object.  Registered extensions survive page
reloads because they are injected as part of the bridge code string.

Each extension is wrapped in an IIFE and assigned to
C<window.chandra.E<lt>nameE<gt>>.  Dependencies are resolved via topological
sort so that an extension's prerequisites are always available when it runs.

=head1 METHODS

=over 4

=item B<register>( $name, $js_source [, depends => \@names ] )

Register (or overwrite) a named extension.  C<$name> must be alphanumeric
plus underscore and must not collide with reserved bridge properties
(C<invoke>, C<call>, C<_resolve>, C<_event>, C<_eventData>, C<_callbacks>,
C<_id>).

=item B<register_file>( $name, $path [, depends => \@names ] )

Like C<register> but reads the JS source from a file.

=item B<unregister>( $name )

Remove a previously registered extension.  Returns true on success.

=item B<is_registered>( $name )

Returns true if an extension with that name exists.

=item B<source>( $name )

Returns the raw JS source for the named extension, or C<undef>.

=item B<list>()

Returns extension names in dependency-resolved order.

=item B<clear>()

Remove all registered extensions.

=item B<generate_js>()

Returns the combined JS string for all extensions (IIFEs in dependency
order).

=item B<generate_js_escaped>()

Like C<generate_js> but with backslash-escaping suitable for C<eval_js>
injection.

=back

=head1 SEE ALSO

L<Chandra::Bridge>, L<Chandra::App>

=cut
