# NAME

Baal::Parser - A Paser for Baal IDL.

# SYNOPSIS

    use Baal::Parser;
    my $parser = Baal::Parser->new;
    my $parsed_document = $parser->parse(<<END);
    namespace Data.Hoge += Hoge.Fuga.* {
        service HogeHoge {
            Hoge: <= !integer => !integer;
        }
    }
    END

# DESCRIPTION

Baal::Parser is A Paser for Baal IDL.
See [http://techblog.kayac.com/?page=1482198679](http://techblog.kayac.com/?page=1482198679) and [http://techblog.kayac.com/unity\_advent\_calendar\_2016\_20](http://techblog.kayac.com/unity_advent_calendar_2016_20)
about Baal(They are written in japanese).

# LICENSE

Copyright (C) ohta-nobuyuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ohta-nobuyuki <ohta-nobuyuki@kayac.com>
