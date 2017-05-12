# NAME

Acme::Taboo - Automated Cencoring Micro Engine

# SYNOPSIS

    use Acme::Taboo;
    my $taboo    = Acme::Taboo->new('bunny', 'coyote', 'roadrunner');
    my $str      = 'Do you love bugs bunny, or wily coyote?';
    my $censored = $taboo->censor($str);

# DESCRIPTION

Acme::Taboo detects taboos from string and replaces it.

# QUALITY GUARANTEE

This software is guaranteed quality by Acme corporation.

# LICENSE

Copyright (C) ytnobody, not Acme corporation.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself if you think good about Acme corporation.

# AUTHOR

ytnobody <ytnobody aaaaaaaaaaaaatttttttttttttt acme^D^D^D^Dgmail dddooottt com>
