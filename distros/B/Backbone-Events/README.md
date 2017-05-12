# SYNOPSIS

    package MyProducer {
        use Moo;
        with 'Backbone::Events';
    };
    my $pub = MyProducer->new;

    package MySubscriber {
        use Moo;
        with 'Backbone::Events';
    };
    my $sub = MySubscriber->new;

    $sub->listen_to($pub, 'some-event', sub { ... })
    ...
    $pub->trigger('some-event', qw(args for callback));

# DESCRIPTION

Backbone::Events is a Moo::Role which provides a simple interface for binding
and triggering custom named events. Events do not have to be declared before
they are bound, and may take passed arguments.

Events can be optionally namespaced by prepending the event with the
namespace: '$namespace:$event'.

# METHODS

## on($event, $callback)

Bind a callback to an object.

Callbacks bound to the special 'all' event will be triggered when any event
occurs, and are passed the name of the event as the first argument.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'off'.

## off(\[$event\], \[$callback\])

Remove a previously-bound callback from an object.

## trigger($event, @args)

Trigger callbacks for the given event.

## once($event, $callback)

Just like 'on', but causes the bound callback to fire only once before being
removed.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'off'.

## listen\_to($other, $event, $callback)

Tell an object to listen to a particular event on an other object.
The other object must consume the Backbone::Events role.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'stop\_listening'.

## stop\_listening(\[$other\], \[$event\], \[$callback\])

Tell an object to stop listening to events.

## listen\_to\_once($other, $event, $callback)

Just like 'listen\_to', but causes the bound callback to fire only once before
being removed.

Returns the callback that was passed. This is mainly so anonymous functions
can be returned, and later passed back to 'stop\_listening'.

# SEE ALSO

[http://backbonejs.org/#Events](http://backbonejs.org/#Events)
