# NAME

App::perl2js - A module that transpile Perl code to JavaScript as readable as possible.

# SYNOPSIS

    use App::perl2js::Converter;
    print App::perl2js::Converter->new->convert(q[
        package Hoge;
        sub hoge {
            my $self = $_[0];
            if ($_[1]) {
                $self->{hoge} = $_[1];
            } else {
                return $self->{hoge};
            }
        }
    ]);
    # ---- output ----
    # 'use strict';
    # function print() { console.log.apply(console.log, arguments) }
    # ... some runtime helplers
    #
    # var Hoge = (function() {
    #     var Hoge = {
    #         hoge() {
    #             if (this !== undefined) { Array.prototype.unshift.call(arguments, this) }
    #             var $self = arguments[0];
    #             if (arguments[1]) {
    #                 $self["hoge"] = arguments[1];
    #             } else {
    #                 return $self["hoge"]
    #             }
    #         },
    #     }
    #     return Hoge;
    # })();
    # export { Hoge }

# DESCRIPTION

App::perl2js is a transpiler from Perl to JavaScript. this module aim to help porting from Perl to JavaScript, not to output runnable code.

# LICENSE

Copyright (C) hatz48.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hatz48 &lt;hatz48@hatena.ne.jp>
