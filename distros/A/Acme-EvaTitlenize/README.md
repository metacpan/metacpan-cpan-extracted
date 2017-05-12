# NAME

Acme::EvaTitlenize - Generate strings like title of Evangelion

# SYNOPSIS

    print Acme::EvaTitlenize::lower_left(qw/奇跡の 価値は/);
    # output:
    #   奇
    #   跡
    #   の価値は

    print Acme::EvaTitlenize::upper_right(qw/奇跡の 価値は/);
    # output:
    #   奇跡の価
    #         値
    #         は
    



# DESCRIPTION

Acme::EvaTitlenize generate strings like title of Evangelion.

# LICENSE

Copyright (C) Yuuki Tan-nai.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Tan-nai(@saisa6153) <yuki.tannai@gmail.com>
