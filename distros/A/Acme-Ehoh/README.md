# NAME

Acme::Ehoh - Calclate ehoh

# SYNOPSIS

    use Acme::Ehoh;
    print Acme::Ehoh::direction(2014);

# DESCRIPTION

Acme::Ehoh caluclate ehoh (lucky direction on Onmyodo).

# FUNCTION

- direction($year)

    Return ehoh direction of specified year (value 0 means north, 90 means east,
    and so on).

    On error, return undef.

# LICENSE

Copyright (C) SHIRAKATA Kentaro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

SHIRAKATA Kentaro <argrath@ub32.org>
