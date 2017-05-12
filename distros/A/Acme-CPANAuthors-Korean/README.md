# NAME

Acme::CPANAuthors::Korean - We are Korean CPAN Authors! (우리는 CPAN Author 다!)

# SYNOPSIS

    use Acme::CPANAuthors;
    use Acme::CPANAuthors::Korean;
    $authors = Acme::CPANAuthors->new('Korean');

    $number   = $authors->count;
    @ids      = $authors->id;
    @distors  = $authors->distributions('JEEN');
    $url      = $authors->avatar_url('KEEDI');
    $kwalitee = $authors->kwalitee('AERO');

# DESCRIPTION

See documentation for [Acme::CPANAuthors](https://metacpan.org/pod/Acme::CPANAuthors) for more details.

# DEPENDENCIES

[Acme::CPANAuthors](https://metacpan.org/pod/Acme::CPANAuthors)

# DEVELOPMENT

Git repository: http://github.com/jeen/Acme-CPANAuthors-Korean/

# AUTHOR

Jeen Lee <jeen@perl.kr>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
