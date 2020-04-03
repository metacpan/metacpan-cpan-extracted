# NAME

Data::Object::Struct

# ABSTRACT

Struct Class for Perl 5

# SYNOPSIS

    package main;

    use Data::Object::Struct;

    my $person = Data::Object::Struct->new(
      fname => 'Aron',
      lname => 'Nienow',
      cname => 'Jacobs, Sawayn and Nienow'
    );

    # $person->fname # Aron
    # $person->lname # Nienow
    # $person->cname # Jacobs, Sawayn and Nienow

    # $person->mname
    # Error!

    # $person->mname = 'Clifton'
    # Error!

    # $person->{mname} = 'Clifton'
    # Error!

# DESCRIPTION

This package provides a class that creates struct-like objects which bundle
attributes together, is immutable, and provides accessors, without having to
write an explicit class.

# INTEGRATES

This package integrates behaviors from:

[Data::Object::Role::Buildable](https://metacpan.org/pod/Data::Object::Role::Buildable)

[Data::Object::Role::Immutable](https://metacpan.org/pod/Data::Object::Role::Immutable)

[Data::Object::Role::Proxyable](https://metacpan.org/pod/Data::Object::Role::Proxyable)

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/data-object-struct/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/iamalnewkirk/data-object-struct/wiki)

[Project](https://github.com/iamalnewkirk/data-object-struct)

[Initiatives](https://github.com/iamalnewkirk/data-object-struct/projects)

[Milestones](https://github.com/iamalnewkirk/data-object-struct/milestones)

[Contributing](https://github.com/iamalnewkirk/data-object-struct/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/data-object-struct/issues)
