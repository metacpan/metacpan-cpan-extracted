# Class::Type::Enum

Class::Type::Enum is a class builder for type-like enumeration classes.

It's a bit of an experiment that grew from liking [Object::Enum][objenum] and
using it with [DBIC][dbic], but prefering something more akin to defining
types, with traditional numeric backing values and sortability.  Object::Enum
instances are all just instances of Object::Enum. I'd love to hear thoughts or
advice.

[Object::Enum][objenum] works nicely for varchars with enum-like sets of
values, but all enums you get out of it are instances of Object::Enum.
Instead, this is a class builder which lets you treat that class as an enum
type.

Thanks to the ordinal values behind these enums, they can be sorted either by
ordinal (`<=>`) or by symbol (`cmp`).  This also allows for checks like
`$thing->status > $approved` in addition to the usual `$thing->status->is_foo`
checks.  There is no check that you're comparing similar types, as comparison
is just happening through overload fallback after stringify and numify.

_Unlike_ Object::Enum, objects are not mutable.  I may add methods that return
new instances though, for example `next` and `prev`...

Also I liked `is_any` and `is_none` from [Enumeration][enumeration] and added
the same, as `any` and `none`.

## License

This software is licensed under the same terms as the Perl distribution itself.

[dbic]: https://metacpan.org/pod/DBIx::Class
[objenum]: https://metacpan.org/pod/Object::Enum
[enumeration]: https://metacpan.org/pod/Enumeration
